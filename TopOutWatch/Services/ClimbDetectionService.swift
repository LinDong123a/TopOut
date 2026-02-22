import Foundation
import CoreMotion
import Combine

/// Multi-sensor fusion climb detection service.
/// At startup, detects available sensors via SensorCapability, then fuses only
/// available signals (motion, altitude, heart rate, pedometer) to determine climbing state.
///
/// Preserves the existing callback API: `onStateChanged`, `onClimbStarted`, `onClimbStopped`.
/// Adds new Published properties for richer data: `climbConfidence`, `currentMetrics`, `sensorCapability`.
final class ClimbDetectionService: ObservableObject {

    // MARK: - Published State (existing API preserved)

    @Published var isClimbing = false
    @Published var currentState: ClimbState = .idle

    // MARK: - New Published Properties

    /// Current algorithm confidence (0.0~1.0)
    @Published var climbConfidence: Double = 0
    /// Detected sensor capabilities
    @Published var sensorCapability: SensorCapability?
    /// Total altitude gain (meters) during current session
    @Published var totalAltitudeGain: Double = 0
    /// Current altitude rate (m/s)
    @Published var currentAltitudeRate: Double = 0
    /// Current heart rate zone
    @Published var currentHRZone: HRZone = .rest
    /// Current climb interval duration
    @Published var currentClimbDuration: TimeInterval? = nil
    /// Number of climb intervals
    @Published var climbIntervalCount: Int = 0

    // MARK: - Callbacks (existing API preserved)

    var onClimbStarted: (() -> Void)?
    var onClimbStopped: (() -> Void)?
    var onStateChanged: ((ClimbState) -> Void)?

    // MARK: - Components

    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()

    private var motionAnalyzer: MotionAnalyzer?
    private var altitudeAnalyzer: AltitudeAnalyzer?
    private var heartRateAnalyzer: HeartRateAnalyzer?
    private var pedometerAnalyzer: PedometerAnalyzer?
    private let fusionEngine = SignalFusionEngine()
    private let stateMachine = ClimbStateMachine()
    private let intervalTracker = IntervalTracker()

    /// Detected capability (set once on startMonitoring)
    private var capability: SensorCapability?

    init() {
        motionQueue.name = "com.topout.climbdetection"
        motionQueue.maxConcurrentOperationCount = 1

        // Wire state machine callbacks
        stateMachine.onStateChanged = { [weak self] newState in
            DispatchQueue.main.async {
                self?.handleStateTransition(newState)
            }
        }
    }

    // MARK: - Start / Stop

    func startMonitoring() {
        // 1. Detect available sensors
        let cap = SensorCapability.detect()
        self.capability = cap
        DispatchQueue.main.async { [weak self] in
            self?.sensorCapability = cap
        }

        // 2. Configure fusion weights based on available sensors
        fusionEngine.configure(capability: cap)

        // 3. Start motion (DeviceMotion preferred, fallback to accelerometer)
        if cap.canUseDeviceMotion {
            motionAnalyzer = MotionAnalyzer(useDeviceMotion: true)
            motionManager.deviceMotionUpdateInterval = 0.1 // 10Hz
            motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
                guard let self, let motion, error == nil else { return }
                self.processDeviceMotion(motion)
            }
        } else if cap.hasAccelerometer {
            motionAnalyzer = MotionAnalyzer(useDeviceMotion: false)
            motionManager.accelerometerUpdateInterval = 0.1 // 10Hz
            motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, error in
                guard let self, let data, error == nil else { return }
                self.processAccelerometer(data)
            }
        }

        // 4. Start altitude (if available)
        if cap.hasAltimeter {
            let alt = AltitudeAnalyzer()
            altitudeAnalyzer = alt
            alt.start()
        }

        // 5. Start heart rate analyzer
        if cap.hasHeartRate {
            heartRateAnalyzer = HeartRateAnalyzer()
        }

        // 6. Start pedometer (if available)
        if cap.hasPedometer {
            let ped = PedometerAnalyzer(hasFloorCounting: cap.hasFloorCounting)
            pedometerAnalyzer = ped
            ped.start()
        }

        // 7. Start interval tracker
        intervalTracker.startSession()

        print("[ClimbDetection] Started with sensors: \(cap.summary)")
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        altitudeAnalyzer?.stop()
        pedometerAnalyzer?.stop()
        intervalTracker.endSession()

        motionAnalyzer?.reset()
        heartRateAnalyzer?.reset()
        stateMachine.reset()

        DispatchQueue.main.async { [weak self] in
            self?.isClimbing = false
            self?.currentState = .idle
            self?.climbConfidence = 0
        }

        print("[ClimbDetection] Stopped monitoring")
    }

    // MARK: - External Heart Rate Feed

    /// Called by ClimbSessionManager when WorkoutService provides a new HR reading
    func updateHeartRate(_ bpm: Double) {
        heartRateAnalyzer?.update(bpm: bpm)

        // Also feed to interval tracker
        intervalTracker.updateHeartRate(bpm)
    }

    // MARK: - Session Data

    /// Get all climb intervals for the session (for ClimbRecord)
    func getSessionIntervals() -> [ClimbInterval] {
        intervalTracker.allClimbIntervals()
    }

    /// Get detailed interval metrics
    func getSessionIntervalMetrics() -> [ClimbIntervalMetrics] {
        intervalTracker.allIntervalMetrics()
    }

    /// Get session-level metrics
    func getSessionMetrics() -> SessionMetrics {
        let hrResult = heartRateAnalyzer?.currentResult()
        return intervalTracker.sessionMetrics(
            peakHR: hrResult?.currentBPM ?? 0,
            totalAltGain: altitudeAnalyzer?.totalGain ?? 0
        )
    }

    // MARK: - Motion Processing (10Hz)

    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        guard let analyzer = motionAnalyzer else { return }
        let motionResult = analyzer.process(deviceMotion: motion)
        runFusion(motionResult: motionResult)
    }

    private func processAccelerometer(_ data: CMAccelerometerData) {
        guard let analyzer = motionAnalyzer else { return }
        let motionResult = analyzer.process(accelerometer: data)
        runFusion(motionResult: motionResult)
    }

    // MARK: - Fusion (called at 10Hz from motion queue)

    private func runFusion(motionResult: MotionAnalyzer.Result) {
        // Gather current results from all analyzers
        let altResult = altitudeAnalyzer?.currentResult()
        let hrResult = heartRateAnalyzer?.currentResult()
        let pedResult = pedometerAnalyzer?.currentResult()

        // Fuse signals
        let fusion = fusionEngine.fuse(
            motionResult: motionResult,
            altitudeResult: altResult,
            hrResult: hrResult,
            pedometerResult: pedResult
        )

        // Feed confidence to state machine
        let now = Date()
        stateMachine.update(confidence: fusion.confidence, now: now)

        // Feed metrics to interval tracker
        intervalTracker.updateConfidence(fusion.confidence)
        if let alt = altResult {
            intervalTracker.updateAltitudeGain(alt.totalGain)
        }
        if let hr = hrResult {
            intervalTracker.updateHeartRateZone(hr.zone.rawValue)
        }

        // Update published properties on main queue
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.climbConfidence = fusion.confidence
            self.totalAltitudeGain = altResult?.totalGain ?? 0
            self.currentAltitudeRate = altResult?.currentRate ?? 0
            self.currentHRZone = hrResult?.zone ?? .rest
            self.currentClimbDuration = self.intervalTracker.currentClimbDuration
            self.climbIntervalCount = self.intervalTracker.climbIntervalCount
        }
    }

    // MARK: - State Transition Handling

    private func handleStateTransition(_ newState: ClimbState) {
        let previousState = currentState

        currentState = newState
        isClimbing = (newState == .climbing)

        // Notify interval tracker
        intervalTracker.onStateChanged(newState)

        // Fire callbacks
        onStateChanged?(newState)

        if newState == .climbing && previousState == .idle {
            onClimbStarted?()
        } else if newState == .idle && previousState != .idle {
            onClimbStopped?()
        }
    }
}

import Foundation
import CoreMotion
import Combine

/// P0: Automatic climb detection using CoreMotion accelerometer + gyroscope
final class ClimbDetectionService: ObservableObject {
    @Published var isClimbing = false
    @Published var currentState: ClimbState = .idle
    
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    // Detection parameters
    private var accelerationThreshold: Double = 1.3  // g-force threshold for climb detection
    private var stillnessThreshold: Double = 0.15     // g-force variance for stillness
    private var stopTimeout: TimeInterval = 30        // seconds of no motion to auto-stop
    
    private var lastMotionTime: Date?
    private var motionBuffer: [Double] = []
    private let bufferSize = 50  // ~5 seconds at 10Hz
    private var stopTimer: Timer?
    
    var onClimbStarted: (() -> Void)?
    var onClimbStopped: (() -> Void)?
    var onStateChanged: ((ClimbState) -> Void)?
    
    init() {
        queue.name = "com.topout.climbdetection"
        queue.maxConcurrentOperationCount = 1
    }
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1 // 10Hz
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self, let data else { return }
            self.processAccelerometerData(data)
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: queue, withHandler: { _, _ in })
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        stopTimer?.invalidate()
        stopTimer = nil
    }
    
    func updateSensitivity(_ sensitivity: Double) {
        // sensitivity 0.0 (low) to 1.0 (high)
        accelerationThreshold = 1.5 - (sensitivity * 0.4) // range 1.1 - 1.5
    }
    
    func updateStopTimeout(_ timeout: TimeInterval) {
        stopTimeout = timeout
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = data.acceleration
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        
        motionBuffer.append(magnitude)
        if motionBuffer.count > bufferSize {
            motionBuffer.removeFirst()
        }
        
        let isActiveMotion = detectClimbingPattern()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if isActiveMotion {
                self.lastMotionTime = Date()
                self.resetStopTimer()
                
                if self.currentState != .climbing {
                    if self.currentState == .idle {
                        self.onClimbStarted?()
                    }
                    self.currentState = .climbing
                    self.isClimbing = true
                    self.onStateChanged?(.climbing)
                }
            } else if self.currentState == .climbing {
                // Transition to resting
                self.currentState = .resting
                self.onStateChanged?(.resting)
                self.startStopTimer()
            }
        }
    }
    
    private func detectClimbingPattern() -> Bool {
        guard motionBuffer.count >= 10 else { return false }
        
        let recentSamples = Array(motionBuffer.suffix(10))
        let mean = recentSamples.reduce(0, +) / Double(recentSamples.count)
        let variance = recentSamples.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(recentSamples.count)
        
        // Climbing pattern: significant acceleration variance + peaks above threshold
        let hasHighVariance = variance > stillnessThreshold
        let hasPeaks = recentSamples.contains { $0 > accelerationThreshold }
        
        return hasHighVariance && hasPeaks
    }
    
    private func startStopTimer() {
        stopTimer?.invalidate()
        stopTimer = Timer.scheduledTimer(withTimeInterval: stopTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.currentState = .idle
            self.isClimbing = false
            self.onClimbStopped?()
            self.onStateChanged?(.idle)
        }
    }
    
    private func resetStopTimer() {
        stopTimer?.invalidate()
        stopTimer = nil
    }
}

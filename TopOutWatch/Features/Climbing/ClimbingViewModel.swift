import Foundation
import Combine

/// Coordinates climb detection, workout tracking, and phone communication
@MainActor
final class ClimbingViewModel: ObservableObject {
    @Published var climbState: ClimbState = .idle
    @Published var heartRate: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isSessionActive = false
    @Published var todayClimbCount: Int = 0
    @Published var todayTotalDuration: TimeInterval = 0
    
    private let climbDetection = ClimbDetectionService()
    private let workoutService = WorkoutService()
    private let connectivity = PhoneConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTimer: Timer?
    
    init() {
        setupBindings()
    }
    
    func setup() async {
        _ = await workoutService.requestAuthorization()
        climbDetection.startMonitoring()
    }
    
    private func setupBindings() {
        // Auto-detect climb start
        climbDetection.onClimbStarted = { [weak self] in
            Task { @MainActor in
                self?.startSession()
            }
        }
        
        // Auto-detect climb stop
        climbDetection.onClimbStopped = { [weak self] in
            Task { @MainActor in
                self?.stopSession()
            }
        }
        
        // State changes from detection
        climbDetection.onStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.climbState = state
            }
        }
        
        // Heart rate updates
        workoutService.onHeartRateUpdate = { [weak self] hr in
            Task { @MainActor in
                self?.heartRate = hr
            }
        }
        
        // Session ended
        workoutService.onSessionEnded = { [weak self] record in
            Task { @MainActor in
                self?.handleSessionEnded(record: record)
            }
        }
        
        // Bind elapsed time
        workoutService.$elapsedTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$elapsedTime)
        
        workoutService.$isSessionActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSessionActive)
    }
    
    // MARK: - Manual Controls
    
    func startSession() {
        guard !isSessionActive else { return }
        workoutService.startWorkout()
        climbState = .climbing
        connectivity.sendSessionStarted()
        startRealtimeUpdates()
    }
    
    func stopSession() {
        guard isSessionActive else { return }
        workoutService.endWorkout()
        stopRealtimeUpdates()
    }
    
    // MARK: - Realtime Updates to iPhone
    
    private func startRealtimeUpdates() {
        realtimeTimer?.invalidate()
        realtimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendRealtimeUpdate()
            }
        }
    }
    
    private func stopRealtimeUpdates() {
        realtimeTimer?.invalidate()
        realtimeTimer = nil
    }
    
    private func sendRealtimeUpdate() {
        let data = RealtimeData(
            heartRate: heartRate,
            climbState: climbState,
            duration: elapsedTime,
            timestamp: Date(),
            todayClimbCount: todayClimbCount,
            todayTotalDuration: todayTotalDuration
        )
        connectivity.sendRealtimeData(data)
    }
    
    private func handleSessionEnded(record: ClimbRecord) {
        climbState = .idle
        todayClimbCount += 1
        todayTotalDuration += record.duration
        connectivity.sendSessionEnded(record: record)
    }
}

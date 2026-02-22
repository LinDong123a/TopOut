import Foundation
import SwiftUI
import Combine
import WatchKit

/// Central state manager for the watchOS climbing session
@MainActor
final class ClimbSessionManager: ObservableObject {

    enum AppState: Equatable {
        case idle      // Not in a workout — shows IdleStartView
        case waiting   // Between climbs — shows WaitingView (start climb / end session)
        case climbing  // Actively climbing — shows ActiveSessionView
        case summary   // Session ended — shows SessionSummaryView
    }

    enum ClimbingScene: String, Codable {
        case indoor, outdoor

        var displayName: String {
            switch self {
            case .indoor: return "室内"
            case .outdoor: return "户外"
            }
        }

        var icon: String {
            switch self {
            case .indoor: return "building.2.fill"
            case .outdoor: return "mountain.2.fill"
            }
        }

        /// Available climb types for this scene
        var climbTypes: [ClimbType] {
            switch self {
            case .indoor: return [.boulder, .topRope, .lead]
            case .outdoor: return [.boulder, .lead]
            }
        }
    }

    enum ClimbType: String, CaseIterable, Codable {
        case boulder = "抱石"
        case lead = "先锋"
        case topRope = "顶绳"
    }

    enum CompletionStatus: String, CaseIterable {
        case completed = "completed"
        case failed = "failed"
        case flash = "flash"
        case onsight = "onsight"

        var label: String {
            switch self {
            case .completed: return "完攀"
            case .failed: return "未完"
            case .flash: return "Flash"
            case .onsight: return "Onsight"
            }
        }

        var emoji: String {
            switch self {
            case .completed: return "✅"
            case .failed: return "❌"
            case .flash: return "⚡"
            case .onsight: return "👁️"
            }
        }
    }

    struct RouteLog: Identifiable {
        let id = UUID()
        let type: ClimbType
        let difficulty: String
        let status: CompletionStatus
        let isStarred: Bool
        let timestamp: Date
    }

    // MARK: - Published State
    @Published var appState: AppState = .idle
    @Published var scene: ClimbingScene = .indoor
    @Published var selectedClimbType: ClimbType = .boulder

    // Climbing session
    @Published var climbState: ClimbState = .idle
    @Published var heartRate: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isSessionActive = false

    // Route logging
    @Published var routeLogs: [RouteLog] = []
    @Published var todayClimbCount: Int = 0
    @Published var todayTotalDuration: TimeInterval = 0

    // Summary data (populated when session ends)
    @Published var summaryDuration: TimeInterval = 0
    @Published var summaryRouteCount: Int = 0
    @Published var summaryAvgHR: Double = 0
    @Published var summaryMaxHR: Double = 0

    // Notification demo
    @Published var showNotification = false
    @Published var notificationText = ""

    // No heart rate prompt
    @Published var showNoHRPrompt = false

    // Services
    private let climbDetection = ClimbDetectionService()
    private let workoutService = WorkoutService()
    private let connectivity = PhoneConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTimer: Timer?
    private var notificationTimer: Timer?
    private var noHRTimer: Timer?
    private var lastValidHRTime: Date?
    /// Prevents echo loops: true when action was triggered by phone remote command
    private var isFromRemote = false

    // Difficulty scales
    static let boulderGrades = (0...16).map { "V\($0)" }
    static let routeGrades: [String] = {
        var grades: [String] = []
        for major in 5...15 {
            if major <= 9 {
                grades.append("5.\(major)")
            } else {
                for sub in ["a", "b", "c", "d"] {
                    grades.append("5.\(major)\(sub)")
                }
            }
        }
        return grades
    }()

    init() {
        loadSavedScene()
        setupBindings()
        listenForPhoneEndSession()
        listenForPhoneStartSession()
    }

    // MARK: - Scene & Type Selection

    func selectScene(_ s: ClimbingScene) {
        scene = s
        UserDefaults.standard.set(s.rawValue, forKey: "selectedScene")
        // Reset climb type to first available for this scene
        if !s.climbTypes.contains(selectedClimbType) {
            selectedClimbType = s.climbTypes.first ?? .boulder
        }
        WKInterfaceDevice.current().play(.click)
    }

    func selectClimbType(_ type: ClimbType) {
        selectedClimbType = type
        WKInterfaceDevice.current().play(.click)
    }

    private func loadSavedScene() {
        if let saved = UserDefaults.standard.string(forKey: "selectedScene"),
           let s = ClimbingScene(rawValue: saved) {
            scene = s
            if !s.climbTypes.contains(selectedClimbType) {
                selectedClimbType = s.climbTypes.first ?? .boulder
            }
        }
    }

    // MARK: - Session Control

    func setup() async {
        _ = await workoutService.requestAuthorization()
        climbDetection.startMonitoring()
    }

    /// Start climbing — from idle: starts full workout; from waiting: resumes detection only
    func startClimbing() {
        if appState == .idle && !isSessionActive {
            // First climb: start workout + everything
            workoutService.startWorkout()
            isSessionActive = true
            routeLogs = []
            // Only notify phone if this was initiated locally (not from phone command)
            if !isFromRemote {
                connectivity.sendSessionStarted()
            }
            startRealtimeUpdates()
            startNotificationDemo()
            startNoHRMonitoring()
            WKInterfaceDevice.current().play(.start)
        }
        // Resume climb detection (both from idle and from waiting)
        climbState = .climbing
        climbDetection.startMonitoring()
        appState = .climbing
    }

    /// Finish current climb — pause detection, go to waiting screen (workout keeps running)
    func finishCurrentClimb() {
        guard appState == .climbing else { return }
        climbState = .idle
        climbDetection.stopMonitoring()
        appState = .waiting
    }

    /// End the entire session — stop everything, show summary
    func endClimbing() {
        guard isSessionActive else { return }
        let now = Date()

        let samples = workoutService.heartRateSamples
        let avgHR = samples.isEmpty ? 0 : samples.map(\.bpm).reduce(0, +) / Double(samples.count)
        let maxHR = samples.map(\.bpm).max() ?? 0

        // Save summary data before resetting
        summaryDuration = elapsedTime
        summaryRouteCount = routeLogs.count
        summaryAvgHR = avgHR
        summaryMaxHR = maxHR

        workoutService.endWorkout()
        stopRealtimeUpdates()
        stopNotificationDemo()
        stopNoHRMonitoring()
        climbDetection.stopMonitoring()
        isSessionActive = false
        climbState = .idle

        todayClimbCount += routeLogs.count
        todayTotalDuration += elapsedTime

        // Build route log data for sync
        let routeLogData = routeLogs.map { log in
            RouteLogData(
                climbType: log.type.rawValue,
                difficulty: log.difficulty,
                completionStatus: log.status.rawValue,
                isStarred: log.isStarred,
                timestamp: log.timestamp
            )
        }

        // Gather multi-sensor session metrics
        let sessionMetrics = climbDetection.getSessionMetrics()
        let climbIntervals = climbDetection.getSessionIntervals()

        // Build and send record to iPhone
        let record = ClimbRecord(
            startTime: now.addingTimeInterval(-elapsedTime),
            endTime: now,
            duration: elapsedTime,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            calories: 0,
            heartRateSamples: samples,
            climbIntervals: climbIntervals,
            climbType: scene == .outdoor ? "outdoor" : "indoor",
            isOutdoor: scene == .outdoor,
            totalAltitudeGain: sessionMetrics.totalAltitudeGain,
            totalClimbingTime: sessionMetrics.totalClimbingTime,
            climbIntervalCount: sessionMetrics.climbIntervalCount
        )
        // Only send session data to phone if this was initiated locally (not from phone command)
        if !isFromRemote {
            connectivity.sendSessionEnded(record: record, routeLogs: routeLogData)
        }

        appState = .summary
        WKInterfaceDevice.current().play(.success)
    }

    /// Dismiss summary and return to idle
    func finishSummary() {
        routeLogs.removeAll()
        heartRate = 0
        elapsedTime = 0
        appState = .idle
    }

    // MARK: - Route Logging

    func logRoute(type: ClimbType, difficulty: String, status: CompletionStatus, starred: Bool) {
        let log = RouteLog(type: type, difficulty: difficulty, status: status, isStarred: starred, timestamp: Date())
        routeLogs.append(log)

        // Send route log to phone via dedicated message type
        connectivity.sendRouteLogged(
            climbType: type.rawValue,
            difficulty: difficulty,
            status: status.rawValue,
            starred: starred
        )

        WKInterfaceDevice.current().play(.success)
    }

    func gradesForType(_ type: ClimbType) -> [String] {
        type == .boulder ? Self.boulderGrades : Self.routeGrades
    }

    // MARK: - Private

    private func setupBindings() {
        climbDetection.onStateChanged = { [weak self] state in
            Task { @MainActor in
                guard let self, self.isSessionActive else { return }
                self.climbState = state
            }
        }

        workoutService.onHeartRateUpdate = { [weak self] hr in
            Task { @MainActor in
                guard let self else { return }
                self.heartRate = hr
                // Feed heart rate to climb detection algorithm
                self.climbDetection.updateHeartRate(hr)
                if hr > 0 {
                    self.lastValidHRTime = Date()
                    if self.showNoHRPrompt {
                        self.showNoHRPrompt = false
                    }
                }
            }
        }

        workoutService.$elapsedTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$elapsedTime)
    }

    private func startRealtimeUpdates() {
        realtimeTimer?.invalidate()
        realtimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let data = RealtimeData(
                    heartRate: self.heartRate,
                    climbState: self.climbState,
                    duration: self.elapsedTime,
                    timestamp: Date(),
                    todayClimbCount: self.todayClimbCount + self.routeLogs.count,
                    todayTotalDuration: self.todayTotalDuration + self.elapsedTime,
                    altitudeGain: self.climbDetection.totalAltitudeGain,
                    currentAltitudeRate: self.climbDetection.currentAltitudeRate,
                    climbConfidence: self.climbDetection.climbConfidence,
                    heartRateZone: self.climbDetection.currentHRZone.rawValue,
                    currentClimbDuration: self.climbDetection.currentClimbDuration,
                    climbIntervalCount: self.climbDetection.climbIntervalCount
                )
                self.connectivity.sendRealtimeData(data)
            }
        }
    }

    private func stopRealtimeUpdates() {
        realtimeTimer?.invalidate()
        realtimeTimer = nil
    }

    // MARK: - Notification Demo

    private let demoNames = ["小明", "Alice", "攀岩达人", "Boulder王", "岩友Leo"]

    private func startNotificationDemo() {
        notificationTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 15...40), repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isSessionActive else { return }
                let name = self.demoNames.randomElement() ?? "好友"
                self.notificationText = "\(name) 👍了你的攀爬记录"
                self.showNotification = true
                WKInterfaceDevice.current().play(.notification)

                // Auto dismiss after 3s
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showNotification = false
                }
            }
        }
    }

    private func stopNotificationDemo() {
        notificationTimer?.invalidate()
        notificationTimer = nil
        showNotification = false
    }

    // MARK: - No Heart Rate Monitoring

    func dismissNoHRPrompt() {
        showNoHRPrompt = false
        lastValidHRTime = Date()
    }

    private func startNoHRMonitoring() {
        lastValidHRTime = Date()
        showNoHRPrompt = false
        noHRTimer?.invalidate()
        noHRTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isSessionActive else { return }
                guard let lastTime = self.lastValidHRTime else { return }
                // If no valid heart rate for 30 seconds, prompt
                if self.heartRate == 0 && Date().timeIntervalSince(lastTime) > 30 {
                    if !self.showNoHRPrompt {
                        self.showNoHRPrompt = true
                        WKInterfaceDevice.current().play(.notification)
                    }
                }
            }
        }
    }

    private func stopNoHRMonitoring() {
        noHRTimer?.invalidate()
        noHRTimer = nil
        showNoHRPrompt = false
    }

    // MARK: - Phone Session Listeners

    private func listenForPhoneEndSession() {
        connectivity.$phoneEndedSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ended in
                guard let self, ended, self.isSessionActive else { return }
                self.isFromRemote = true
                self.endClimbing()
                self.isFromRemote = false
                // Reset the flag so it can be triggered again next time
                self.connectivity.phoneEndedSession = false
            }
            .store(in: &cancellables)
    }

    private func listenForPhoneStartSession() {
        connectivity.$phoneStartedSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] started in
                guard let self, started, !self.isSessionActive else { return }
                self.isFromRemote = true
                self.startClimbing()
                self.isFromRemote = false
                // Reset the flag so it can be triggered again next time
                self.connectivity.phoneStartedSession = false
            }
            .store(in: &cancellables)
    }
}

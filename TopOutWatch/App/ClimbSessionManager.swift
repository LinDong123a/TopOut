import Foundation
import SwiftUI
import Combine
import WatchKit

/// Central state manager for the watchOS climbing session
@MainActor
final class ClimbSessionManager: ObservableObject {
    
    enum AppState: Equatable {
        case sceneSelection
        case ready
        case climbing
        case summary
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
    @Published var appState: AppState = .sceneSelection
    @Published var scene: ClimbingScene = .indoor
    
    // Climbing session
    @Published var climbState: ClimbState = .idle
    @Published var heartRate: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isSessionActive = false
    @Published var isPaused = false
    
    // Route logging
    @Published var routeLogs: [RouteLog] = []
    @Published var todayClimbCount: Int = 0
    @Published var todayTotalDuration: TimeInterval = 0
    
    // Summary data
    @Published var summaryDuration: TimeInterval = 0
    @Published var summaryRouteCount: Int = 0
    @Published var summaryAvgHR: Double = 0
    @Published var summaryMaxHR: Double = 0
    @Published var syncedToPhone: Bool = false
    
    // Notification demo
    @Published var showNotification = false
    @Published var notificationText = ""
    
    // Services
    private let climbDetection = ClimbDetectionService()
    private let workoutService = WorkoutService()
    private let connectivity = PhoneConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTimer: Timer?
    private var notificationTimer: Timer?
    
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
    }
    
    // MARK: - Scene Selection
    
    func selectScene(_ s: ClimbingScene) {
        scene = s
        UserDefaults.standard.set(s.rawValue, forKey: "selectedScene")
        appState = .ready
        WKInterfaceDevice.current().play(.click)
    }
    
    private func loadSavedScene() {
        if let saved = UserDefaults.standard.string(forKey: "selectedScene"),
           let s = ClimbingScene(rawValue: saved) {
            scene = s
            appState = .ready
        }
    }
    
    // MARK: - Session Control
    
    func setup() async {
        _ = await workoutService.requestAuthorization()
        climbDetection.startMonitoring()
    }
    
    func startClimbing() {
        guard !isSessionActive else { return }
        workoutService.startWorkout()
        climbState = .climbing
        isSessionActive = true
        isPaused = false
        routeLogs = []
        connectivity.sendSessionStarted()
        startRealtimeUpdates()
        startNotificationDemo()
        appState = .climbing
        WKInterfaceDevice.current().play(.start)
    }
    
    func pauseResume() {
        isPaused.toggle()
        if isPaused {
            climbState = .resting
            WKInterfaceDevice.current().play(.stop)
        } else {
            climbState = .climbing
            WKInterfaceDevice.current().play(.start)
        }
    }
    
    func endClimbing() {
        guard isSessionActive else { return }
        
        // Build summary before stopping
        summaryDuration = elapsedTime
        summaryRouteCount = routeLogs.count
        let samples = workoutService.heartRateSamples
        summaryAvgHR = samples.isEmpty ? 0 : samples.map(\.bpm).reduce(0, +) / Double(samples.count)
        summaryMaxHR = samples.map(\.bpm).max() ?? 0
        
        workoutService.endWorkout()
        stopRealtimeUpdates()
        stopNotificationDemo()
        isSessionActive = false
        climbState = .idle
        
        todayClimbCount += routeLogs.count
        todayTotalDuration += elapsedTime
        
        // Simulate sync
        syncedToPhone = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.syncedToPhone = true
        }
        
        appState = .summary
        WKInterfaceDevice.current().play(.success)
    }
    
    func finishSummary() {
        appState = .ready
    }
    
    func goToSceneSelection() {
        appState = .sceneSelection
    }
    
    // MARK: - Route Logging
    
    func logRoute(type: ClimbType, difficulty: String, status: CompletionStatus, starred: Bool) {
        let log = RouteLog(type: type, difficulty: difficulty, status: status, isStarred: starred, timestamp: Date())
        routeLogs.append(log)
        
        // Send to phone
        let message: [String: Any] = [
            "type": "routeLogged",
            "climbType": type.rawValue,
            "difficulty": difficulty,
            "status": status.rawValue,
            "starred": starred,
            "timestamp": Date().timeIntervalSince1970
        ]
        connectivity.sendRealtimeData(RealtimeData(
            heartRate: heartRate,
            climbState: climbState,
            duration: elapsedTime,
            timestamp: Date(),
            todayClimbCount: todayClimbCount + routeLogs.count,
            todayTotalDuration: todayTotalDuration + elapsedTime
        ))
        
        WKInterfaceDevice.current().play(.success)
    }
    
    func gradesForType(_ type: ClimbType) -> [String] {
        type == .boulder ? Self.boulderGrades : Self.routeGrades
    }
    
    // MARK: - Private
    
    private func setupBindings() {
        climbDetection.onStateChanged = { [weak self] state in
            Task { @MainActor in
                guard let self, self.isSessionActive, !self.isPaused else { return }
                self.climbState = state
            }
        }
        
        workoutService.onHeartRateUpdate = { [weak self] hr in
            Task { @MainActor in
                self?.heartRate = hr
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
                    todayTotalDuration: self.todayTotalDuration + self.elapsedTime
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
}

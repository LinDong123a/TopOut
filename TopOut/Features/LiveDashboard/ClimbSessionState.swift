import Foundation
import SwiftUI
import Combine

/// Shared climb session state — injected as @EnvironmentObject at ContentView level
@MainActor
final class ClimbSessionState: ObservableObject {
    @Published var isClimbing = false
    @Published var isPaused = false
    @Published var sessionStartTime: Date?
    @Published var routeRecords: [RouteRecord] = []
    @Published var elapsedTime: TimeInterval = 0

    private var pausedAccumulated: TimeInterval = 0
    private var pauseStartTime: Date?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    /// Prevents infinite sync loops: true when action was triggered by remote (watch)
    private var isFromRemote = false
    /// Tracks how many watch route logs we've already converted to routeRecords
    private var lastWatchRouteCount = 0

    init() {
        // Sync with watch connectivity — when watch starts/ends, mirror locally
        WatchConnectivityService.shared.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in
                guard let self else { return }
                if active && !self.isClimbing {
                    self.isFromRemote = true
                    self.startSession()
                    self.isFromRemote = false
                } else if !active && self.isClimbing {
                    self.isFromRemote = true
                    self.endSession()
                    self.isFromRemote = false
                }
            }
            .store(in: &cancellables)

        // Sync route logs from watch → phone's routeRecords list
        WatchConnectivityService.shared.$latestRouteLogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                guard let self else { return }
                // Only add new entries (compare count to avoid duplicates on reset)
                let fromWatch = logs.count
                if fromWatch > self.lastWatchRouteCount {
                    for i in self.lastWatchRouteCount..<fromWatch {
                        let log = logs[i]
                        let status: RouteRecord.SendStatus = log.completionStatus == "failed" ? .fell : .sent
                        let record = RouteRecord(
                            difficulty: log.difficulty,
                            sendStatus: status,
                            isStarred: log.isStarred,
                            timestamp: log.timestamp
                        )
                        self.routeRecords.insert(record, at: 0)
                    }
                    self.lastWatchRouteCount = fromWatch
                    // Update Live Activity with new routes from watch
                    LiveActivityService.shared.updateLiveActivity(routeRecords: self.routeRecords)
                } else if fromWatch == 0 {
                    // Reset when watch starts new session
                    self.lastWatchRouteCount = 0
                }
            }
            .store(in: &cancellables)
    }

    func startSession() {
        guard !isClimbing else { return }
        isClimbing = true
        isPaused = false
        sessionStartTime = Date()
        elapsedTime = 0
        pausedAccumulated = 0
        pauseStartTime = nil
        routeRecords = []
        lastWatchRouteCount = 0
        startTimer()
        // Start lock screen Live Activity
        LiveActivityService.shared.startLiveActivity(startTime: sessionStartTime!)
        // Only tell watch to start if this was initiated locally (not from watch)
        if !isFromRemote {
            WatchConnectivityService.shared.sendStartSession()
        }
    }

    func endSession() {
        // End lock screen Live Activity before clearing state
        LiveActivityService.shared.endLiveActivity(routeRecords: routeRecords)
        isClimbing = false
        isPaused = false
        stopTimer()
        // Only tell watch to stop if this was initiated locally (not from watch)
        if !isFromRemote {
            WatchConnectivityService.shared.sendEndSession()
        }
    }

    func pauseSession() {
        guard isClimbing, !isPaused else { return }
        isPaused = true
        pauseStartTime = Date()
        stopTimer()
    }

    func resumeSession() {
        guard isClimbing, isPaused else { return }
        if let ps = pauseStartTime {
            pausedAccumulated += Date().timeIntervalSince(ps)
        }
        pauseStartTime = nil
        isPaused = false
        startTimer()
    }

    func addRecord(_ record: RouteRecord) {
        routeRecords.insert(record, at: 0)
        // Update Live Activity with new route
        LiveActivityService.shared.updateLiveActivity(routeRecords: routeRecords)
    }

    func deleteRecord(at offsets: IndexSet) {
        routeRecords.remove(atOffsets: offsets)
        // Update Live Activity after deletion
        LiveActivityService.shared.updateLiveActivity(routeRecords: routeRecords)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.sessionStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start) - self.pausedAccumulated
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

import Foundation
import SwiftUI
import Combine

/// Shared climb session state — injected as @EnvironmentObject at ContentView level
@MainActor
final class ClimbSessionState: ObservableObject {
    @Published var isClimbing = false
    @Published var sessionStartTime: Date?
    @Published var routeRecords: [RouteRecord] = []
    @Published var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Sync with watch connectivity
        WatchConnectivityService.shared.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in
                guard let self else { return }
                if active && !self.isClimbing {
                    self.startSession()
                } else if !active && self.isClimbing {
                    self.endSession()
                }
            }
            .store(in: &cancellables)
    }
    
    func startSession() {
        guard !isClimbing else { return }
        isClimbing = true
        sessionStartTime = Date()
        elapsedTime = 0
        routeRecords = []
        startTimer()
    }
    
    func endSession() {
        isClimbing = false
        stopTimer()
    }
    
    func addRecord(_ record: RouteRecord) {
        routeRecords.insert(record, at: 0)
    }
    
    func deleteRecord(at offsets: IndexSet) {
        routeRecords.remove(atOffsets: offsets)
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.sessionStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

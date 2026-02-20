import Foundation
import SwiftUI
import Combine

/// ViewModel for the live dashboard, fed by WatchConnectivityService
/// Phase 1.5: also pushes data via WebSocket to backend
@MainActor
final class LiveDashboardViewModel: ObservableObject {
    @Published var heartRate: Double = 0
    @Published var climbState: ClimbState = .idle
    @Published var duration: TimeInterval = 0
    @Published var todayClimbCount: Int = 0
    @Published var todayTotalDuration: TimeInterval = 0
    @Published var todayDifficultyBreakdown: [String: Int] = ["V2": 3, "V3": 2, "V4": 4, "V5": 1, "5.10a": 2]
    @Published var heartRateHistory: [HeartRateSample] = []
    @Published var isConnected = false
    @Published var streakDays: Int = 1
    
    private let connectivity = WatchConnectivityService.shared
    private let wsService = WebSocketService.shared
    private var cancellables = Set<AnyCancellable>()
    private var wasSessionActive = false
    
    var stateColor: Color {
        switch climbState {
        case .idle: return TopOutTheme.textTertiary
        case .climbing: return TopOutTheme.accentGreen
        case .resting: return TopOutTheme.warningAmber
        }
    }
    
    var chartMinHR: Double {
        let min = heartRateHistory.map(\.bpm).min() ?? 60
        return max(40, min - 10)
    }
    
    var chartMaxHR: Double {
        let max = heartRateHistory.map(\.bpm).max() ?? 120
        return min(220, max + 10)
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        connectivity.$realtimeData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.updateFromRealtimeData(data)
            }
            .store(in: &cancellables)
        
        connectivity.$isReachable
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        connectivity.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in
                guard let self else { return }
                if active && !self.wasSessionActive {
                    // Session just started - connect WebSocket
                    self.wsService.connectClimbSocket()
                    // Send climb start with privacy & gym
                    let privacy = PrivacySettings.load()
                    let gymId = LocationService.shared.nearbyGym?.id ?? "unknown"
                    self.wsService.sendClimbStart(gymId: gymId, privacy: privacy)
                } else if !active && self.wasSessionActive {
                    // Session ended
                    self.wsService.sendClimbEnd()
                    self.wsService.disconnectClimbSocket()
                    self.climbState = .idle
                }
                self.wasSessionActive = active
            }
            .store(in: &cancellables)
    }
    
    private func updateFromRealtimeData(_ data: RealtimeData) {
        heartRate = data.heartRate
        climbState = data.climbState
        duration = data.duration
        todayClimbCount = data.todayClimbCount
        todayTotalDuration = data.todayTotalDuration
        
        // Push heart rate to backend via WebSocket
        if data.heartRate > 0 {
            wsService.sendHeartRate(data.heartRate, state: data.climbState)
        }
        
        // Add to history
        if data.heartRate > 0 {
            let sample = HeartRateSample(timestamp: data.timestamp, bpm: data.heartRate)
            heartRateHistory.append(sample)
            
            // Keep last 5 minutes of data
            let cutoff = Date().addingTimeInterval(-300)
            heartRateHistory.removeAll { $0.timestamp < cutoff }
        }
    }
}

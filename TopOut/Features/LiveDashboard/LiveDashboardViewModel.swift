import Foundation
import SwiftUI
import Combine

/// ViewModel for the live dashboard, fed by WatchConnectivityService
@MainActor
final class LiveDashboardViewModel: ObservableObject {
    @Published var heartRate: Double = 0
    @Published var climbState: ClimbState = .idle
    @Published var duration: TimeInterval = 0
    @Published var todayClimbCount: Int = 0
    @Published var todayTotalDuration: TimeInterval = 0
    @Published var heartRateHistory: [HeartRateSample] = []
    @Published var isConnected = false
    @Published var streakDays: Int = 1
    
    private let connectivity = WatchConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var stateColor: Color {
        switch climbState {
        case .idle: return .gray
        case .climbing: return .green
        case .resting: return .yellow
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
                if !active {
                    self?.climbState = .idle
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateFromRealtimeData(_ data: RealtimeData) {
        heartRate = data.heartRate
        climbState = data.climbState
        duration = data.duration
        todayClimbCount = data.todayClimbCount
        todayTotalDuration = data.todayTotalDuration
        
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

import SwiftUI

/// P1: Watch climbing interface - heart rate, timer, status, manual controls
struct ClimbingView: View {
    @StateObject private var viewModel = ClimbingViewModel()
    
    var body: some View {
        VStack(spacing: 8) {
            if viewModel.isSessionActive {
                activeSessionView
            } else {
                idleView
            }
        }
        .task {
            await viewModel.setup()
        }
    }
    
    // MARK: - Active Session
    
    private var activeSessionView: some View {
        VStack(spacing: 6) {
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.climbState == .climbing ? .green : .yellow)
                    .frame(width: 8, height: 8)
                Text(viewModel.climbState.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Heart rate
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                Text("\(Int(viewModel.heartRate))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Timer
            Text(viewModel.elapsedTime.formattedDuration)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
            
            // Stop button
            Button(action: { viewModel.stopSession() }) {
                Image(systemName: "stop.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
    
    // MARK: - Idle View
    
    private var idleView: some View {
        VStack(spacing: 12) {
            // Today's stats
            VStack(spacing: 4) {
                Text("今日攀爬")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    VStack {
                        Text("\(viewModel.todayClimbCount)")
                            .font(.title2.bold())
                        Text("次")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text(viewModel.todayTotalDuration.formattedShortDuration)
                            .font(.title2.bold())
                        Text("总时长")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Manual start button
            Button(action: { viewModel.startSession() }) {
                Label("开始攀爬", systemImage: "figure.climbing")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Text("自动检测已开启")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ClimbingView()
}

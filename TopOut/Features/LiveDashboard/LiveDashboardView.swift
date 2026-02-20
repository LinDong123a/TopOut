import SwiftUI
import Charts

/// P0: Full-screen landscape live dashboard with privacy settings & gym live screen
struct LiveDashboardView: View {
    @StateObject private var viewModel = LiveDashboardViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var privacySettings = PrivacySettings.load()
    @State private var showGymLive = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                if geometry.size.width > geometry.size.height {
                    // Landscape layout
                    landscapeLayout(size: geometry.size)
                } else {
                    // Portrait layout
                    portraitLayout(size: geometry.size)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            locationService.requestPermission()
        }
        .sheet(isPresented: $showGymLive) {
            if let gym = locationService.nearbyGym {
                NavigationStack {
                    GymLiveScreenView(gym: gym)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("关闭") { showGymLive = false }
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Landscape Layout (Primary)
    
    private func landscapeLayout(size: CGSize) -> some View {
        HStack(spacing: 0) {
            // Left: Timer + Status + Privacy
            VStack(spacing: 16) {
                statusIndicator
                timerDisplay
                
                // Privacy settings (when idle)
                if viewModel.climbState == .idle {
                    PrivacySettingsView(settings: $privacySettings)
                        .padding(.horizontal, 8)
                }
                
                todayStats
                Spacer()
                bottomBar
            }
            .frame(width: size.width * 0.35)
            .padding()
            
            // Right: Heart rate + Chart
            VStack(spacing: 12) {
                heartRateDisplay
                heartRateChart
                    .frame(maxHeight: .infinity)
            }
            .frame(width: size.width * 0.65)
            .padding()
        }
    }
    
    // MARK: - Portrait Layout (Fallback)
    
    private func portraitLayout(size: CGSize) -> some View {
        VStack(spacing: 16) {
            statusIndicator
            
            // Privacy settings (when idle)
            if viewModel.climbState == .idle {
                PrivacySettingsView(settings: $privacySettings)
                    .padding(.horizontal)
            }
            
            timerDisplay
            heartRateDisplay
            heartRateChart
                .frame(height: size.height * 0.3)
            todayStats
            Spacer()
            bottomBar
        }
        .padding()
    }
    
    // MARK: - Components
    
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.stateColor)
                .frame(width: 16, height: 16)
                .shadow(color: viewModel.stateColor.opacity(0.8), radius: 8)
            
            Text(viewModel.climbState.displayName)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            // Gym indicator
            if let gym = locationService.nearbyGym {
                Button {
                    showGymLive = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.caption)
                        Text(gym.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.15), in: Capsule())
                }
            }
            
            // Connection status
            Image(systemName: viewModel.isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .foregroundStyle(viewModel.isConnected ? .green : .gray)
        }
    }
    
    private var timerDisplay: some View {
        Text(viewModel.duration.formattedDuration)
            .font(.system(size: 72, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
    }
    
    private var heartRateDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundStyle(.red)
                .symbolEffect(.pulse, options: .repeating, isActive: viewModel.heartRate > 0)
            
            Text("\(Int(viewModel.heartRate))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.red)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: Int(viewModel.heartRate))
            
            Text("BPM")
                .font(.title3)
                .foregroundStyle(.red.opacity(0.7))
        }
    }
    
    private var heartRateChart: some View {
        Chart {
            ForEach(Array(viewModel.heartRateHistory.enumerated()), id: \.offset) { index, sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.red.opacity(0.6), .red],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.red.opacity(0.0), .red.opacity(0.2)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .chartYScale(domain: (viewModel.chartMinHR)...(viewModel.chartMaxHR))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private var todayStats: some View {
        HStack(spacing: 24) {
            StatItem(value: "\(viewModel.todayClimbCount)", label: "今日攀爬", icon: "figure.climbing")
            StatItem(value: viewModel.todayTotalDuration.formattedShortDuration, label: "累计时长", icon: "clock")
        }
    }
    
    private var bottomBar: some View {
        HStack {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("连续 \(viewModel.streakDays) 天")
                    .foregroundStyle(.orange)
                    .font(.subheadline.weight(.medium))
            }
            
            Spacer()
            
            // Privacy status indicator
            HStack(spacing: 6) {
                Image(systemName: privacySettings.isVisible ? "eye" : "eye.slash")
                    .font(.caption)
                if privacySettings.isVisible && privacySettings.isAnonymous {
                    Text("匿名")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - StatItem

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    LiveDashboardView()
}

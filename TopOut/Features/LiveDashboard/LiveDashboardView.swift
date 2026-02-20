import SwiftUI
import Charts

/// P0: Full-screen live dashboard — portrait & landscape
struct LiveDashboardView: View {
    @StateObject private var viewModel = LiveDashboardViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var privacySettings = PrivacySettings.load()
    @State private var showGymLive = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TopOutTheme.backgroundPrimary.ignoresSafeArea()
                if geo.size.width > geo.size.height {
                    landscapeLayout(size: geo.size)
                } else {
                    portraitLayout(size: geo.size)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear { locationService.requestPermission() }
        .sheet(isPresented: $showGymLive) {
            if let gym = locationService.nearbyGym {
                NavigationStack {
                    GymLiveScreenView(gym: gym)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("关闭") { showGymLive = false }
                                    .foregroundStyle(TopOutTheme.textSecondary)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Landscape

    private func landscapeLayout(size: CGSize) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 14) {
                statusIndicator
                timerDisplay
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

            VStack(spacing: 12) {
                heartRateDisplay
                heartRateChartOrEmpty
                    .frame(maxHeight: .infinity)
            }
            .frame(width: size.width * 0.65)
            .padding()
        }
    }

    // MARK: - Portrait

    private func portraitLayout(size: CGSize) -> some View {
        VStack(spacing: 16) {
            statusIndicator
            if viewModel.climbState == .idle {
                PrivacySettingsView(settings: $privacySettings)
                    .padding(.horizontal)
            }
            timerDisplay
            heartRateDisplay
            heartRateChartOrEmpty
                .frame(height: size.height * 0.28)
                .padding(.horizontal, 4)
            todayStats
            Spacer()
            bottomBar
        }
        .padding()
    }

    // MARK: - Status

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.stateColor)
                .frame(width: 14, height: 14)
                .shadow(color: viewModel.stateColor.opacity(0.6), radius: 6)

            Text(viewModel.climbState.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)

            Spacer()

            if let gym = locationService.nearbyGym {
                Button { showGymLive = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill").font(.caption2)
                        Text(gym.name).font(.caption).lineLimit(1)
                    }
                    .foregroundStyle(TopOutTheme.sageGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        TopOutTheme.mossGreen.opacity(0.15),
                        in: Capsule()
                    )
                }
            }

            Image(systemName: viewModel.isConnected
                  ? "applewatch.radiowaves.left.and.right"
                  : "applewatch.slash")
                .foregroundStyle(viewModel.isConnected
                                 ? TopOutTheme.accentGreen
                                 : TopOutTheme.textTertiary)
                .font(.caption)
        }
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        Text(viewModel.duration.formattedDuration)
            .font(.system(size: 64, weight: .bold, design: .monospaced))
            .foregroundStyle(TopOutTheme.textPrimary)
            .minimumScaleFactor(0.5)
    }

    // MARK: - Heart rate

    private var heartRateDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(TopOutTheme.heartRed)
                .symbolEffect(.pulse, options: .repeating,
                              isActive: viewModel.heartRate > 0)

            if viewModel.heartRate > 0 {
                Text("\(Int(viewModel.heartRate))")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(TopOutTheme.heartRed)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3),
                               value: Int(viewModel.heartRate))
            } else {
                Text("--")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }

            Text("BPM")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.heartRed.opacity(0.6))
        }
    }

    // MARK: - Chart / Empty

    @ViewBuilder
    private var heartRateChartOrEmpty: some View {
        if viewModel.heartRateHistory.isEmpty {
            emptyChartPlaceholder
        } else {
            heartRateChart
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 36))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.5))
            Text("等待心率数据…")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
            Text("连接 Apple Watch 开始攀爬")
                .font(.caption)
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .topOutCard()
    }

    private var heartRateChart: some View {
        Chart {
            ForEach(Array(viewModel.heartRateHistory.enumerated()),
                    id: \.offset) { _, sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(TopOutTheme.heartRed)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            TopOutTheme.heartRed.opacity(0.25),
                            TopOutTheme.heartRed.opacity(0.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: viewModel.chartMinHR...viewModel.chartMaxHR)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [4]))
                    .foregroundStyle(TopOutTheme.textTertiary.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [4]))
                    .foregroundStyle(TopOutTheme.textTertiary.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .topOutCard()
    }

    // MARK: - Today Stats

    private var todayStats: some View {
        HStack(spacing: 20) {
            DashStatItem(value: "\(viewModel.todayClimbCount)",
                         label: "今日攀爬",
                         icon: "figure.climbing",
                         color: TopOutTheme.accentGreen)
            DashStatItem(value: viewModel.todayTotalDuration.formattedShortDuration,
                         label: "累计时长",
                         icon: "clock",
                         color: TopOutTheme.rockBrown)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(TopOutTheme.streakOrange)
                Text("连续 \(viewModel.streakDays) 天")
                    .foregroundStyle(TopOutTheme.streakOrange)
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: privacySettings.isVisible
                      ? "eye" : "eye.slash")
                    .font(.caption)
                if privacySettings.isVisible && privacySettings.isAnonymous {
                    Text("匿名").font(.caption)
                }
            }
            .foregroundStyle(TopOutTheme.textTertiary)
        }
    }
}

// MARK: - Stat Item

private struct DashStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(TopOutTheme.textPrimary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }
}

#Preview {
    LiveDashboardView()
}

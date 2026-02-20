import SwiftUI
import Charts

/// P0: Full-screen live dashboard — portrait & landscape
struct LiveDashboardView: View {
    @StateObject private var viewModel = LiveDashboardViewModel()
    @EnvironmentObject var climbSession: ClimbSessionState
    @ObservedObject private var locationService = LocationService.shared
    @State private var privacySettings = PrivacySettings.load()
    @State private var showGymLive = false
    @State private var showSpectate = false
    @State private var showGymSelector = false
    @State private var showNotifications = false
    @State private var showRouteRecorder = false
    @StateObject private var notificationStore = NotificationStore.shared
    @State private var selectedGymName = "岩时攀岩馆（望京店）"
    @State private var appeared = false
    @State private var elementsAppeared = [false, false, false, false, false]

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
        .onAppear {
            locationService.requestPermission()
            // Staggered entrance
            for i in elementsAppeared.indices {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.08)) {
                    elementsAppeared[i] = true
                }
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        // FloatingSpectateButton moved to HomeView
        .sheet(isPresented: $showNotifications) {
            NavigationStack {
                NotificationCenterView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("关闭") { showNotifications = false }
                                .foregroundStyle(TopOutTheme.textSecondary)
                        }
                    }
            }
        }
        .sheet(isPresented: $showSpectate) {
            SpectateView()
        }
        .sheet(isPresented: $showGymSelector) {
            GymSelectorView(selectedGymName: $selectedGymName)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showRouteRecorder) {
            RouteRecorderView()
                .environmentObject(climbSession)
        }
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
                if viewModel.climbState == .idle {
                    ClimbPrivacySettingsView(settings: $privacySettings)
                        .padding(.horizontal, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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

    private var isOutdoorLocation: Bool {
        selectedGymName.contains("岩场")
    }

    private var gymLocationBar: some View {
        Button {
            showGymSelector = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOutdoorLocation ? "mountain.2.fill" : "location.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(isOutdoorLocation ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                Text("我在")
                    .font(.system(size: 14))
                    .foregroundStyle(TopOutTheme.textSecondary)
                Text(selectedGymName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isOutdoorLocation ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                    .lineLimit(1)
                Text("攀岩")
                    .font(.system(size: 14))
                    .foregroundStyle(TopOutTheme.textSecondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05), in: Capsule())
            .overlay(Capsule().stroke(TopOutTheme.cardStroke, lineWidth: 1))
        }
    }

    private func portraitLayout(size: CGSize) -> some View {
        VStack(spacing: 16) {
            gymLocationBar
            
            statusIndicator
                .offset(y: elementsAppeared[0] ? 0 : -20)
                .opacity(elementsAppeared[0] ? 1 : 0)

            if viewModel.climbState == .idle {
                ClimbPrivacySettingsView(settings: $privacySettings)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if viewModel.isConnected {
                heartRateDisplay
                    .offset(y: elementsAppeared[1] ? 0 : 20)
                    .opacity(elementsAppeared[1] ? 1 : 0)

                heartRateChartOrEmpty
                    .frame(height: size.height * 0.20)
                    .padding(.horizontal, 4)
                    .offset(y: elementsAppeared[3] ? 0 : 20)
                    .opacity(elementsAppeared[3] ? 1 : 0)
            } else {
                // No watch — show route count prominently
                VStack(spacing: 4) {
                    Text("\(climbSession.routeRecords.count)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(TopOutTheme.accentGreen)
                    Text("已爬条数")
                        .font(.subheadline)
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
                .offset(y: elementsAppeared[1] ? 0 : 20)
                .opacity(elementsAppeared[1] ? 1 : 0)
            }

            todayStats
                .offset(y: elementsAppeared[4] ? 0 : 20)
                .opacity(elementsAppeared[4] ? 1 : 0)

            // Route recorder button
            routeRecorderButton
            
            // Recorded routes list
            if !climbSession.routeRecords.isEmpty {
                recordedRoutesList
            }

            Spacer()
            bottomBar
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Status

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.stateColor)
                .frame(width: 14, height: 14)
                .shadow(color: viewModel.stateColor.opacity(0.6), radius: 6)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.climbState)

            Text(viewModel.climbState.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)
                .contentTransition(.interpolate)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.climbState)

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
                .transition(.scale.combined(with: .opacity))
            }

            // Notification bell
            Button { showNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.subheadline)
                        .foregroundStyle(TopOutTheme.textSecondary)
                    if notificationStore.unreadCount > 0 {
                        Circle()
                            .fill(TopOutTheme.heartRed)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }

            Image(systemName: viewModel.isConnected
                  ? "applewatch.radiowaves.left.and.right"
                  : "applewatch.slash")
                .foregroundStyle(viewModel.isConnected
                                 ? TopOutTheme.accentGreen
                                 : TopOutTheme.textTertiary)
                .font(.caption)
                .contentTransition(.symbolEffect(.replace))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.climbState)
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        Text(viewModel.duration.formattedDuration)
            .font(.system(size: 64, weight: .bold, design: .monospaced))
            .foregroundStyle(TopOutTheme.textPrimary)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText(countsDown: false))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.duration)
    }

    // MARK: - Heart rate

    private var heartRateDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.body)
                .foregroundStyle(TopOutTheme.heartRed)
                .symbolEffect(.pulse, options: .repeating,
                              isActive: viewModel.heartRate > 0)

            if viewModel.heartRate > 0 {
                Text("\(Int(viewModel.heartRate))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(TopOutTheme.heartRed)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8),
                               value: Int(viewModel.heartRate))
            } else {
                Text("--")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }

            Text("BPM")
                .font(.caption)
                .foregroundStyle(TopOutTheme.heartRed.opacity(0.6))
        }
    }

    // MARK: - Chart / Empty

    @ViewBuilder
    private var heartRateChartOrEmpty: some View {
        if viewModel.heartRateHistory.isEmpty {
            emptyChartPlaceholder
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else {
            heartRateChart
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.heartRateHistory.count)
    }

    // MARK: - Today Stats

    private var todayStats: some View {
        VStack(spacing: 12) {
            // Primary stats row
            HStack(spacing: 16) {
                DashStatItem(value: "\(viewModel.todayClimbCount)",
                             label: "今日条数",
                             icon: "figure.climbing",
                             color: TopOutTheme.accentGreen)
                DashStatItem(value: viewModel.todayTotalDuration.formattedShortDuration,
                             label: "累计时长",
                             icon: "clock",
                             color: TopOutTheme.rockBrown)
            }
            
            // Difficulty breakdown
            if !viewModel.todayDifficultyBreakdown.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.todayDifficultyBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { difficulty, count in
                            HStack(spacing: 4) {
                                Text(difficulty)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(TopOutTheme.accentGreen)
                                Text("×\(count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(TopOutTheme.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(TopOutTheme.accentGreen.opacity(0.1), in: Capsule())
                            .overlay(Capsule().stroke(TopOutTheme.accentGreen.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Route Recorder

    private var routeRecorderButton: some View {
        Button { showRouteRecorder = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.title3)
                Text("📹 记录这条线")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(TopOutTheme.accentGreen, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var recordedRoutesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已爬 \(climbSession.routeRecords.count) 条")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)
            
            ForEach(climbSession.routeRecords) { record in
                HStack(spacing: 10) {
                    // Media thumbnail placeholder
                    if record.mediaType != nil {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(TopOutTheme.backgroundElevated)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: record.mediaType == .video ? "video.fill" : "photo.fill")
                                    .font(.caption)
                                    .foregroundStyle(TopOutTheme.textTertiary)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(record.difficulty)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(TopOutTheme.accentGreen)
                            Text(record.sendStatus.emoji + " " + record.sendStatus.rawValue)
                                .font(.caption)
                                .foregroundStyle(TopOutTheme.textSecondary)
                            if record.isStarred {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(TopOutTheme.warningAmber)
                            }
                        }
                        Text(record.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(TopOutTheme.textTertiary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .topOutCard()
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
                    .contentTransition(.numericText())
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: privacySettings.isVisible
                      ? "eye" : "eye.slash")
                    .font(.caption)
                    .contentTransition(.symbolEffect(.replace))
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
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(TopOutTheme.textPrimary)
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LiveDashboardView()
        .environmentObject(ClimbSessionState())
}

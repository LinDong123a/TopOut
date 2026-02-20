import SwiftUI

// MARK: - Model

struct FollowedClimber: Identifiable {
    let id = UUID()
    let nickname: String
    let avatarSymbol: String
    let boulderGrade: String
    let isLive: Bool
    let liveGymName: String?
    let lastActiveTime: Date?
    let heartRate: Int?
    let hasNewActivity: Bool
    var isFollowed: Bool = true
}

// MARK: - Mock Data

private func mockFollowedClimbers() -> [FollowedClimber] {
    let now = Date()
    return [
        FollowedClimber(nickname: "小岩", avatarSymbol: "figure.climbing",
                        boulderGrade: "V6", isLive: true, liveGymName: "岩时攀岩馆",
                        lastActiveTime: now, heartRate: 156, hasNewActivity: true),
        FollowedClimber(nickname: "Luna", avatarSymbol: "star.circle.fill",
                        boulderGrade: "V5", isLive: true, liveGymName: "奥岩攀岩馆（望京店）",
                        lastActiveTime: now, heartRate: 148, hasNewActivity: true),
        FollowedClimber(nickname: "阿飞", avatarSymbol: "flame.fill",
                        boulderGrade: "V8", isLive: true, liveGymName: "巅峰攀岩（三里屯）",
                        lastActiveTime: now, heartRate: 162, hasNewActivity: false),
        FollowedClimber(nickname: "石头", avatarSymbol: "mountain.2.fill",
                        boulderGrade: "V4", isLive: false, liveGymName: nil,
                        lastActiveTime: now.addingTimeInterval(-3 * 3600), heartRate: nil, hasNewActivity: false),
        FollowedClimber(nickname: "攀登者K", avatarSymbol: "bolt.circle.fill",
                        boulderGrade: "V3", isLive: false, liveGymName: nil,
                        lastActiveTime: now.addingTimeInterval(-8 * 3600), heartRate: nil, hasNewActivity: false),
        FollowedClimber(nickname: "猴子", avatarSymbol: "hare.fill",
                        boulderGrade: "V7", isLive: false, liveGymName: nil,
                        lastActiveTime: now.addingTimeInterval(-24 * 3600), heartRate: nil, hasNewActivity: false),
        FollowedClimber(nickname: "大壁", avatarSymbol: "person.circle.fill",
                        boulderGrade: "V2", isLive: false, liveGymName: nil,
                        lastActiveTime: now.addingTimeInterval(-2 * 24 * 3600), heartRate: nil, hasNewActivity: false),
        FollowedClimber(nickname: "岩壁精灵", avatarSymbol: "leaf.circle.fill",
                        boulderGrade: "V5", isLive: false, liveGymName: nil,
                        lastActiveTime: now.addingTimeInterval(-5 * 24 * 3600), heartRate: nil, hasNewActivity: false),
    ]
}

// MARK: - View

struct FollowingView: View {
    @State private var climbers = mockFollowedClimbers()
    @State private var searchText = ""
    @State private var appeared = false
    @State private var bannerText: String?

    private var filtered: [FollowedClimber] {
        let sorted = climbers.sorted { a, b in
            if a.isLive != b.isLive { return a.isLive }
            return (a.lastActiveTime ?? .distantPast) > (b.lastActiveTime ?? .distantPast)
        }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.nickname.localizedCaseInsensitiveContains(searchText) }
    }

    private var liveCount: Int { climbers.filter(\.isLive).count }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(TopOutTheme.textTertiary)
                        TextField("搜索岩友", text: $searchText)
                            .foregroundStyle(TopOutTheme.textPrimary)
                    }
                    .padding(12)
                    .background(TopOutTheme.backgroundCard, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Live summary
                    if liveCount > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .foregroundStyle(TopOutTheme.accentGreen)
                                .symbolEffect(.pulse)
                            Text("\(liveCount) 位岩友正在攀爬")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TopOutTheme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // List
                    LazyVStack(spacing: 10) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, climber in
                            ClimberCard(climber: climber, onToggleFollow: {
                                toggleFollow(climber)
                            })
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(min(index, 10)) * 0.05),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
            .topOutBackground()
            .navigationTitle("关注")
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
                // Simulate notification banner
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if let live = climbers.first(where: { $0.isLive && $0.hasNewActivity }) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            bannerText = "你关注的 \(live.nickname) 正在 \(live.liveGymName ?? "岩馆") 攀岩 🧗"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { bannerText = nil }
                        }
                    }
                }
            }

            // Notification banner
            if let text = bannerText {
                notificationBanner(text)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }

    private func toggleFollow(_ climber: FollowedClimber) {
        if let idx = climbers.firstIndex(where: { $0.id == climber.id }) {
            climbers[idx].isFollowed.toggle()
        }
    }

    private func notificationBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(TopOutTheme.streakOrange)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TopOutTheme.textPrimary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TopOutTheme.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(TopOutTheme.streakOrange.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Climber Card

private struct ClimberCard: View {
    let climber: FollowedClimber
    let onToggleFollow: () -> Void
    @State private var pressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with live indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(climber.isLive
                              ? TopOutTheme.accentGreen.opacity(0.15)
                              : TopOutTheme.textTertiary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: climber.avatarSymbol)
                        .font(.title3)
                        .foregroundStyle(climber.isLive ? TopOutTheme.accentGreen : TopOutTheme.textSecondary)
                }

                // New activity red dot
                if climber.hasNewActivity {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(TopOutTheme.backgroundCard, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(climber.nickname)
                        .font(.headline)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text(climber.boulderGrade)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TopOutTheme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
                }

                if climber.isLive, let gym = climber.liveGymName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(TopOutTheme.accentGreen)
                            .frame(width: 6, height: 6)
                        Text("实时攀爬中 · \(gym)")
                            .font(.caption)
                            .foregroundStyle(TopOutTheme.accentGreen)
                            .lineLimit(1)
                    }
                } else if let time = climber.lastActiveTime {
                    Text(time.followingRelativeString)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }

            Spacer()

            if climber.isLive, let hr = climber.heartRate {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(TopOutTheme.heartRed)
                    Text("\(hr)")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(TopOutTheme.heartRed)
                }
                .padding(.trailing, 4)
            }

            Button {
                onToggleFollow()
            } label: {
                Text(climber.isFollowed ? "已关注" : "关注")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(climber.isFollowed ? TopOutTheme.textTertiary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(climber.isFollowed
                                  ? TopOutTheme.textTertiary.opacity(0.15)
                                  : TopOutTheme.accentGreen)
                    )
            }
        }
        .topOutCard()
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

// MARK: - Date Helper

private extension Date {
    var followingRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        FollowingView()
    }
}

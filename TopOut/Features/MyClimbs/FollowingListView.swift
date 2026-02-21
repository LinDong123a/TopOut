import SwiftUI

/// List of people the user follows
struct FollowingListView: View {
    @State private var climbers = MockSocialData.followingList()
    @State private var appeared = false
    @State private var cheeredClimbers: Set<UUID> = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(climbers.enumerated()), id: \.element.id) { index, climber in
                    HStack {
                        NavigationLink(destination: MyClimbsView(userId: climber.id.uuidString)) {
                            SocialClimberRow(climber: climber) {
                                climbers[index].isFollowed.toggle()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if climber.isLive {
                            CheerButton(
                                isLiked: Binding(
                                    get: { cheeredClimbers.contains(climber.id) },
                                    set: { newVal in
                                        if newVal { cheeredClimbers.insert(climber.id) }
                                        else { cheeredClimbers.remove(climber.id) }
                                    }
                                )
                            )
                        }
                    }
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
            .padding(.top, 8)
        }
        .topOutBackground()
        .navigationTitle("关注")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

/// List of people following the user
struct FollowersListView: View {
    @State private var climbers = MockSocialData.followersList()
    @State private var appeared = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(climbers.enumerated()), id: \.element.id) { index, climber in
                    NavigationLink(destination: MyClimbsView(userId: climber.id.uuidString)) {
                        SocialClimberRow(climber: climber) {
                            climbers[index].isFollowed.toggle()
                        }
                    }
                    .buttonStyle(.plain)
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
            .padding(.top, 8)
        }
        .topOutBackground()
        .navigationTitle("粉丝")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Shared Row

struct SocialClimberRow: View {
    let climber: SocialClimber
    let onToggleFollow: () -> Void
    @State private var pressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with live dot
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
                if climber.isLive {
                    Circle()
                        .fill(TopOutTheme.accentGreen)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(TopOutTheme.backgroundCard, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(climber.nickname)
                        .font(.headline)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text(climber.grade)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TopOutTheme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
                }

                if climber.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(TopOutTheme.accentGreen).frame(width: 6, height: 6)
                        Text("正在攀爬")
                            .font(.caption)
                            .foregroundStyle(TopOutTheme.accentGreen)
                    }
                } else if let time = climber.lastActiveTime {
                    Text(time.socialRelativeString)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onToggleFollow()
                }
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

// MARK: - Model

struct SocialClimber: Identifiable {
    let id: UUID
    let nickname: String
    let avatarSymbol: String
    let grade: String
    let isLive: Bool
    let lastActiveTime: Date?
    var isFollowed: Bool

    init(id: UUID = UUID(), nickname: String, avatarSymbol: String, grade: String, isLive: Bool = false, lastActiveTime: Date? = nil, isFollowed: Bool = true) {
        self.id = id
        self.nickname = nickname
        self.avatarSymbol = avatarSymbol
        self.grade = grade
        self.isLive = isLive
        self.lastActiveTime = lastActiveTime
        self.isFollowed = isFollowed
    }
}

// MARK: - Mock Data

enum MockSocialData {
    private static let now = Date()

    static func followingList() -> [SocialClimber] {
        [
            SocialClimber(nickname: "小岩", avatarSymbol: "figure.climbing", grade: "V6", isLive: true, isFollowed: true),
            SocialClimber(nickname: "Luna", avatarSymbol: "star.circle.fill", grade: "V5", isLive: true, isFollowed: true),
            SocialClimber(nickname: "阿飞", avatarSymbol: "flame.fill", grade: "V8", isLive: true, isFollowed: true),
            SocialClimber(nickname: "石头", avatarSymbol: "mountain.2.fill", grade: "V4", lastActiveTime: now.addingTimeInterval(-3 * 3600), isFollowed: true),
            SocialClimber(nickname: "攀登者K", avatarSymbol: "bolt.circle.fill", grade: "V3", lastActiveTime: now.addingTimeInterval(-8 * 3600), isFollowed: true),
            SocialClimber(nickname: "猴子", avatarSymbol: "hare.fill", grade: "V7", lastActiveTime: now.addingTimeInterval(-24 * 3600), isFollowed: true),
            SocialClimber(nickname: "大壁", avatarSymbol: "person.circle.fill", grade: "V2", lastActiveTime: now.addingTimeInterval(-2 * 86400), isFollowed: true),
            SocialClimber(nickname: "岩壁精灵", avatarSymbol: "leaf.circle.fill", grade: "V5", lastActiveTime: now.addingTimeInterval(-5 * 86400), isFollowed: true),
            SocialClimber(nickname: "飞鱼", avatarSymbol: "fish.circle.fill", grade: "V4", lastActiveTime: now.addingTimeInterval(-7 * 86400), isFollowed: true),
            SocialClimber(nickname: "老岩", avatarSymbol: "shield.checkered", grade: "V9", lastActiveTime: now.addingTimeInterval(-3 * 86400), isFollowed: true),
            SocialClimber(nickname: "小蜜蜂", avatarSymbol: "ant.circle.fill", grade: "V3", lastActiveTime: now.addingTimeInterval(-10 * 86400), isFollowed: true),
            SocialClimber(nickname: "岩神", avatarSymbol: "crown.fill", grade: "V10", isLive: false, lastActiveTime: now.addingTimeInterval(-1 * 86400), isFollowed: true),
        ]
    }

    static func followersList() -> [SocialClimber] {
        [
            SocialClimber(nickname: "Luna", avatarSymbol: "star.circle.fill", grade: "V5", isLive: true, isFollowed: true),
            SocialClimber(nickname: "石头", avatarSymbol: "mountain.2.fill", grade: "V4", lastActiveTime: now.addingTimeInterval(-3 * 3600), isFollowed: true),
            SocialClimber(nickname: "攀登者K", avatarSymbol: "bolt.circle.fill", grade: "V3", lastActiveTime: now.addingTimeInterval(-8 * 3600), isFollowed: true),
            SocialClimber(nickname: "飞鱼", avatarSymbol: "fish.circle.fill", grade: "V4", lastActiveTime: now.addingTimeInterval(-7 * 86400), isFollowed: true),
            SocialClimber(nickname: "新手小白", avatarSymbol: "person.crop.circle", grade: "V1", lastActiveTime: now.addingTimeInterval(-2 * 86400), isFollowed: false),
            SocialClimber(nickname: "岩壁舞者", avatarSymbol: "figure.dance", grade: "V5", lastActiveTime: now.addingTimeInterval(-4 * 86400), isFollowed: false),
            SocialClimber(nickname: "峭壁行者", avatarSymbol: "figure.walk.circle.fill", grade: "V6", lastActiveTime: now.addingTimeInterval(-1 * 86400), isFollowed: false),
            SocialClimber(nickname: "岩缝猎人", avatarSymbol: "scope", grade: "V4", lastActiveTime: now.addingTimeInterval(-6 * 86400), isFollowed: false),
        ]
    }
}

// MARK: - Date Helper

extension Date {
    var socialRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

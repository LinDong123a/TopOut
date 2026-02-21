import SwiftUI

/// Controls what other users can see when they visit your profile
struct ProfilePrivacySettingsView: View {
    @AppStorage("privacy_climbHistory") private var climbHistory = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_statistics") private var statistics = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_badges") private var badges = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_stickers") private var stickers = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_followingList") private var followingList = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_followerList") private var followerList = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_activeStatus") private var activeStatus = VisibilityLevel.everyone.rawValue

    var body: some View {
        Form {
            Section {
                Text("控制其他用户查看你的主页时能看到的内容")
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textSecondary)
                    .listRowBackground(TopOutTheme.backgroundCard)
            }

            Section {
                privacyRow(
                    title: "攀爬记录",
                    subtitle: "历史攀爬记录与详情",
                    icon: "figure.climbing",
                    color: TopOutTheme.accentGreen,
                    binding: $climbHistory
                )
                privacyRow(
                    title: "统计数据",
                    subtitle: "总攀爬次数、时长、最高难度等",
                    icon: "chart.bar.fill",
                    color: TopOutTheme.rockBrown,
                    binding: $statistics
                )
            } header: {
                Text("攀爬数据")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            Section {
                privacyRow(
                    title: "徽章成就",
                    subtitle: "获得的攀爬徽章与里程碑",
                    icon: "medal.fill",
                    color: TopOutTheme.warningAmber,
                    binding: $badges
                )
                privacyRow(
                    title: "打卡贴纸",
                    subtitle: "岩馆打卡贴纸墙",
                    icon: "star.square.on.square.fill",
                    color: TopOutTheme.streakOrange,
                    binding: $stickers
                )
            } header: {
                Text("成就展示")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            Section {
                privacyRow(
                    title: "关注列表",
                    subtitle: "谁能看到你关注了谁",
                    icon: "person.badge.plus",
                    color: TopOutTheme.sageGreen,
                    binding: $followingList
                )
                privacyRow(
                    title: "粉丝列表",
                    subtitle: "谁能看到谁关注了你",
                    icon: "person.2.fill",
                    color: TopOutTheme.sageGreen,
                    binding: $followerList
                )
                privacyRow(
                    title: "在线状态",
                    subtitle: "正在攀爬时是否在岩馆实时页显示",
                    icon: "location.fill",
                    color: TopOutTheme.heartRed,
                    binding: $activeStatus
                )
            } header: {
                Text("社交")
                    .foregroundStyle(TopOutTheme.textSecondary)
            } footer: {
                Text("设为「仅自己可见」后，对应内容在他人访问你的主页时将被隐藏")
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .scrollContentBackground(.hidden)
        .topOutBackground()
        .navigationTitle("主页隐私")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func privacyRow(title: String, subtitle: String, icon: String, color: Color, binding: Binding<String>) -> some View {
        Picker(selection: binding) {
            ForEach(VisibilityLevel.allCases) { level in
                Label(level.label, systemImage: level.icon)
                    .tag(level.rawValue)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }
        }
        .tint(TopOutTheme.textSecondary)
        .listRowBackground(TopOutTheme.backgroundCard)
    }
}

#Preview {
    NavigationStack {
        ProfilePrivacySettingsView()
    }
}

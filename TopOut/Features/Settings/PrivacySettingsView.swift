import SwiftUI

// MARK: - Model

enum VisibilityLevel: String, CaseIterable, Identifiable {
    case everyone = "everyone"
    case followersOnly = "followersOnly"
    case onlyMe = "onlyMe"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .everyone: return "公开"
        case .followersOnly: return "仅关注者可见"
        case .onlyMe: return "仅自己可见"
        }
    }

    var icon: String {
        switch self {
        case .everyone: return "globe.asia.australia"
        case .followersOnly: return "person.2"
        case .onlyMe: return "lock"
        }
    }
}

// MARK: - View

struct PrivacySettingsView: View {
    @AppStorage("privacy_followingList") private var followingList = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_followerList") private var followerList = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_climbHistory") private var climbHistory = VisibilityLevel.everyone.rawValue
    @AppStorage("privacy_activeStatus") private var activeStatus = VisibilityLevel.everyone.rawValue

    var body: some View {
        Form {
            Section {
                Text("控制你的信息对他人的可见范围")
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textSecondary)
                    .listRowBackground(TopOutTheme.backgroundCard)
            }

            Section {
                privacyRow(title: "关注列表", subtitle: "谁能看到我关注了谁", icon: "person.badge.plus", color: TopOutTheme.accentGreen, binding: $followingList)
                privacyRow(title: "粉丝列表", subtitle: "谁能看到谁关注了我", icon: "person.2.fill", color: TopOutTheme.accentGreen, binding: $followerList)
            } header: {
                Text("社交关系")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            Section {
                privacyRow(title: "运动记录", subtitle: "攀爬历史对他人的可见性", icon: "figure.climbing", color: TopOutTheme.rockBrown, binding: $climbHistory)
                privacyRow(title: "运动状态", subtitle: "正在攀爬时是否在岩馆实时页显示", icon: "location.fill", color: TopOutTheme.streakOrange, binding: $activeStatus)
            } header: {
                Text("运动数据")
                    .foregroundStyle(TopOutTheme.textSecondary)
            } footer: {
                Text("统计数据与运动记录联动，不单独控制")
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .scrollContentBackground(.hidden)
        .topOutBackground()
        .navigationTitle("隐私设置")
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
        PrivacySettingsView()
    }
}

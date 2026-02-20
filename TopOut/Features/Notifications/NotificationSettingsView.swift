import SwiftUI

/// 通知设置 — 控制各类通知的开关
struct NotificationSettingsView: View {
    @StateObject private var settings = NotificationSettings.shared
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.cheerEnabled) {
                    Label("点赞提醒", systemImage: "hand.thumbsup.fill")
                }
                .tint(TopOutTheme.accentGreen)
                .listRowBackground(TopOutTheme.backgroundCard)
                
                Toggle(isOn: $settings.climbingEnabled) {
                    Label("关注的人攀爬提醒", systemImage: "figure.climbing")
                }
                .tint(TopOutTheme.accentGreen)
                .listRowBackground(TopOutTheme.backgroundCard)
                
                Toggle(isOn: $settings.followerEnabled) {
                    Label("新粉丝提醒", systemImage: "person.fill.badge.plus")
                }
                .tint(TopOutTheme.accentGreen)
                .listRowBackground(TopOutTheme.backgroundCard)
            } header: {
                Text("通知类型")
                    .foregroundStyle(TopOutTheme.textSecondary)
            } footer: {
                Text("系统通知始终开启")
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .scrollContentBackground(.hidden)
        .topOutBackground()
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}

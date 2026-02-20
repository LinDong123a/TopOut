import SwiftUI

/// 通知中心 — 显示所有通知，支持已读/未读
struct NotificationCenterView: View {
    @StateObject private var store = NotificationStore.shared
    
    var body: some View {
        Group {
            if store.notifications.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .topOutBackground()
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.unreadCount > 0 {
                    Button("全部已读") {
                        withAnimation { store.markAllAsRead() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.accentGreen)
                }
            }
        }
    }
    
    private var notificationList: some View {
        List {
            ForEach(store.notifications) { notif in
                notificationRow(notif)
                    .listRowBackground(TopOutTheme.backgroundCard)
                    .listRowSeparatorTint(TopOutTheme.cardStroke)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func notificationRow(_ notif: TopOutNotification) -> some View {
        Button {
            withAnimation { store.markAsRead(notif.id) }
        } label: {
            HStack(spacing: 12) {
                // Unread indicator
                Circle()
                    .fill(notif.isRead ? Color.clear : TopOutTheme.accentGreen)
                    .frame(width: 8, height: 8)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(notif.type.iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: notif.type.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(notif.type.iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notif.content)
                        .font(.subheadline)
                        .foregroundStyle(notif.isRead ? TopOutTheme.textSecondary : TopOutTheme.textPrimary)
                        .lineLimit(2)
                    Text(notif.relativeTime)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.5))
            Text("暂无通知")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textSecondary)
            Text("关注岩友、开始攀爬后就会收到通知")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationCenterView()
    }
}

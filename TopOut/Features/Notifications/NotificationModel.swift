import Foundation
import SwiftUI

// MARK: - Notification Model

enum TopOutNotificationType: String, Codable, CaseIterable {
    case cheer       // 👍 点赞加油
    case climbing    // 🧗 开始攀爬
    case newFollower // 👤 新粉丝
    case system      // 📢 系统通知
    
    var icon: String {
        switch self {
        case .cheer: return "hand.thumbsup.fill"
        case .climbing: return "figure.climbing"
        case .newFollower: return "person.fill.badge.plus"
        case .system: return "megaphone.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .cheer: return TopOutTheme.streakOrange
        case .climbing: return TopOutTheme.accentGreen
        case .newFollower: return TopOutTheme.sageGreen
        case .system: return TopOutTheme.rockBrown
        }
    }
}

struct TopOutNotification: Identifiable {
    let id: UUID
    let type: TopOutNotificationType
    let content: String
    let timestamp: Date
    var isRead: Bool
    
    var relativeTime: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        return "\(Int(interval / 86400))天前"
    }
}

// MARK: - Notification Store

@MainActor
final class NotificationStore: ObservableObject {
    static let shared = NotificationStore()
    
    @Published var notifications: [TopOutNotification] = []
    
    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    
    init() {
        loadMockData()
    }
    
    func markAsRead(_ id: UUID) {
        if let i = notifications.firstIndex(where: { $0.id == id }) {
            notifications[i].isRead = true
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }
    
    private func loadMockData() {
        let now = Date()
        notifications = [
            // 3 条点赞（1条未读）
            TopOutNotification(id: UUID(), type: .cheer, content: "攀岩达人 为你的攀爬记录点赞", timestamp: now.addingTimeInterval(-180), isRead: false),
            TopOutNotification(id: UUID(), type: .cheer, content: "Boulder王 为你的攀爬记录点赞", timestamp: now.addingTimeInterval(-7200), isRead: true),
            TopOutNotification(id: UUID(), type: .cheer, content: "Alice 为你的攀爬记录点赞", timestamp: now.addingTimeInterval(-86400), isRead: true),
            
            // 4 条开始攀爬（2条未读）
            TopOutNotification(id: UUID(), type: .climbing, content: "你关注的 小明 正在 岩时攀岩馆 攀岩", timestamp: now.addingTimeInterval(-300), isRead: false),
            TopOutNotification(id: UUID(), type: .climbing, content: "你关注的 岩友Leo 正在 首岩攀岩馆 攀岩", timestamp: now.addingTimeInterval(-1200), isRead: false),
            TopOutNotification(id: UUID(), type: .climbing, content: "你关注的 Alice 正在 奥森岩馆 攀岩", timestamp: now.addingTimeInterval(-14400), isRead: true),
            TopOutNotification(id: UUID(), type: .climbing, content: "你关注的 Boulder王 正在 岩舞空间 攀岩", timestamp: now.addingTimeInterval(-43200), isRead: true),
            
            // 3 条新粉丝（1条未读）
            TopOutNotification(id: UUID(), type: .newFollower, content: "攀岩小白 关注了你", timestamp: now.addingTimeInterval(-600), isRead: false),
            TopOutNotification(id: UUID(), type: .newFollower, content: "山野客 关注了你", timestamp: now.addingTimeInterval(-28800), isRead: true),
            TopOutNotification(id: UUID(), type: .newFollower, content: "ClimbFun 关注了你", timestamp: now.addingTimeInterval(-72000), isRead: true),
            
            // 2 条系统
            TopOutNotification(id: UUID(), type: .system, content: "欢迎使用 TopOut！开始记录你的攀爬之旅吧", timestamp: now.addingTimeInterval(-172800), isRead: true),
            TopOutNotification(id: UUID(), type: .system, content: "TopOut v1.5 更新：新增线路标记功能", timestamp: now.addingTimeInterval(-259200), isRead: true),
        ].sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Notification Settings

final class NotificationSettings: ObservableObject {
    static let shared = NotificationSettings()
    
    @AppStorage("notif_cheer") var cheerEnabled = true
    @AppStorage("notif_climbing") var climbingEnabled = true
    @AppStorage("notif_follower") var followerEnabled = true
}

import Foundation

struct RouteRecord: Identifiable {
    let id = UUID()
    var difficulty: String // "V3", "5.11a" etc
    var sendStatus: SendStatus
    var isStarred: Bool
    var note: String?
    var mediaPath: String? // local file path
    var mediaType: MediaType?
    var timestamp: Date
    
    enum SendStatus: String, CaseIterable {
        case sent = "完攀"
        case fell = "跌落"
        case attempting = "尝试中"
        
        var emoji: String {
            switch self {
            case .sent: return "✅"
            case .fell: return "❌"
            case .attempting: return "🔄"
            }
        }
    }
    
    enum MediaType {
        case photo, video
    }
}

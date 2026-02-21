import Foundation

enum ClimbState: String, Codable {
    case idle = "idle"
    case climbing = "climbing"
    case resting = "resting"
    
    var displayName: String {
        switch self {
        case .idle: return "开始攀爬"
        case .climbing: return "攀爬中"
        case .resting: return "休息中"
        }
    }
    
    var emoji: String {
        switch self {
        case .idle: return "⚪"
        case .climbing: return "🟢"
        case .resting: return "🟡"
        }
    }
}

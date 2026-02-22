import Foundation

/// Detailed metrics for a single climbing or resting interval
struct ClimbIntervalMetrics: Codable, Hashable {
    var startTime: Date
    var endTime: Date
    var isClimbing: Bool
    var altitudeGain: Double
    var averageHeartRate: Double
    var maxHeartRate: Double
    var heartRateZone: Int
    var averageConfidence: Double
}

/// Aggregated session-level metrics computed from all intervals
struct SessionMetrics: Codable {
    var totalAltitudeGain: Double
    var totalClimbingTime: TimeInterval
    var totalRestingTime: TimeInterval
    var climbIntervalCount: Int
    var averageClimbDuration: TimeInterval
    var averageRestDuration: TimeInterval
    var peakHeartRate: Double
    var averageClimbingHR: Double
    var averageRestingHR: Double
}

/// Heart rate training zone
enum HRZone: Int, Codable, Comparable, CaseIterable {
    case rest = 0
    case light = 1
    case moderate = 2
    case vigorous = 3
    case peak = 4

    static func < (lhs: HRZone, rhs: HRZone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .rest:     return "休息"
        case .light:    return "轻度"
        case .moderate: return "中度"
        case .vigorous: return "高强度"
        case .peak:     return "峰值"
        }
    }

    var emoji: String {
        switch self {
        case .rest:     return "💤"
        case .light:    return "🟢"
        case .moderate: return "🟡"
        case .vigorous: return "🟠"
        case .peak:     return "🔴"
        }
    }
}

import Foundation

/// Message types exchanged between Watch and iPhone via WatchConnectivity
enum WatchMessageKey: String {
    case messageType = "type"
    case heartRate = "heartRate"
    case climbState = "climbState"
    case timestamp = "timestamp"
    case duration = "duration"
    case sessionActive = "sessionActive"
    case climbRecord = "climbRecord"
    case todayClimbCount = "todayClimbCount"
    case todayTotalDuration = "todayTotalDuration"
}

enum WatchMessageType: String, Codable {
    case realtimeUpdate = "realtimeUpdate"
    case sessionStarted = "sessionStarted"
    case sessionEnded = "sessionEnded"
    case recordSync = "recordSync"
}

struct RealtimeData: Codable {
    var heartRate: Double
    var climbState: ClimbState
    var duration: TimeInterval
    var timestamp: Date
    var todayClimbCount: Int
    var todayTotalDuration: TimeInterval
    
    var dictionary: [String: Any] {
        [
            WatchMessageKey.messageType.rawValue: WatchMessageType.realtimeUpdate.rawValue,
            WatchMessageKey.heartRate.rawValue: heartRate,
            WatchMessageKey.climbState.rawValue: climbState.rawValue,
            WatchMessageKey.duration.rawValue: duration,
            WatchMessageKey.timestamp.rawValue: timestamp.timeIntervalSince1970,
            WatchMessageKey.todayClimbCount.rawValue: todayClimbCount,
            WatchMessageKey.todayTotalDuration.rawValue: todayTotalDuration
        ]
    }
    
    static func from(dictionary: [String: Any]) -> RealtimeData? {
        guard let heartRate = dictionary[WatchMessageKey.heartRate.rawValue] as? Double,
              let stateRaw = dictionary[WatchMessageKey.climbState.rawValue] as? String,
              let state = ClimbState(rawValue: stateRaw),
              let duration = dictionary[WatchMessageKey.duration.rawValue] as? TimeInterval,
              let ts = dictionary[WatchMessageKey.timestamp.rawValue] as? TimeInterval
        else { return nil }
        
        return RealtimeData(
            heartRate: heartRate,
            climbState: state,
            duration: duration,
            timestamp: Date(timeIntervalSince1970: ts),
            todayClimbCount: dictionary[WatchMessageKey.todayClimbCount.rawValue] as? Int ?? 0,
            todayTotalDuration: dictionary[WatchMessageKey.todayTotalDuration.rawValue] as? TimeInterval ?? 0
        )
    }
}

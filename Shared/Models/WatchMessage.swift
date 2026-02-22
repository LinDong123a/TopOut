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
    
    // Route fields
    case climbType = "climbType"
    case difficulty = "difficulty"
    case completionStatus = "completionStatus"
    case isStarred = "isStarred"
    case locationName = "locationName"
    case isOutdoor = "isOutdoor"
    case routeLogs = "routeLogs"
    
    // Cheer
    case cheerFromUser = "cheerFromUser"
}

enum WatchMessageType: String, Codable {
    case realtimeUpdate = "realtimeUpdate"
    case sessionStarted = "sessionStarted"
    case sessionEnded = "sessionEnded"
    case recordSync = "recordSync"
    case routeLogged = "routeLogged"          // Watch → iPhone: single route marked
    case cheerNotification = "cheerNotification" // iPhone → Watch: someone cheered
    case phoneEndSession = "phoneEndSession"   // iPhone → Watch: end session command
    case phoneStartSession = "phoneStartSession" // iPhone → Watch: start session command
}

struct RealtimeData: Codable {
    var heartRate: Double
    var climbState: ClimbState
    var duration: TimeInterval
    var timestamp: Date
    var todayClimbCount: Int
    var todayTotalDuration: TimeInterval

    // New optional fields from multi-sensor algorithm (backward compatible)
    var altitudeGain: Double?
    var currentAltitudeRate: Double?
    var climbConfidence: Double?
    var heartRateZone: Int?
    var currentClimbDuration: TimeInterval?
    var climbIntervalCount: Int?

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.realtimeUpdate.rawValue,
            WatchMessageKey.heartRate.rawValue: heartRate,
            WatchMessageKey.climbState.rawValue: climbState.rawValue,
            WatchMessageKey.duration.rawValue: duration,
            WatchMessageKey.timestamp.rawValue: timestamp.timeIntervalSince1970,
            WatchMessageKey.todayClimbCount.rawValue: todayClimbCount,
            WatchMessageKey.todayTotalDuration.rawValue: todayTotalDuration
        ]
        // Optional fields — only include if present
        if let v = altitudeGain { dict["altitudeGain"] = v }
        if let v = currentAltitudeRate { dict["currentAltitudeRate"] = v }
        if let v = climbConfidence { dict["climbConfidence"] = v }
        if let v = heartRateZone { dict["heartRateZone"] = v }
        if let v = currentClimbDuration { dict["currentClimbDuration"] = v }
        if let v = climbIntervalCount { dict["climbIntervalCount"] = v }
        return dict
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
            todayTotalDuration: dictionary[WatchMessageKey.todayTotalDuration.rawValue] as? TimeInterval ?? 0,
            altitudeGain: dictionary["altitudeGain"] as? Double,
            currentAltitudeRate: dictionary["currentAltitudeRate"] as? Double,
            climbConfidence: dictionary["climbConfidence"] as? Double,
            heartRateZone: dictionary["heartRateZone"] as? Int,
            currentClimbDuration: dictionary["currentClimbDuration"] as? TimeInterval,
            climbIntervalCount: dictionary["climbIntervalCount"] as? Int
        )
    }
}

/// Structured route log data for Watch ↔ iPhone sync
struct RouteLogData: Codable {
    var climbType: String
    var difficulty: String
    var completionStatus: String
    var isStarred: Bool
    var timestamp: Date
}

/// Session end payload helper
struct ClimbSessionData {
    var recordId: UUID
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var averageHeartRate: Double
    var maxHeartRate: Double
    var minHeartRate: Double
    var calories: Double
    var heartRateSamples: [HeartRateSample]
    var climbType: String
    var difficulty: String?
    var completionStatus: String
    var isStarred: Bool
    var locationName: String?
    var isOutdoor: Bool
    var routeLogs: [RouteLogData]
    
    static func from(message: [String: Any]) -> ClimbSessionData? {
        let recordId = (message["recordId"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
        let startTime = (message["startTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let endTime = (message["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let duration = message["duration"] as? TimeInterval ?? 0
        let avgHR = message["averageHeartRate"] as? Double ?? 0
        let maxHR = message["maxHeartRate"] as? Double ?? 0
        let minHR = message["minHeartRate"] as? Double ?? 0
        let calories = message["calories"] as? Double ?? 0
        
        var samples: [HeartRateSample] = []
        if let samplesString = message["heartRateSamples"] as? String,
           let data = samplesString.data(using: .utf8) {
            samples = (try? JSONDecoder().decode([HeartRateSample].self, from: data)) ?? []
        }
        
        var routes: [RouteLogData] = []
        if let routesString = message[WatchMessageKey.routeLogs.rawValue] as? String,
           let data = routesString.data(using: .utf8) {
            routes = (try? JSONDecoder().decode([RouteLogData].self, from: data)) ?? []
        }
        
        return ClimbSessionData(
            recordId: recordId,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            minHeartRate: minHR,
            calories: calories,
            heartRateSamples: samples,
            climbType: message[WatchMessageKey.climbType.rawValue] as? String ?? "indoorBoulder",
            difficulty: message[WatchMessageKey.difficulty.rawValue] as? String,
            completionStatus: message[WatchMessageKey.completionStatus.rawValue] as? String ?? "completed",
            isStarred: message[WatchMessageKey.isStarred.rawValue] as? Bool ?? false,
            locationName: message[WatchMessageKey.locationName.rawValue] as? String,
            isOutdoor: message[WatchMessageKey.isOutdoor.rawValue] as? Bool ?? false,
            routeLogs: routes
        )
    }
}

import Foundation
import SwiftData

@Model
final class ClimbRecord {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var averageHeartRate: Double
    var maxHeartRate: Double
    var minHeartRate: Double
    var calories: Double
    var heartRateSamples: [HeartRateSample]
    var climbIntervals: [ClimbInterval]
    
    // New fields
    var climbType: String
    var difficulty: String?
    var completionStatus: String
    var isStarred: Bool
    var feeling: Int
    var notes: String?
    var locationName: String?
    var isOutdoor: Bool
    
    // Multi-sensor algorithm metrics
    var totalAltitudeGain: Double
    var totalClimbingTime: TimeInterval
    var climbIntervalCount: Int

    // Public / Video fields
    var isPublic: Bool
    var videoURLs: [String]
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        averageHeartRate: Double = 0,
        maxHeartRate: Double = 0,
        minHeartRate: Double = 0,
        calories: Double = 0,
        heartRateSamples: [HeartRateSample] = [],
        climbIntervals: [ClimbInterval] = [],
        climbType: String = "indoorBoulder",
        difficulty: String? = nil,
        completionStatus: String = "completed",
        isStarred: Bool = false,
        feeling: Int = 3,
        notes: String? = nil,
        locationName: String? = nil,
        isOutdoor: Bool = false,
        totalAltitudeGain: Double = 0,
        totalClimbingTime: TimeInterval = 0,
        climbIntervalCount: Int = 0,
        isPublic: Bool = false,
        videoURLs: [String] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.minHeartRate = minHeartRate
        self.calories = calories
        self.heartRateSamples = heartRateSamples
        self.climbIntervals = climbIntervals
        self.climbType = climbType
        self.difficulty = difficulty
        self.completionStatus = completionStatus
        self.isStarred = isStarred
        self.feeling = feeling
        self.notes = notes
        self.locationName = locationName
        self.isOutdoor = isOutdoor
        self.totalAltitudeGain = totalAltitudeGain
        self.totalClimbingTime = totalClimbingTime
        self.climbIntervalCount = climbIntervalCount
        self.isPublic = isPublic
        self.videoURLs = videoURLs
    }
}

struct HeartRateSample: Codable, Hashable {
    var timestamp: Date
    var bpm: Double
}

struct ClimbInterval: Codable, Hashable {
    var startTime: Date
    var endTime: Date
    var isClimbing: Bool
}

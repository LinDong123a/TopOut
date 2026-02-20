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
        climbIntervals: [ClimbInterval] = []
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

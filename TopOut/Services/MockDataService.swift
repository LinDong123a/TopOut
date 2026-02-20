import Foundation
import SwiftData

/// Inserts mock ClimbRecords into SwiftData if the store is empty
enum MockDataService {
    @MainActor
    static func insertIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<ClimbRecord>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let now = Date()
        let records = generateRecords(around: now)
        for r in records { context.insert(r) }
        try? context.save()
        print("[MockData] Inserted \(records.count) climb records")
    }

    private static func generateRecords(around now: Date) -> [ClimbRecord] {
        // 18 records spread over the last 30 days
        let calendar = Calendar.current
        var results: [ClimbRecord] = []

        let entries: [(daysAgo: Int, hour: Int)] = [
            (0, 19), (1, 10), (1, 15),
            (3, 18), (4, 9), (5, 20),
            (7, 14), (8, 17), (10, 11),
            (12, 19), (14, 10), (15, 16),
            (18, 13), (20, 18), (22, 9),
            (25, 15), (27, 20), (29, 11),
        ]

        for (i, e) in entries.enumerated() {
            let start = calendar.date(byAdding: .day, value: -e.daysAgo,
                                      to: calendar.date(bySettingHour: e.hour, minute: Int.random(in: 0...59), second: 0, of: now)!)!
            let durationMin = Double(Int.random(in: 15...90))
            let duration = durationMin * 60
            let avgHR = Double(Int.random(in: 120...155))
            let maxHR = Double(Int.random(in: max(Int(avgHR) + 5, 155)...185))
            let minHR = Double(Int.random(in: 85...Int(avgHR) - 10))
            let calories = Double(Int.random(in: 100...500))

            // Generate some heart rate samples
            let sampleCount = Int(durationMin / 2)
            var samples: [HeartRateSample] = []
            for s in 0..<sampleCount {
                let t = start.addingTimeInterval(Double(s) * 120)
                let bpm = Double(Int.random(in: Int(minHR)...Int(maxHR)))
                samples.append(HeartRateSample(timestamp: t, bpm: bpm))
            }

            // Generate climb intervals
            var intervals: [ClimbInterval] = []
            var offset: TimeInterval = 0
            while offset < duration {
                let climbDur = Double(Int.random(in: 120...360))
                let restDur = Double(Int.random(in: 60...240))
                let climbStart = start.addingTimeInterval(offset)
                let climbEnd = start.addingTimeInterval(min(offset + climbDur, duration))
                intervals.append(ClimbInterval(startTime: climbStart, endTime: climbEnd, isClimbing: true))
                offset += climbDur
                if offset < duration {
                    let restStart = start.addingTimeInterval(offset)
                    let restEnd = start.addingTimeInterval(min(offset + restDur, duration))
                    intervals.append(ClimbInterval(startTime: restStart, endTime: restEnd, isClimbing: false))
                    offset += restDur
                }
            }

            let record = ClimbRecord(
                startTime: start,
                endTime: start.addingTimeInterval(duration),
                duration: duration,
                averageHeartRate: avgHR,
                maxHeartRate: maxHR,
                minHeartRate: minHR,
                calories: calories,
                heartRateSamples: samples,
                climbIntervals: intervals
            )
            results.append(record)
        }
        return results
    }
}

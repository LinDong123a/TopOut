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

    // Per-record metadata
    private struct RecordMeta {
        let daysAgo: Int
        let hour: Int
        let climbType: String
        let difficulty: String?
        let completionStatus: String
        let isStarred: Bool
        let feeling: Int
        let notes: String?
        let locationName: String?
        let isOutdoor: Bool
    }

    private static func generateRecords(around now: Date) -> [ClimbRecord] {
        let calendar = Calendar.current
        var results: [ClimbRecord] = []

        let entries: [RecordMeta] = [
            // 14 indoor
            RecordMeta(daysAgo: 0, hour: 19, climbType: "indoorBoulder", difficulty: "V4", completionStatus: "completed", isStarred: true, feeling: 5, notes: "手感超好，红线一把过", locationName: "岩时攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 1, hour: 10, climbType: "indoorBoulder", difficulty: "V5", completionStatus: "flash", isStarred: true, feeling: 5, notes: nil, locationName: "岩时攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 1, hour: 15, climbType: "indoorLead", difficulty: "5.11a", completionStatus: "completed", isStarred: false, feeling: 4, notes: nil, locationName: "岩舞空间（三里屯）", isOutdoor: false),
            RecordMeta(daysAgo: 3, hour: 18, climbType: "indoorBoulder", difficulty: "V6", completionStatus: "failed", isStarred: false, feeling: 2, notes: "指皮磨破了", locationName: "奥攀攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 4, hour: 9, climbType: "indoorTopRope", difficulty: "5.10c", completionStatus: "completed", isStarred: false, feeling: 3, notes: nil, locationName: "首攀攀岩（朝阳大悦城）", isOutdoor: false),
            RecordMeta(daysAgo: 5, hour: 20, climbType: "indoorBoulder", difficulty: "V3", completionStatus: "onsight", isStarred: false, feeling: 4, notes: nil, locationName: "岩时攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 7, hour: 14, climbType: "indoorLead", difficulty: "5.11c", completionStatus: "failed", isStarred: false, feeling: 2, notes: "第三把脱落", locationName: "岩舞空间（三里屯）", isOutdoor: false),
            RecordMeta(daysAgo: 8, hour: 17, climbType: "indoorBoulder", difficulty: "V4", completionStatus: "flash", isStarred: true, feeling: 5, notes: "新线首攀！", locationName: "岩时攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 10, hour: 11, climbType: "indoorBoulder", difficulty: "V5", completionStatus: "completed", isStarred: false, feeling: 3, notes: nil, locationName: "奥攀攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 12, hour: 19, climbType: "indoorTopRope", difficulty: "5.10a", completionStatus: "completed", isStarred: false, feeling: 4, notes: nil, locationName: "首攀攀岩（朝阳大悦城）", isOutdoor: false),
            RecordMeta(daysAgo: 14, hour: 10, climbType: "indoorBoulder", difficulty: "V3", completionStatus: "onsight", isStarred: false, feeling: 3, notes: nil, locationName: "岩时攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 18, hour: 16, climbType: "indoorLead", difficulty: "5.11a", completionStatus: "completed", isStarred: false, feeling: 4, notes: nil, locationName: "岩舞空间（三里屯）", isOutdoor: false),
            RecordMeta(daysAgo: 22, hour: 13, climbType: "indoorBoulder", difficulty: "V4", completionStatus: "completed", isStarred: false, feeling: 3, notes: nil, locationName: "奥攀攀岩馆", isOutdoor: false),
            RecordMeta(daysAgo: 25, hour: 18, climbType: "indoorBoulder", difficulty: "V2", completionStatus: "flash", isStarred: false, feeling: 4, notes: nil, locationName: "岩时攀岩馆", isOutdoor: false),
            // 4 outdoor
            RecordMeta(daysAgo: 15, hour: 9, climbType: "outdoorLead", difficulty: "5.10d", completionStatus: "completed", isStarred: true, feeling: 5, notes: "白河经典线路，风景绝美", locationName: "白河岩场", isOutdoor: true),
            RecordMeta(daysAgo: 20, hour: 10, climbType: "outdoorBoulder", difficulty: "V5", completionStatus: "flash", isStarred: false, feeling: 4, notes: "岩质很好", locationName: "白河岩场", isOutdoor: true),
            RecordMeta(daysAgo: 27, hour: 8, climbType: "outdoorTrad", difficulty: "5.9", completionStatus: "completed", isStarred: false, feeling: 3, notes: "第一次放传统保护", locationName: "后白河岩场", isOutdoor: true),
            RecordMeta(daysAgo: 29, hour: 9, climbType: "outdoorLead", difficulty: "5.11a", completionStatus: "failed", isStarred: false, feeling: 2, notes: "crux 过不去，下次再来", locationName: "白河岩场", isOutdoor: true),
        ]

        for e in entries {
            let start = calendar.date(byAdding: .day, value: -e.daysAgo,
                                      to: calendar.date(bySettingHour: e.hour, minute: Int.random(in: 0...59), second: 0, of: now)!)!
            let durationMin = Double(Int.random(in: 15...90))
            let duration = durationMin * 60
            let avgHR = Double(Int.random(in: 120...155))
            let maxHR = Double(Int.random(in: max(Int(avgHR) + 5, 155)...185))
            let minHR = Double(Int.random(in: 85...Int(avgHR) - 10))
            let calories = Double(Int.random(in: 100...500))

            let sampleCount = Int(durationMin / 2)
            var samples: [HeartRateSample] = []
            for s in 0..<sampleCount {
                let t = start.addingTimeInterval(Double(s) * 120)
                let bpm = Double(Int.random(in: Int(minHR)...Int(maxHR)))
                samples.append(HeartRateSample(timestamp: t, bpm: bpm))
            }

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
                climbIntervals: intervals,
                climbType: e.climbType,
                difficulty: e.difficulty,
                completionStatus: e.completionStatus,
                isStarred: e.isStarred,
                feeling: e.feeling,
                notes: e.notes,
                locationName: e.locationName,
                isOutdoor: e.isOutdoor
            )
            results.append(record)
        }
        return results
    }
}

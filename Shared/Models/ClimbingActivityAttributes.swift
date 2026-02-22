import Foundation
import ActivityKit

/// Data model for the climbing Live Activity on lock screen & Dynamic Island.
struct ClimbingActivityAttributes: ActivityAttributes {

    // MARK: - Static (set once when activity starts)

    /// Session start time — used by Text(date, style: .timer) for real-time elapsed display
    var startTime: Date

    // MARK: - Dynamic content state (updated on each route log)

    struct ContentState: Codable, Hashable {
        /// Difficulty grades, e.g. ["V3", "V5", "5.10a"]
        var difficulties: [String]
        /// Counts per difficulty (parallel array), e.g. [2, 1, 3]
        var counts: [Int]
        /// Number of completed routes (完攀/Flash/Onsight)
        var sentCount: Int
        /// Total routes logged
        var totalCount: Int

        /// Display text for completion ratio, e.g. "2/3"
        var completionText: String {
            "\(sentCount)/\(totalCount)"
        }

        /// Completion percentage 0.0–1.0
        var completionRatio: Double {
            totalCount > 0 ? Double(sentCount) / Double(totalCount) : 0
        }

        /// Zipped difficulty pills for display
        var difficultyPills: [(difficulty: String, count: Int)] {
            zip(difficulties, counts).map { ($0, $1) }
        }
    }
}

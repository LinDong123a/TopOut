import Foundation
import ActivityKit

/// Manages the climbing Live Activity lifecycle.
/// Called from ClimbSessionState on session start / route update / session end.
@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<ClimbingActivityAttributes>?

    private init() {}

    // MARK: - Start

    func startLiveActivity(startTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }

        // End any stale activities first
        for activity in Activity<ClimbingActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        let attributes = ClimbingActivityAttributes(startTime: startTime)
        let initialState = ClimbingActivityAttributes.ContentState(
            difficulties: [],
            counts: [],
            sentCount: 0,
            totalCount: 0
        )
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("[LiveActivity] Started: \(currentActivity?.id ?? "nil")")
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    // MARK: - Update

    func updateLiveActivity(routeRecords: [RouteRecord]) {
        guard let activity = currentActivity else { return }

        let state = buildContentState(from: routeRecords)
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    // MARK: - End

    func endLiveActivity(routeRecords: [RouteRecord]) {
        guard let activity = currentActivity else { return }

        let finalState = buildContentState(from: routeRecords)
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 300))
            print("[LiveActivity] Ended")
        }
        currentActivity = nil
    }

    // MARK: - Private

    private func buildContentState(from records: [RouteRecord]) -> ClimbingActivityAttributes.ContentState {
        var difficultyMap: [String: Int] = [:]
        var sentCount = 0

        for record in records {
            difficultyMap[record.difficulty, default: 0] += 1
            if record.sendStatus == .sent {
                sentCount += 1
            }
        }

        let sorted = difficultyMap.sorted { $0.key < $1.key }

        return ClimbingActivityAttributes.ContentState(
            difficulties: sorted.map { $0.key },
            counts: sorted.map { $0.value },
            sentCount: sentCount,
            totalCount: records.count
        )
    }
}

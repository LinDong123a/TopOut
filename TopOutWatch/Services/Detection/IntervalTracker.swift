import Foundation

/// Tracks climbing/resting intervals with detailed per-interval metrics.
/// Produces session-level statistics on demand.
final class IntervalTracker {

    /// A completed or in-progress interval
    struct Interval {
        let startTime: Date
        var endTime: Date?
        let isClimbing: Bool
        var altitudeGain: Double = 0
        var averageHeartRate: Double = 0
        var maxHeartRate: Double = 0
        var heartRateZone: Int = 0
        var averageConfidence: Double = 0
        private var hrSum: Double = 0
        private var hrCount: Int = 0
        private var confidenceSum: Double = 0
        private var confidenceCount: Int = 0

        init(startTime: Date, endTime: Date? = nil, isClimbing: Bool) {
            self.startTime = startTime
            self.endTime = endTime
            self.isClimbing = isClimbing
        }

        var duration: TimeInterval {
            (endTime ?? Date()).timeIntervalSince(startTime)
        }

        mutating func addHeartRate(_ bpm: Double) {
            guard bpm > 0 else { return }
            hrSum += bpm
            hrCount += 1
            averageHeartRate = hrSum / Double(hrCount)
            maxHeartRate = max(maxHeartRate, bpm)
        }

        mutating func addConfidence(_ c: Double) {
            confidenceSum += c
            confidenceCount += 1
            averageConfidence = confidenceSum / Double(confidenceCount)
        }

        func toClimbInterval() -> ClimbInterval {
            ClimbInterval(
                startTime: startTime,
                endTime: endTime ?? Date(),
                isClimbing: isClimbing
            )
        }

        func toMetrics() -> ClimbIntervalMetrics {
            ClimbIntervalMetrics(
                startTime: startTime,
                endTime: endTime ?? Date(),
                isClimbing: isClimbing,
                altitudeGain: altitudeGain,
                averageHeartRate: averageHeartRate,
                maxHeartRate: maxHeartRate,
                heartRateZone: heartRateZone,
                averageConfidence: averageConfidence
            )
        }
    }

    // MARK: - State

    private var intervals: [Interval] = []
    private var currentInterval: Interval?
    private var sessionStartTime: Date?

    // MARK: - Lifecycle

    func startSession() {
        intervals.removeAll()
        currentInterval = nil
        sessionStartTime = Date()
    }

    func endSession() {
        closeCurrentInterval()
    }

    // MARK: - State Transitions

    /// Called when ClimbStateMachine changes state
    func onStateChanged(_ state: ClimbState) {
        let now = Date()

        // Close current interval
        closeCurrentInterval()

        // Start new interval (don't track idle separately)
        if state == .climbing || state == .resting {
            currentInterval = Interval(startTime: now, isClimbing: state == .climbing)
        }
    }

    // MARK: - Feed Metrics

    /// Feed heart rate for current interval
    func updateHeartRate(_ bpm: Double) {
        currentInterval?.addHeartRate(bpm)
    }

    /// Feed confidence score for current interval
    func updateConfidence(_ confidence: Double) {
        currentInterval?.addConfidence(confidence)
    }

    /// Feed altitude gain for current interval
    func updateAltitudeGain(_ gain: Double) {
        currentInterval?.altitudeGain = gain
    }

    /// Feed heart rate zone for current interval
    func updateHeartRateZone(_ zone: Int) {
        currentInterval?.heartRateZone = zone
    }

    // MARK: - Queries

    /// All completed intervals
    var completedIntervals: [Interval] { intervals }

    /// Current (in-progress) interval
    var activeInterval: Interval? { currentInterval }

    /// All intervals as ClimbInterval (for ClimbRecord compatibility)
    func allClimbIntervals() -> [ClimbInterval] {
        var result = intervals.map { $0.toClimbInterval() }
        if let current = currentInterval {
            result.append(current.toClimbInterval())
        }
        return result
    }

    /// All intervals as ClimbIntervalMetrics
    func allIntervalMetrics() -> [ClimbIntervalMetrics] {
        var result = intervals.map { $0.toMetrics() }
        if let current = currentInterval {
            result.append(current.toMetrics())
        }
        return result
    }

    /// Session-level metrics
    func sessionMetrics(peakHR: Double = 0, avgClimbingHR: Double = 0, avgRestingHR: Double = 0, totalAltGain: Double = 0) -> SessionMetrics {
        let allIntervals = intervals + (currentInterval.map { [$0] } ?? [])
        let climbIntervals = allIntervals.filter { $0.isClimbing }
        let restIntervals = allIntervals.filter { !$0.isClimbing }

        let totalClimbTime = climbIntervals.reduce(0) { $0 + $1.duration }
        let totalRestTime = restIntervals.reduce(0) { $0 + $1.duration }

        return SessionMetrics(
            totalAltitudeGain: totalAltGain,
            totalClimbingTime: totalClimbTime,
            totalRestingTime: totalRestTime,
            climbIntervalCount: climbIntervals.count,
            averageClimbDuration: climbIntervals.isEmpty ? 0 : totalClimbTime / Double(climbIntervals.count),
            averageRestDuration: restIntervals.isEmpty ? 0 : totalRestTime / Double(restIntervals.count),
            peakHeartRate: peakHR,
            averageClimbingHR: avgClimbingHR,
            averageRestingHR: avgRestingHR
        )
    }

    /// Duration of current climbing interval (nil if not climbing)
    var currentClimbDuration: TimeInterval? {
        guard let interval = currentInterval, interval.isClimbing else { return nil }
        return interval.duration
    }

    /// Number of climb→rest transitions
    var climbIntervalCount: Int {
        intervals.filter { $0.isClimbing }.count + (currentInterval?.isClimbing == true ? 1 : 0)
    }

    // MARK: - Private

    private func closeCurrentInterval() {
        guard var interval = currentInterval else { return }
        interval.endTime = Date()
        intervals.append(interval)
        currentInterval = nil
    }
}

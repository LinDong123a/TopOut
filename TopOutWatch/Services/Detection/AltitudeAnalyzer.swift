import Foundation
import CoreMotion

/// Analyzes barometric altimeter data to detect vertical movement (climbing / descending).
/// Only active when SensorCapability.hasAltimeter == true.
final class AltitudeAnalyzer {

    struct Result {
        /// 0.0 (no altitude change) to 1.0 (significant ascent)
        let altitudeScore: Double
        /// Total altitude gained during session (meters)
        let totalGain: Double
        /// Current rate of altitude change (m/s), positive = ascending
        let currentRate: Double
    }

    // MARK: - State

    private let altimeter = CMAltimeter()
    private var isRunning = false

    /// Relative altitude samples: (timestamp, relativeAltitude in meters)
    private var altitudeBuffer = RingBuffer<(time: TimeInterval, altitude: Double)>(capacity: 60)
    /// Session start reference time
    private var sessionStartTime: TimeInterval = 0
    /// Running total of altitude gained (only positive deltas)
    private(set) var totalGain: Double = 0
    /// Previous altitude reading for delta computation
    private var previousAltitude: Double?

    // MARK: - Thresholds

    /// Rate above this (m/s) is considered active ascent
    private let significantRate: Double = 0.05  // 5 cm/s
    /// Maximum rate for score saturation
    private let maxRate: Double = 0.5  // 50 cm/s (fast climb)

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        isRunning = true
        sessionStartTime = Date().timeIntervalSince1970
        totalGain = 0
        previousAltitude = nil
        altitudeBuffer.reset()

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            self.processAltitudeData(data)
        }
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
    }

    func reset() {
        totalGain = 0
        previousAltitude = nil
        altitudeBuffer.reset()
    }

    // MARK: - Process

    private func processAltitudeData(_ data: CMAltitudeData) {
        let altitude = data.relativeAltitude.doubleValue  // meters relative to start
        let time = data.timestamp

        altitudeBuffer.append((time: time, altitude: altitude))

        // Accumulate positive altitude gain
        if let prev = previousAltitude {
            let delta = altitude - prev
            if delta > 0.01 { // filter noise: only count > 1cm
                totalGain += delta
            }
        }
        previousAltitude = altitude
    }

    // MARK: - Compute

    /// Compute current altitude analysis result
    func currentResult() -> Result {
        let rate = computeRate()
        let score = computeScore(rate: rate)
        return Result(altitudeScore: score, totalGain: totalGain, currentRate: rate)
    }

    /// Altitude change rate over the last 5 seconds
    private func computeRate() -> Double {
        let samples = altitudeBuffer.last(10) // ~5-10 seconds of data
        guard samples.count >= 2 else { return 0 }

        let first = samples.first!
        let last = samples.last!
        let dt = last.time - first.time
        guard dt > 0.5 else { return 0 }

        return (last.altitude - first.altitude) / dt
    }

    /// Convert rate to a 0-1 score
    private func computeScore(rate: Double) -> Double {
        // Only positive (ascending) rates contribute to climbing score
        guard rate > 0 else {
            // Small score for any non-zero rate (descending also means activity)
            if abs(rate) > significantRate {
                return 0.15
            }
            return 0.0
        }

        if rate < significantRate {
            return 0.05 // trivial movement
        }

        // Linear scale from significantRate to maxRate → 0.2 to 1.0
        let normalized = (rate - significantRate) / (maxRate - significantRate)
        return min(max(normalized * 0.8 + 0.2, 0.0), 1.0)
    }
}

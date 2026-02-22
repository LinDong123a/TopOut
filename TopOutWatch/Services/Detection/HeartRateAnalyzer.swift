import Foundation

/// Heart rate zone classification and climbing confidence scoring.
/// HR is a confirming signal (lags 5-15s behind activity), not a leading one.
final class HeartRateAnalyzer {

    struct Result {
        /// 0.0 (resting HR) to 1.0 (peak exertion HR)
        let hrScore: Double
        /// Current heart rate zone
        let zone: HRZone
        /// Rate of change in BPM per minute (positive = increasing)
        let rateOfChange: Double
        /// Current BPM
        let currentBPM: Double
    }

    // MARK: - State

    /// Recent HR samples with timestamps
    private var hrBuffer = RingBuffer<(time: Date, bpm: Double)>(capacity: 30) // ~30 seconds
    /// User's estimated resting HR (updated adaptively)
    private var restingHR: Double = 70
    /// User's estimated max HR (age-based default, can be calibrated)
    private var maxHR: Double = 190

    // MARK: - Configuration

    /// Set user profile for better zone estimation
    func configure(restingHR: Double? = nil, maxHR: Double? = nil) {
        if let rhr = restingHR { self.restingHR = rhr }
        if let mhr = maxHR { self.maxHR = mhr }
    }

    // MARK: - Feed Data

    /// Feed a new heart rate reading (called from WorkoutService callback)
    func update(bpm: Double) {
        guard bpm > 0 else { return }
        hrBuffer.append((time: Date(), bpm: bpm))
    }

    func reset() {
        hrBuffer.reset()
    }

    // MARK: - Compute

    func currentResult() -> Result {
        let samples = hrBuffer.toArray()
        guard let latest = samples.last else {
            return Result(hrScore: 0, zone: .rest, rateOfChange: 0, currentBPM: 0)
        }

        let bpm = latest.bpm
        let zone = classifyZone(bpm: bpm)
        let roc = computeRateOfChange(samples: samples)
        let score = computeScore(bpm: bpm, zone: zone, roc: roc)

        return Result(hrScore: score, zone: zone, rateOfChange: roc, currentBPM: bpm)
    }

    // MARK: - Zone Classification (Karvonen method)

    private func classifyZone(bpm: Double) -> HRZone {
        let hrReserve = maxHR - restingHR
        let intensity = (bpm - restingHR) / max(hrReserve, 1)

        switch intensity {
        case ..<0.5:      return .rest      // < 50% HRR
        case 0.5..<0.6:   return .light     // 50-60% HRR
        case 0.6..<0.7:   return .moderate  // 60-70% HRR
        case 0.7..<0.85:  return .vigorous  // 70-85% HRR
        default:          return .peak      // 85%+ HRR
        }
    }

    // MARK: - Rate of Change

    /// BPM change per minute, computed over last 15 seconds
    private func computeRateOfChange(samples: [(time: Date, bpm: Double)]) -> Double {
        guard samples.count >= 2 else { return 0 }

        // Use samples from last ~15 seconds
        let now = Date()
        let recentSamples = samples.filter { now.timeIntervalSince($0.time) < 15 }
        guard recentSamples.count >= 2 else { return 0 }

        let first = recentSamples.first!
        let last = recentSamples.last!
        let dt = last.time.timeIntervalSince(first.time)
        guard dt > 2 else { return 0 }

        let dBPM = last.bpm - first.bpm
        return dBPM / (dt / 60.0) // BPM per minute
    }

    // MARK: - Scoring

    private func computeScore(bpm: Double, zone: HRZone, roc: Double) -> Double {
        // Base score from zone
        let baseScore: Double
        switch zone {
        case .rest:     baseScore = 0.05
        case .light:    baseScore = 0.25
        case .moderate: baseScore = 0.50
        case .vigorous: baseScore = 0.75
        case .peak:     baseScore = 0.95
        }

        // Bonus for rising HR (indicates recent onset of activity)
        let rocBonus: Double
        if roc > 5 {
            rocBonus = min(roc / 30.0, 0.15)  // up to 0.15 bonus
        } else if roc < -5 {
            rocBonus = max(roc / 30.0, -0.1)  // small penalty for falling HR
        } else {
            rocBonus = 0
        }

        return min(max(baseScore + rocBonus, 0.0), 1.0)
    }
}

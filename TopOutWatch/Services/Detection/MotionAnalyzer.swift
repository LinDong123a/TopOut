import Foundation
import CoreMotion

/// Analyzes CMDeviceMotion (or raw accelerometer) to produce a climbing likelihood score.
/// Features: userAcceleration RMS, pitch variance, rotation rate RMS, walking detection via autocorrelation.
final class MotionAnalyzer {

    struct Result {
        /// 0.0 (no motion / resting) to 1.0 (strong climbing signal)
        let motionScore: Double
        /// True if periodic walking pattern detected (suppresses climb detection)
        let isWalkingDetected: Bool
        /// RMS of user acceleration (gravity removed)
        let accelRMS: Double
        /// Peak acceleration magnitude in recent window
        let peakAccel: Double
    }

    // MARK: - Buffers

    /// Acceleration magnitude buffer for RMS / variance (10Hz × 5s = 50 samples)
    private var accelBuffer = RingBuffer<Double>(capacity: 50)
    /// Pitch values for attitude change detection
    private var pitchBuffer = RingBuffer<Double>(capacity: 50)
    /// Rotation rate magnitude buffer
    private var rotationBuffer = RingBuffer<Double>(capacity: 50)
    /// Longer buffer for walking autocorrelation (10Hz × 4s = 40)
    private var walkBuffer = RingBuffer<Double>(capacity: 40)

    /// Whether we're using DeviceMotion (gravity-separated) or raw accelerometer
    private let useDeviceMotion: Bool

    // MARK: - Thresholds

    /// Minimum accel RMS to consider "active motion"
    private let accelRMSClimbing: Double = 0.12
    /// Peak acceleration threshold
    private let peakAccelThreshold: Double = 0.6
    /// Walking autocorrelation peak threshold (0 = no correlation, 1 = perfect periodicity)
    private let walkCorrelationThreshold: Double = 0.45
    /// Walking frequency range: 1.4 – 2.5 Hz (lag 4-7 at 10Hz)
    private let walkLagRange = 4...7

    init(useDeviceMotion: Bool) {
        self.useDeviceMotion = useDeviceMotion
    }

    // MARK: - Feed Data

    /// Feed a CMDeviceMotion sample (preferred — gravity-separated)
    func process(deviceMotion dm: CMDeviceMotion) -> Result {
        let ua = dm.userAcceleration
        let accelMag = sqrt(ua.x * ua.x + ua.y * ua.y + ua.z * ua.z)

        accelBuffer.append(accelMag)
        walkBuffer.append(accelMag)
        pitchBuffer.append(dm.attitude.pitch)

        let rr = dm.rotationRate
        let rotMag = sqrt(rr.x * rr.x + rr.y * rr.y + rr.z * rr.z)
        rotationBuffer.append(rotMag)

        return computeResult()
    }

    /// Feed raw CMAccelerometerData (fallback when DeviceMotion unavailable)
    func process(accelerometer data: CMAccelerometerData) -> Result {
        let a = data.acceleration
        let rawMag = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
        // Remove approximate gravity (1g)
        let accelMag = abs(rawMag - 1.0)

        accelBuffer.append(accelMag)
        walkBuffer.append(accelMag)
        // No pitch / rotation available in raw mode

        return computeResult()
    }

    func reset() {
        accelBuffer.reset()
        pitchBuffer.reset()
        rotationBuffer.reset()
        walkBuffer.reset()
    }

    // MARK: - Compute

    private func computeResult() -> Result {
        let recentAccel = accelBuffer.last(20) // last 2 seconds
        guard recentAccel.count >= 10 else {
            return Result(motionScore: 0, isWalkingDetected: false, accelRMS: 0, peakAccel: 0)
        }

        // 1. Acceleration RMS
        let accelRMS = rms(recentAccel)

        // 2. Peak acceleration
        let peakAccel = recentAccel.max() ?? 0

        // 3. Pitch variance (only with DeviceMotion)
        let pitchVar: Double
        if useDeviceMotion {
            let recentPitch = pitchBuffer.last(20)
            pitchVar = variance(recentPitch)
        } else {
            pitchVar = 0
        }

        // 4. Rotation rate RMS (only with DeviceMotion)
        let rotRMS: Double
        if useDeviceMotion {
            let recentRot = rotationBuffer.last(20)
            rotRMS = rms(recentRot)
        } else {
            rotRMS = 0
        }

        // 5. Walking detection via autocorrelation
        let isWalking = detectWalking()

        // 6. Compute motion score
        let score = computeMotionScore(accelRMS: accelRMS, peakAccel: peakAccel, pitchVar: pitchVar, rotRMS: rotRMS)

        return Result(
            motionScore: score,
            isWalkingDetected: isWalking,
            accelRMS: accelRMS,
            peakAccel: peakAccel
        )
    }

    private func computeMotionScore(accelRMS: Double, peakAccel: Double, pitchVar: Double, rotRMS: Double) -> Double {
        // Sub-scores (each 0-1)
        let accelScore = min(accelRMS / 0.5, 1.0) // saturates at 0.5g RMS
        let peakScore = min(peakAccel / 1.2, 1.0)  // saturates at 1.2g peak

        if useDeviceMotion {
            // Pitch variance score: climbing involves arm raising (pitch change)
            let pitchScore = min(pitchVar / 0.15, 1.0)
            // Rotation score: climbing involves wrist rotation
            let rotScore = min(rotRMS / 2.0, 1.0)

            // Weighted blend of sub-features
            return clamp(accelScore * 0.35 + peakScore * 0.25 + pitchScore * 0.20 + rotScore * 0.20)
        } else {
            // Fallback: only acceleration features
            return clamp(accelScore * 0.6 + peakScore * 0.4)
        }
    }

    // MARK: - Walking Detection (Autocorrelation)

    /// Detect periodic walking pattern by looking for autocorrelation peaks in the walk frequency range
    private func detectWalking() -> Bool {
        let samples = walkBuffer.toArray()
        guard samples.count >= 30 else { return false }

        let mean = samples.reduce(0, +) / Double(samples.count)
        let centered = samples.map { $0 - mean }

        // Variance (autocorrelation at lag 0)
        let variance = centered.reduce(0) { $0 + $1 * $1 } / Double(centered.count)
        guard variance > 0.001 else { return false } // too still for walking

        // Compute normalized autocorrelation at walking-frequency lags
        var maxCorrelation: Double = 0
        for lag in walkLagRange {
            var sum: Double = 0
            let n = centered.count - lag
            guard n > 0 else { continue }
            for i in 0..<n {
                sum += centered[i] * centered[i + lag]
            }
            let correlation = sum / (Double(n) * variance)
            maxCorrelation = max(maxCorrelation, correlation)
        }

        return maxCorrelation > walkCorrelationThreshold
    }

    // MARK: - Math Helpers

    private func rms(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sumSq = values.reduce(0) { $0 + $1 * $1 }
        return sqrt(sumSq / Double(values.count))
    }

    private func variance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }
}

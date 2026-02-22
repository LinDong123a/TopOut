import Foundation

/// Fuses multiple sensor signals into a single climbing confidence score.
/// Automatically adapts weights based on which sensors are available at runtime.
final class SignalFusionEngine {

    struct FusionResult {
        /// 0.0 (definitely resting) to 1.0 (definitely climbing)
        let confidence: Double
        /// Individual signal contributions for debugging/telemetry
        let motionScore: Double
        let altitudeScore: Double
        let hrScore: Double
        /// Walking penalty applied
        let walkingPenalty: Double
        /// Floors bonus applied
        let floorBonus: Double
    }

    // MARK: - Base Weights (all sensors available)

    /// Default weights when all sensors present
    private struct BaseWeights {
        static let motion: Double = 0.45
        static let altitude: Double = 0.25
        static let heartRate: Double = 0.15
        static let pedometer: Double = 0.15
    }

    // MARK: - Active Weights

    private var motionWeight: Double = 0
    private var altitudeWeight: Double = 0
    private var heartRateWeight: Double = 0
    private var pedometerWeight: Double = 0

    /// Walking detection penalty factor
    private let walkingPenaltyFactor: Double = 0.35

    /// Floor ascent bonus factor (floors are strong climb indicator)
    private let floorBonusFactor: Double = 0.15

    // MARK: - Configuration

    /// Configure weights based on detected sensor capabilities
    func configure(capability: SensorCapability) {
        // Determine which signals are available and their base weights
        let hasMotion = capability.hasDeviceMotion || capability.hasAccelerometer
        let hasAlt = capability.hasAltimeter
        let hasHR = capability.hasHeartRate
        let hasPed = capability.hasPedometer

        // Sum available base weights for normalization
        var totalBase: Double = 0
        if hasMotion { totalBase += BaseWeights.motion }
        if hasAlt    { totalBase += BaseWeights.altitude }
        if hasHR     { totalBase += BaseWeights.heartRate }
        if hasPed    { totalBase += BaseWeights.pedometer }

        guard totalBase > 0 else { return }

        // Normalize: each active weight = base / totalBase (sums to 1.0)
        motionWeight    = hasMotion ? BaseWeights.motion / totalBase : 0
        altitudeWeight  = hasAlt    ? BaseWeights.altitude / totalBase : 0
        heartRateWeight = hasHR     ? BaseWeights.heartRate / totalBase : 0
        pedometerWeight = hasPed    ? BaseWeights.pedometer / totalBase : 0

        print("[SignalFusion] Configured weights: motion=\(f(motionWeight)) altitude=\(f(altitudeWeight)) hr=\(f(heartRateWeight)) pedometer=\(f(pedometerWeight))")
    }

    // MARK: - Fusion

    /// Compute fused climbing confidence
    func fuse(
        motionResult: MotionAnalyzer.Result?,
        altitudeResult: AltitudeAnalyzer.Result?,
        hrResult: HeartRateAnalyzer.Result?,
        pedometerResult: PedometerAnalyzer.Result?
    ) -> FusionResult {

        var weightedSum: Double = 0
        var totalWeight: Double = 0
        var walkingPenalty: Double = 0
        var floorBonus: Double = 0

        let mScore = motionResult?.motionScore ?? 0
        let aScore = altitudeResult?.altitudeScore ?? 0
        let hScore = hrResult?.hrScore ?? 0

        // 1. Motion signal
        if motionWeight > 0, let motion = motionResult {
            weightedSum += motionWeight * motion.motionScore
            totalWeight += motionWeight

            // Walking penalty: if motion analyzer + pedometer both detect walking
            if motion.isWalkingDetected {
                walkingPenalty += walkingPenaltyFactor * 0.5
            }
        }

        // 2. Altitude signal
        if altitudeWeight > 0, let altitude = altitudeResult {
            weightedSum += altitudeWeight * altitude.altitudeScore
            totalWeight += altitudeWeight
        }

        // 3. Heart rate signal
        if heartRateWeight > 0, let hr = hrResult {
            weightedSum += heartRateWeight * hr.hrScore
            totalWeight += heartRateWeight
        }

        // 4. Pedometer signal (contributes via penalty / bonus, not direct score)
        if pedometerWeight > 0, let ped = pedometerResult {
            if ped.isFlatWalking {
                // Flat walking → strong penalty
                walkingPenalty += walkingPenaltyFactor * 0.5
            }
            if ped.recentFloorsAscended > 0 {
                // Floor ascent → bonus (climbing or ascending)
                floorBonus = floorBonusFactor * Double(min(ped.recentFloorsAscended, 3))
            }
        }

        // Compute base confidence
        let baseConfidence: Double
        if totalWeight > 0 {
            baseConfidence = weightedSum / totalWeight
        } else {
            baseConfidence = 0
        }

        // Apply penalties and bonuses
        let confidence = clamp(baseConfidence - walkingPenalty + floorBonus)

        return FusionResult(
            confidence: confidence,
            motionScore: mScore,
            altitudeScore: aScore,
            hrScore: hScore,
            walkingPenalty: walkingPenalty,
            floorBonus: floorBonus
        )
    }

    // MARK: - Helpers

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }

    private func f(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

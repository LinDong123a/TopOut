import Foundation
import CoreMotion
import HealthKit

/// Runtime detection of available watch sensors for adaptive algorithm fusion
struct SensorCapability {
    let hasAccelerometer: Bool
    let hasGyroscope: Bool
    let hasDeviceMotion: Bool
    let hasMagnetometer: Bool
    let hasAltimeter: Bool
    let hasHeartRate: Bool
    let hasPedometer: Bool
    let hasFloorCounting: Bool

    /// Number of signal sources available for fusion
    var availableSignalCount: Int {
        var count = 0
        if hasDeviceMotion || hasAccelerometer { count += 1 }  // motion signal
        if hasAltimeter { count += 1 }
        if hasHeartRate { count += 1 }
        if hasPedometer { count += 1 }
        return count
    }

    /// One-time detection at startup
    static func detect() -> SensorCapability {
        let motion = CMMotionManager()
        let capability = SensorCapability(
            hasAccelerometer: motion.isAccelerometerAvailable,
            hasGyroscope: motion.isGyroAvailable,
            hasDeviceMotion: motion.isDeviceMotionAvailable,
            hasMagnetometer: motion.isMagnetometerAvailable,
            hasAltimeter: CMAltimeter.isRelativeAltitudeAvailable(),
            hasHeartRate: HKHealthStore.isHealthDataAvailable(),
            hasPedometer: CMPedometer.isStepCountingAvailable(),
            hasFloorCounting: CMPedometer.isFloorCountingAvailable()
        )

        print("[SensorCapability] Detected sensors:")
        print("  Accelerometer: \(capability.hasAccelerometer)")
        print("  Gyroscope: \(capability.hasGyroscope)")
        print("  DeviceMotion: \(capability.hasDeviceMotion)")
        print("  Magnetometer: \(capability.hasMagnetometer)")
        print("  Altimeter: \(capability.hasAltimeter)")
        print("  HeartRate: \(capability.hasHeartRate)")
        print("  Pedometer: \(capability.hasPedometer)")
        print("  FloorCounting: \(capability.hasFloorCounting)")
        print("  Available signal count: \(capability.availableSignalCount)")

        return capability
    }

    /// Whether we can use fused DeviceMotion (accel + gyro + magnetometer)
    var canUseDeviceMotion: Bool { hasDeviceMotion }

    /// Whether we have only basic accelerometer (fallback mode)
    var isAccelerometerOnly: Bool { hasAccelerometer && !hasDeviceMotion }

    /// Human-readable summary
    var summary: String {
        var parts: [String] = []
        if hasDeviceMotion { parts.append("DeviceMotion") }
        else if hasAccelerometer { parts.append("Accelerometer") }
        if hasAltimeter { parts.append("Altimeter") }
        if hasHeartRate { parts.append("HeartRate") }
        if hasPedometer { parts.append("Pedometer") }
        return parts.joined(separator: " + ")
    }
}

import Foundation
import CoreMotion

/// Analyzes pedometer data (step count + floor counting) to assist climb detection.
/// - Floor ascent strongly suggests vertical movement (climbing)
/// - Steps without floors = flat walking → suppresses climb detection
final class PedometerAnalyzer {

    struct Result {
        /// Whether flat walking is detected (steps but no floors)
        let isFlatWalking: Bool
        /// Recent floors ascended (strong climb indicator)
        let recentFloorsAscended: Int
        /// Recent step count
        let recentSteps: Int
        /// Total floors ascended during session
        let totalFloorsAscended: Int
    }

    // MARK: - State

    private let pedometer = CMPedometer()
    private var isRunning = false
    private let hasFloorCounting: Bool

    /// Current window data
    private var currentSteps: Int = 0
    private var currentFloorsAscended: Int = 0
    private var currentFloorsDescended: Int = 0

    /// Session totals
    private(set) var totalFloorsAscended: Int = 0
    private(set) var totalSteps: Int = 0

    /// Previous query values for delta computation
    private var previousSteps: Int = 0
    private var previousFloors: Int = 0

    /// Query interval tracking
    private var sessionStartDate: Date?
    private var lastQueryDate: Date?

    init(hasFloorCounting: Bool) {
        self.hasFloorCounting = hasFloorCounting
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let now = Date()
        sessionStartDate = now
        lastQueryDate = now
        totalFloorsAscended = 0
        totalSteps = 0
        previousSteps = 0
        previousFloors = 0
        currentSteps = 0
        currentFloorsAscended = 0

        // Start live updates
        pedometer.startUpdates(from: now) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            self.processPedometerData(data)
        }
    }

    func stop() {
        pedometer.stopUpdates()
        isRunning = false
    }

    func reset() {
        totalFloorsAscended = 0
        totalSteps = 0
        currentSteps = 0
        currentFloorsAscended = 0
        previousSteps = 0
        previousFloors = 0
    }

    // MARK: - Process

    private func processPedometerData(_ data: CMPedometerData) {
        let steps = data.numberOfSteps.intValue
        let floorsUp = data.floorsAscended?.intValue ?? 0

        // Delta since last update
        let deltaSteps = max(steps - previousSteps, 0)
        let deltaFloors = max(floorsUp - previousFloors, 0)

        previousSteps = steps
        previousFloors = floorsUp

        // Update running values
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentSteps = deltaSteps
            self.currentFloorsAscended = deltaFloors
            self.totalSteps += deltaSteps
            self.totalFloorsAscended += deltaFloors
        }
    }

    // MARK: - Compute

    func currentResult() -> Result {
        let isFlatWalking: Bool
        if currentSteps > 5 && currentFloorsAscended == 0 {
            // Significant steps but no vertical movement → flat walking
            isFlatWalking = true
        } else {
            isFlatWalking = false
        }

        return Result(
            isFlatWalking: isFlatWalking,
            recentFloorsAscended: currentFloorsAscended,
            recentSteps: currentSteps,
            totalFloorsAscended: totalFloorsAscended
        )
    }
}

import Foundation

/// Hysteresis state machine for stable climb state transitions.
/// - Enter climbing: confidence > 0.55 for 0.5s (5 consecutive samples at 10Hz)
/// - Exit climbing:  confidence < 0.30 for 0.5s
/// - Resting → Idle: after 45s of continuous rest
/// - Minimum dwell: climbing 3s, resting 5s before allowing transition
final class ClimbStateMachine {

    // MARK: - Thresholds

    /// Confidence above this enters climbing
    private let enterThreshold: Double = 0.55
    /// Confidence below this exits climbing
    private let exitThreshold: Double = 0.30
    /// Consecutive confirmations needed (at 10Hz, 5 = 0.5s)
    private let confirmationSamples: Int = 5
    /// Minimum time in climbing state before allowing exit (seconds)
    private let minClimbDwell: TimeInterval = 3.0
    /// Minimum time in resting state before allowing re-entry (seconds)
    private let minRestDwell: TimeInterval = 5.0
    /// Resting duration before auto-transitioning to idle (seconds)
    private let idleTimeout: TimeInterval = 45.0

    // MARK: - State

    private(set) var currentState: ClimbState = .idle
    private var stateEnteredAt: Date = Date()
    private var consecutiveAbove: Int = 0
    private var consecutiveBelow: Int = 0

    /// Callback when state changes
    var onStateChanged: ((ClimbState) -> Void)?

    // MARK: - Feed

    /// Feed a new confidence sample (called at ~10Hz)
    func update(confidence: Double, now: Date = Date()) {
        let dwellTime = now.timeIntervalSince(stateEnteredAt)

        switch currentState {
        case .idle:
            // From idle, any significant confidence starts climbing
            if confidence > enterThreshold {
                consecutiveAbove += 1
                consecutiveBelow = 0
                if consecutiveAbove >= confirmationSamples {
                    transitionTo(.climbing, at: now)
                }
            } else {
                consecutiveAbove = 0
            }

        case .climbing:
            if confidence < exitThreshold {
                consecutiveBelow += 1
                consecutiveAbove = 0
                // Only allow exit after minimum dwell
                if consecutiveBelow >= confirmationSamples && dwellTime >= minClimbDwell {
                    transitionTo(.resting, at: now)
                }
            } else {
                consecutiveBelow = 0
                // Keep refreshing above counter
                if confidence > enterThreshold {
                    consecutiveAbove += 1
                }
            }

        case .resting:
            if confidence > enterThreshold {
                consecutiveAbove += 1
                consecutiveBelow = 0
                // Only allow re-entry after minimum rest dwell
                if consecutiveAbove >= confirmationSamples && dwellTime >= minRestDwell {
                    transitionTo(.climbing, at: now)
                }
            } else {
                consecutiveAbove = 0
                if confidence < exitThreshold {
                    consecutiveBelow += 1
                }
                // Auto-transition to idle after extended rest
                if dwellTime >= idleTimeout {
                    transitionTo(.idle, at: now)
                }
            }
        }
    }

    // MARK: - Control

    func reset() {
        currentState = .idle
        stateEnteredAt = Date()
        consecutiveAbove = 0
        consecutiveBelow = 0
    }

    /// Force a specific state (e.g., when session starts/ends)
    func forceState(_ state: ClimbState) {
        if currentState != state {
            currentState = state
            stateEnteredAt = Date()
            consecutiveAbove = 0
            consecutiveBelow = 0
            onStateChanged?(state)
        }
    }

    /// Time spent in current state
    var currentDwellTime: TimeInterval {
        Date().timeIntervalSince(stateEnteredAt)
    }

    // MARK: - Private

    private func transitionTo(_ newState: ClimbState, at time: Date) {
        guard newState != currentState else { return }
        currentState = newState
        stateEnteredAt = time
        consecutiveAbove = 0
        consecutiveBelow = 0
        onStateChanged?(newState)
    }
}

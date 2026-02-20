import Foundation
import HealthKit
import Combine

/// P0: Heart rate collection via HKWorkoutSession + HKLiveWorkoutBuilder
final class WorkoutService: NSObject, ObservableObject {
    @Published var currentHeartRate: Double = 0
    @Published var isSessionActive = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRateSamples: [HeartRateSample] = []
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var sessionStartDate: Date?
    private var timer: Timer?
    
    var onHeartRateUpdate: ((Double) -> Void)?
    var onSessionEnded: ((ClimbRecord) -> Void)?
    
    override init() {
        super.init()
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }
    
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .climbing
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            sessionStartDate = Date()
            heartRateSamples = []
            
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            workoutBuilder?.beginCollection(withStart: startDate) { [weak self] success, error in
                guard success else {
                    print("Failed to begin collection: \(error?.localizedDescription ?? "")")
                    return
                }
                DispatchQueue.main.async {
                    self?.isSessionActive = true
                    self?.startTimer()
                }
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func endWorkout() {
        workoutSession?.end()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func buildClimbRecord() -> ClimbRecord {
        let record = ClimbRecord(
            startTime: sessionStartDate ?? Date(),
            endTime: Date(),
            duration: elapsedTime,
            averageHeartRate: heartRateSamples.isEmpty ? 0 : heartRateSamples.map(\.bpm).reduce(0, +) / Double(heartRateSamples.count),
            maxHeartRate: heartRateSamples.map(\.bpm).max() ?? 0,
            minHeartRate: heartRateSamples.map(\.bpm).min() ?? 0,
            calories: 0,
            heartRateSamples: heartRateSamples
        )
        return record
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutService: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch toState {
            case .ended:
                self.stopTimer()
                let record = self.buildClimbRecord()
                self.isSessionActive = false
                self.onSessionEnded?(record)
                
                self.workoutBuilder?.endCollection(withEnd: date) { [weak self] success, _ in
                    self?.workoutBuilder?.finishWorkout { _, _ in }
                }
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutService: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(heartRateType) else { return }
        
        let statistics = workoutBuilder.statistics(for: heartRateType)
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        
        guard let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentHeartRate = value
            let sample = HeartRateSample(timestamp: Date(), bpm: value)
            self.heartRateSamples.append(sample)
            self.onHeartRateUpdate?(value)
        }
    }
}

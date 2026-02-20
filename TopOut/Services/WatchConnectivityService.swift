import Foundation
import WatchConnectivity
import Combine
import SwiftData

/// P0: iPhone side of WatchConnectivity - receives real-time data from Watch
final class WatchConnectivityService: NSObject, ObservableObject {
    @Published var isReachable = false
    @Published var realtimeData: RealtimeData?
    @Published var isSessionActive = false
    @Published var pendingSessionData: ClimbSessionData?
    
    private var session: WCSession?
    private var modelContext: ModelContext?
    
    static let shared = WatchConnectivityService()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func handleMessage(_ message: [String: Any]) {
        guard let typeRaw = message[WatchMessageKey.messageType.rawValue] as? String,
              let type = WatchMessageType(rawValue: typeRaw) else { return }
        
        DispatchQueue.main.async { [weak self] in
            switch type {
            case .realtimeUpdate:
                if let data = RealtimeData.from(dictionary: message) {
                    self?.realtimeData = data
                }
                
            case .sessionStarted:
                self?.isSessionActive = true
                
            case .sessionEnded:
                self?.isSessionActive = false
                // Instead of auto-saving, store pending data for ClimbFinishView
                self?.pendingSessionData = ClimbSessionData.from(message: message)
                
            case .recordSync:
                // Background sync — save directly
                self?.saveRecord(from: message)
            }
        }
    }
    
    private func saveRecord(from message: [String: Any]) {
        guard let modelContext else { return }
        
        let recordId = (message["recordId"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
        let startTime = (message["startTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let endTime = (message["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let duration = message["duration"] as? TimeInterval ?? 0
        let avgHR = message["averageHeartRate"] as? Double ?? 0
        let maxHR = message["maxHeartRate"] as? Double ?? 0
        let minHR = message["minHeartRate"] as? Double ?? 0
        let calories = message["calories"] as? Double ?? 0
        
        var samples: [HeartRateSample] = []
        if let samplesString = message["heartRateSamples"] as? String,
           let data = samplesString.data(using: .utf8) {
            samples = (try? JSONDecoder().decode([HeartRateSample].self, from: data)) ?? []
        }
        
        let record = ClimbRecord(
            id: recordId,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            minHeartRate: minHR,
            calories: calories,
            heartRateSamples: samples
        )
        
        modelContext.insert(record)
        try? modelContext.save()
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleMessage(message)
        replyHandler(["status": "ok"])
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleMessage(userInfo)
    }
}

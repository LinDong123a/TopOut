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
    @Published var latestRouteLogs: [RouteLogData] = []
    
    private var session: WCSession?
    private var modelContext: ModelContext?
    /// Tracks last processed message timestamp per type to deduplicate sendMessage + transferUserInfo
    private var lastProcessedTimestamp: [String: TimeInterval] = [:]
    
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
    
    // MARK: - Send to Watch
    
    /// Send start-session command to Watch
    func sendStartSession() {
        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.phoneStartSession.rawValue,
            WatchMessageKey.timestamp.rawValue: Date().timeIntervalSince1970
        ]
        guard let session, session.isReachable else {
            session?.transferUserInfo(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { [weak self] _ in
            self?.session?.transferUserInfo(message)
        }
    }

    /// Send end-session command to Watch
    func sendEndSession() {
        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.phoneEndSession.rawValue,
            WatchMessageKey.timestamp.rawValue: Date().timeIntervalSince1970
        ]
        guard let session, session.isReachable else {
            session?.transferUserInfo(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { [weak self] _ in
            self?.session?.transferUserInfo(message)
        }
    }

    /// Send cheer notification to Watch
    func sendCheerNotification(fromUser: String) {
        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.cheerNotification.rawValue,
            WatchMessageKey.cheerFromUser.rawValue: fromUser,
            WatchMessageKey.timestamp.rawValue: Date().timeIntervalSince1970
        ]
        guard let session, session.isReachable else {
            // Use transferUserInfo for guaranteed delivery
            session?.transferUserInfo(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { [weak self] _ in
            // Fallback to transferUserInfo
            self?.session?.transferUserInfo(message)
        }
    }
    
    // MARK: - Handle incoming
    
    private func handleMessage(_ message: [String: Any]) {
        guard let typeRaw = message[WatchMessageKey.messageType.rawValue] as? String,
              let type = WatchMessageType(rawValue: typeRaw) else { return }

        // Deduplicate: sendReliable sends both sendMessage + transferUserInfo,
        // so we may receive the same message twice. Skip if same type+timestamp.
        if let ts = message[WatchMessageKey.timestamp.rawValue] as? TimeInterval {
            if lastProcessedTimestamp[typeRaw] == ts {
                return // Already processed this exact message
            }
            lastProcessedTimestamp[typeRaw] = ts
        }

        DispatchQueue.main.async { [weak self] in
            switch type {
            case .realtimeUpdate:
                if let data = RealtimeData.from(dictionary: message) {
                    self?.realtimeData = data
                }
                
            case .sessionStarted:
                self?.isSessionActive = true
                self?.latestRouteLogs = []
                
            case .sessionEnded:
                self?.isSessionActive = false
                self?.pendingSessionData = ClimbSessionData.from(message: message)
                
            case .recordSync:
                self?.saveRecord(from: message)
                
            case .routeLogged:
                // Single route logged on Watch
                if let climbType = message[WatchMessageKey.climbType.rawValue] as? String,
                   let difficulty = message[WatchMessageKey.difficulty.rawValue] as? String,
                   let status = message[WatchMessageKey.completionStatus.rawValue] as? String,
                   let starred = message[WatchMessageKey.isStarred.rawValue] as? Bool,
                   let ts = message[WatchMessageKey.timestamp.rawValue] as? TimeInterval {
                    let route = RouteLogData(
                        climbType: climbType,
                        difficulty: difficulty,
                        completionStatus: status,
                        isStarred: starred,
                        timestamp: Date(timeIntervalSince1970: ts)
                    )
                    self?.latestRouteLogs.append(route)
                }
                
            case .cheerNotification, .phoneEndSession, .phoneStartSession:
                break // iPhone doesn't handle these (they are iPhone → Watch messages)
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
            heartRateSamples: samples,
            climbType: message[WatchMessageKey.climbType.rawValue] as? String ?? "indoorBoulder",
            difficulty: message[WatchMessageKey.difficulty.rawValue] as? String,
            completionStatus: message[WatchMessageKey.completionStatus.rawValue] as? String ?? "completed",
            isStarred: message[WatchMessageKey.isStarred.rawValue] as? Bool ?? false,
            locationName: message[WatchMessageKey.locationName.rawValue] as? String,
            isOutdoor: message[WatchMessageKey.isOutdoor.rawValue] as? Bool ?? false
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
        if let error {
            print("[WatchConnectivity] Activation error: \(error)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchConnectivity] Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for multi-watch support
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
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleMessage(applicationContext)
    }
}

import Foundation
import WatchConnectivity
import Combine

/// P0: Watch → iPhone real-time communication via WatchConnectivity
final class PhoneConnectivityService: NSObject, ObservableObject {
    @Published var isReachable = false
    @Published var cheerNotification: String?
    
    private var session: WCSession?
    private var pendingMessages: [[String: Any]] = []
    
    static let shared = PhoneConnectivityService()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    /// Send real-time data to iPhone (best-effort, no queuing for realtime)
    func sendRealtimeData(_ data: RealtimeData) {
        guard let session, session.isReachable else {
            // Don't cache realtime - it's stale immediately
            return
        }
        
        session.sendMessage(data.dictionary, replyHandler: nil) { error in
            print("[PhoneConnectivity] Failed to send realtime data: \(error.localizedDescription)")
        }
    }
    
    /// Send session started notification
    func sendSessionStarted() {
        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.sessionStarted.rawValue,
            WatchMessageKey.timestamp.rawValue: Date().timeIntervalSince1970
        ]
        sendGuaranteed(message)
    }
    
    /// Send single route log to iPhone
    func sendRouteLogged(climbType: String, difficulty: String, status: String, starred: Bool) {
        let message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.routeLogged.rawValue,
            WatchMessageKey.climbType.rawValue: climbType,
            WatchMessageKey.difficulty.rawValue: difficulty,
            WatchMessageKey.completionStatus.rawValue: status,
            WatchMessageKey.isStarred.rawValue: starred,
            WatchMessageKey.timestamp.rawValue: Date().timeIntervalSince1970
        ]
        // Try realtime first, fallback to guaranteed
        guard let session, session.isReachable else {
            sendGuaranteed(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { [weak self] _ in
            self?.sendGuaranteed(message)
        }
    }
    
    /// Send session ended with full record including route logs
    func sendSessionEnded(record: ClimbRecord, routeLogs: [RouteLogData] = []) {
        var message: [String: Any] = [
            WatchMessageKey.messageType.rawValue: WatchMessageType.sessionEnded.rawValue,
            WatchMessageKey.timestamp.rawValue: Date().timeIntervalSince1970,
            "recordId": record.id.uuidString,
            "startTime": record.startTime.timeIntervalSince1970,
            "endTime": record.endTime?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            "duration": record.duration,
            "averageHeartRate": record.averageHeartRate,
            "maxHeartRate": record.maxHeartRate,
            "minHeartRate": record.minHeartRate,
            "calories": record.calories,
            // New fields
            WatchMessageKey.climbType.rawValue: record.climbType,
            WatchMessageKey.completionStatus.rawValue: record.completionStatus,
            WatchMessageKey.isStarred.rawValue: record.isStarred,
            WatchMessageKey.isOutdoor.rawValue: record.isOutdoor,
        ]
        
        // Optional fields
        if let difficulty = record.difficulty {
            message[WatchMessageKey.difficulty.rawValue] = difficulty
        }
        if let locationName = record.locationName {
            message[WatchMessageKey.locationName.rawValue] = locationName
        }
        
        // Encode heart rate samples
        if let data = try? JSONEncoder().encode(record.heartRateSamples),
           let samplesString = String(data: data, encoding: .utf8) {
            message["heartRateSamples"] = samplesString
        }
        
        // Encode route logs
        if !routeLogs.isEmpty,
           let data = try? JSONEncoder().encode(routeLogs),
           let routesString = String(data: data, encoding: .utf8) {
            message[WatchMessageKey.routeLogs.rawValue] = routesString
        }
        
        sendGuaranteed(message)
    }
    
    /// Guaranteed delivery via transferUserInfo
    private func sendGuaranteed(_ message: [String: Any]) {
        guard let session else { return }
        session.transferUserInfo(message)
    }
    
    /// Cache messages for retry when connection restores
    private func cacheMessage(_ message: [String: Any]) {
        pendingMessages.append(message)
        if pendingMessages.count > 100 {
            pendingMessages.removeFirst()
        }
    }
    
    /// Flush cached messages when connection restores
    private func flushPendingMessages() {
        guard let session, session.isReachable, !pendingMessages.isEmpty else { return }
        let messages = pendingMessages
        pendingMessages.removeAll()
        
        for message in messages {
            session.sendMessage(message, replyHandler: nil) { [weak self] _ in
                self?.cacheMessage(message)
            }
        }
    }
    
    // MARK: - Handle incoming messages from iPhone
    
    private func handleMessage(_ message: [String: Any]) {
        guard let typeRaw = message[WatchMessageKey.messageType.rawValue] as? String,
              let type = WatchMessageType(rawValue: typeRaw) else { return }
        
        DispatchQueue.main.async { [weak self] in
            switch type {
            case .cheerNotification:
                if let user = message[WatchMessageKey.cheerFromUser.rawValue] as? String {
                    self?.cheerNotification = user
                }
            default:
                break
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
        if let error {
            print("[PhoneConnectivity] Activation error: \(error.localizedDescription)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            if session.isReachable {
                self?.flushPendingMessages()
            }
        }
    }
    
    // Receive messages from iPhone
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

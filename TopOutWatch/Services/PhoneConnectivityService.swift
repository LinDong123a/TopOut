import Foundation
import WatchConnectivity
import Combine

/// P0: Watch → iPhone real-time communication via WatchConnectivity
final class PhoneConnectivityService: NSObject, ObservableObject {
    @Published var isReachable = false
    
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
            // Cache for later if not reachable
            cacheMessage(data.dictionary)
            return
        }
        
        session.sendMessage(data.dictionary, replyHandler: nil) { error in
            print("Failed to send realtime data: \(error)")
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
    
    /// Send session ended with full record
    func sendSessionEnded(record: ClimbRecord) {
        guard let data = try? JSONEncoder().encode(record.heartRateSamples),
              let samplesString = String(data: data, encoding: .utf8) else { return }
        
        let message: [String: Any] = [
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
            "heartRateSamples": samplesString
        ]
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
        // Keep max 100 cached messages
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
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
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
}

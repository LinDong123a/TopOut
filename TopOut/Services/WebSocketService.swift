import Foundation
import Combine

/// WebSocket client for real-time climb data
final class WebSocketService: ObservableObject {
    @Published var isConnected = false
    @Published var gymLiveClimbers: [LiveClimber] = []
    
    private var climbSocket: URLSessionWebSocketTask?
    private var gymSocket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var subscribedGymId: String?
    
    static let shared = WebSocketService()
    
    // MARK: - Climb Data Upload (WS /ws/climb)
    
    func connectClimbSocket() {
        guard let url = URL(string: NetworkConfig.wsBaseURL + "/ws/climb") else { return }
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        climbSocket = session.webSocketTask(with: request)
        climbSocket?.resume()
        
        DispatchQueue.main.async { self.isConnected = true }
        receiveClimbMessages()
    }
    
    func disconnectClimbSocket() {
        climbSocket?.cancel(with: .normalClosure, reason: nil)
        climbSocket = nil
        DispatchQueue.main.async { self.isConnected = false }
    }
    
    /// Send climb start event
    func sendClimbStart(gymId: String, privacy: PrivacySettings) {
        let message: [String: Any] = [
            "type": "climb_start",
            "gym_id": gymId,
            "visible": privacy.isVisible,
            "anonymous": privacy.isAnonymous
        ]
        sendClimbMessage(message)
    }
    
    /// Send real-time heart rate
    func sendHeartRate(_ bpm: Double, state: ClimbState) {
        let message: [String: Any] = [
            "type": "heartrate",
            "bpm": bpm,
            "state": state.rawValue
        ]
        sendClimbMessage(message)
    }
    
    /// Send climb end event
    func sendClimbEnd() {
        sendClimbMessage(["type": "climb_end"])
    }
    
    private func sendClimbMessage(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }
        climbSocket?.send(.string(text)) { error in
            if let error { print("WS send error: \(error)") }
        }
    }
    
    private func receiveClimbMessages() {
        climbSocket?.receive { [weak self] result in
            switch result {
            case .success: break
            case .failure(let error):
                print("WS climb receive error: \(error)")
                DispatchQueue.main.async { self?.isConnected = false }
                return
            }
            self?.receiveClimbMessages()
        }
    }
    
    // MARK: - Gym Live Subscription (WS /ws/gym/{id})
    
    func subscribeToGym(_ gymId: String) {
        unsubscribeFromGym()
        subscribedGymId = gymId
        
        guard let url = URL(string: NetworkConfig.wsBaseURL + "/ws/gym/\(gymId)") else { return }
        gymSocket = session.webSocketTask(with: url)
        gymSocket?.resume()
        receiveGymMessages()
    }
    
    func unsubscribeFromGym() {
        gymSocket?.cancel(with: .normalClosure, reason: nil)
        gymSocket = nil
        subscribedGymId = nil
        DispatchQueue.main.async { self.gymLiveClimbers = [] }
    }
    
    private func receiveGymMessages() {
        gymSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleGymMessage(message)
            case .failure(let error):
                print("WS gym receive error: \(error)")
                return
            }
            self?.receiveGymMessages()
        }
    }
    
    private func handleGymMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .string(let text):
            guard let d = text.data(using: .utf8) else { return }
            data = d
        case .data(let d):
            data = d
        @unknown default:
            return
        }
        
        if let climbers = try? JSONDecoder().decode([LiveClimber].self, from: data) {
            DispatchQueue.main.async { self.gymLiveClimbers = climbers }
        }
    }
}

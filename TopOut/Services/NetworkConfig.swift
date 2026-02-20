import Foundation

/// Configurable backend API settings
enum NetworkConfig {
    /// Base URL for REST API - change this for different environments
    static var apiBaseURL: String {
        // Check UserDefaults first (for runtime config)
        if let custom = UserDefaults.standard.string(forKey: "apiBaseURL"), !custom.isEmpty {
            return custom
        }
        // Default to localhost for development
        #if DEBUG
        return "http://localhost:8000"
        #else
        return "https://api.topout.app"
        #endif
    }
    
    /// WebSocket base URL
    static var wsBaseURL: String {
        let base = apiBaseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        return base
    }
    
    static func setAPIBaseURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "apiBaseURL")
    }
}

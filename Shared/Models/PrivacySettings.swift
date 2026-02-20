import Foundation

struct PrivacySettings: Codable {
    var isVisible: Bool
    var isAnonymous: Bool
    
    static var `default`: PrivacySettings {
        PrivacySettings(isVisible: true, isAnonymous: false)
    }
    
    /// Load last used settings
    static func load() -> PrivacySettings {
        guard let data = UserDefaults.standard.data(forKey: "privacySettings"),
              let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    /// Save current settings
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "privacySettings")
        }
    }
}

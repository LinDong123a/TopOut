import Foundation

struct Gym: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let city: String
    let latitude: Double
    let longitude: Double
    var activeClimbers: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, latitude, longitude
        case activeClimbers = "active_climbers"
    }
}

struct LiveClimber: Codable, Identifiable {
    let id: String
    let nickname: String
    let isAnonymous: Bool
    let state: ClimbState
    let heartRate: Double
    let duration: TimeInterval
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, nickname, state, duration
        case isAnonymous = "is_anonymous"
        case heartRate = "heart_rate"
        case avatarURL = "avatar_url"
    }
    
    var displayName: String {
        isAnonymous ? "攀岩者 #\(id.prefix(4).uppercased())" : nickname
    }
}

struct GymLiveData: Codable {
    let gym: Gym
    let climbers: [LiveClimber]
}

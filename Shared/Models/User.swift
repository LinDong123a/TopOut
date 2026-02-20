import Foundation

struct User: Codable, Identifiable {
    let id: String
    var phone: String
    var nickname: String
    var avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case nickname
        case avatarURL = "avatar_url"
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct LoginRequest: Codable {
    let phone: String
    let code: String
}

struct RegisterRequest: Codable {
    let phone: String
    let code: String
    let nickname: String
}

import Foundation

/// REST API client for TopOut backend
actor APIService {
    static let shared = APIService()
    
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
    }
    
    private func setAuthToken(_ token: String?) {
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    // MARK: - Auth
    
    func login(phone: String, code: String) async throws -> AuthResponse {
        let body = LoginRequest(phone: phone, code: code)
        let response: AuthResponse = try await post("/api/auth/login", body: body)
        setAuthToken(response.token)
        return response
    }
    
    func register(phone: String, code: String, nickname: String) async throws -> AuthResponse {
        let body = RegisterRequest(phone: phone, code: code, nickname: nickname)
        let response: AuthResponse = try await post("/api/auth/register", body: body)
        setAuthToken(response.token)
        return response
    }
    
    func getCurrentUser() async throws -> User {
        try await get("/api/users/me")
    }
    
    func updateProfile(nickname: String) async throws -> User {
        let body = ["nickname": nickname]
        return try await put("/api/users/me", body: body)
    }
    
    func logout() {
        setAuthToken(nil)
    }
    
    var isLoggedIn: Bool {
        authToken != nil
    }
    
    // MARK: - Gyms
    
    func getActiveGyms() async throws -> [Gym] {
        try await get("/api/gyms/active")
    }
    
    func getGymLiveData(gymId: String) async throws -> GymLiveData {
        try await get("/api/gyms/\(gymId)/live")
    }
    
    func getNearbyGyms(latitude: Double, longitude: Double) async throws -> [Gym] {
        try await get("/api/gyms/nearby?lat=\(latitude)&lng=\(longitude)")
    }
    
    // MARK: - HTTP Helpers
    
    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: NetworkConfig.apiBaseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuth(&request)
        return try await execute(request)
    }
    
    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = URL(string: NetworkConfig.apiBaseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        addAuth(&request)
        return try await execute(request)
    }
    
    private func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = URL(string: NetworkConfig.apiBaseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        addAuth(&request)
        return try await execute(request)
    }
    
    private func addAuth(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的服务器响应"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        }
    }
}

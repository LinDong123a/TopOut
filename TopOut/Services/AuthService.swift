import Foundation
import Combine

/// Manages user authentication state
@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    
    static let shared = AuthService()
    
    init() {
        // Check if we have a stored token
        isLoggedIn = UserDefaults.standard.string(forKey: "authToken") != nil
        if isLoggedIn {
            Task { await loadCurrentUser() }
        }
    }
    
    func login(phone: String, code: String) async throws {
        let response = try await APIService.shared.login(phone: phone, code: code)
        currentUser = response.user
        isLoggedIn = true
    }
    
    func register(phone: String, code: String, nickname: String) async throws {
        let response = try await APIService.shared.register(phone: phone, code: code, nickname: nickname)
        currentUser = response.user
        isLoggedIn = true
    }
    
    func logout() async {
        await APIService.shared.logout()
        currentUser = nil
        isLoggedIn = false
    }
    
    private func loadCurrentUser() async {
        do {
            currentUser = try await APIService.shared.getCurrentUser()
        } catch {
            // Token might be expired
            print("Failed to load user: \(error)")
            await logout()
        }
    }
}

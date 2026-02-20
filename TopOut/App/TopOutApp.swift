import SwiftUI
import SwiftData

@main
struct TopOutApp: App {
    @StateObject private var connectivity = WatchConnectivityService.shared
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
                .environmentObject(authService)
        }
        .modelContainer(for: ClimbRecord.self)
    }
}

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
                .task {
                    // Set window background after scene is connected
                    let bgColor = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1)
                    for scene in UIApplication.shared.connectedScenes {
                        guard let windowScene = scene as? UIWindowScene else { continue }
                        for window in windowScene.windows {
                            window.backgroundColor = bgColor
                        }
                    }
                }
        }
        .modelContainer(for: ClimbRecord.self)
    }
}

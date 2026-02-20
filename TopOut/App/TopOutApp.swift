import SwiftUI
import SwiftData

@main
struct TopOutApp: App {
    @StateObject private var connectivity = WatchConnectivityService.shared
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Match window background to theme so safe area has no color gap
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.forEach { $0.backgroundColor = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1) }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
                .environmentObject(authService)
                .onAppear {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        scene.windows.forEach { $0.backgroundColor = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1) }
                    }
                }
        }
        .modelContainer(for: ClimbRecord.self)
    }
}

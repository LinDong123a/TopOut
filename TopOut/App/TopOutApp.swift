import SwiftUI
import SwiftData

@main
struct TopOutApp: App {
    @StateObject private var connectivity = WatchConnectivityService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
        }
        .modelContainer(for: ClimbRecord.self)
    }
}

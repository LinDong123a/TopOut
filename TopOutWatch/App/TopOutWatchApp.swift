import SwiftUI

@main
struct TopOutWatchApp: App {
    @StateObject private var sessionManager = ClimbSessionManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                switch sessionManager.appState {
                case .sceneSelection:
                    SceneSelectionView()
                        .environmentObject(sessionManager)
                case .ready:
                    ReadyView()
                        .environmentObject(sessionManager)
                case .climbing:
                    ClimbingContainerView()
                        .environmentObject(sessionManager)
                case .summary:
                    ClimbSummaryView()
                        .environmentObject(sessionManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: sessionManager.appState)
        }
    }
}

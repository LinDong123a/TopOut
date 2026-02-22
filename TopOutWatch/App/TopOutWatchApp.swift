import SwiftUI

@main
struct TopOutWatchApp: App {
    @StateObject private var sessionManager = ClimbSessionManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                switch sessionManager.appState {
                case .idle:
                    IdleStartView()
                        .environmentObject(sessionManager)
                case .waiting:
                    WaitingView()
                        .environmentObject(sessionManager)
                case .climbing:
                    ActiveSessionView()
                        .environmentObject(sessionManager)
                case .summary:
                    SessionSummaryView()
                        .environmentObject(sessionManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: sessionManager.appState)
        }
    }
}

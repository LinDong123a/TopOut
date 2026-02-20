import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showClimbFinish = false

    var body: some View {
        ZStack {
            // Fill entire window with theme color to eliminate black gaps
            Color(red: 0.08, green: 0.07, blue: 0.06)
                .ignoresSafeArea()
            
            if authService.isLoggedIn {
                mainTabView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                LoginView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authService.isLoggedIn)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onChange(of: connectivity.pendingSessionData != nil) { _, hasPending in
            if hasPending { showClimbFinish = true }
        }
        .fullScreenCover(isPresented: $showClimbFinish) {
            if let data = connectivity.pendingSessionData {
                ClimbFinishView(sessionData: data) {
                    connectivity.pendingSessionData = nil
                } onDiscarded: {
                    connectivity.pendingSessionData = nil
                }
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            LiveDashboardView()
                .tabItem {
                    Label("实时", systemImage: "waveform.path.ecg")
                }
                .tag(0)

            NavigationStack {
                MyClimbsView()
            }
            .tabItem {
                Label("我的攀爬", systemImage: "person.crop.rectangle.stack.fill")
            }
            .tag(1)

            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Label("发现", systemImage: "safari.fill")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(TopOutTheme.accentGreen)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(TopOutTheme.backgroundPrimary)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            connectivity.setModelContext(modelContext)
            MockDataService.insertIfEmpty(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityService.shared)
        .environmentObject(AuthService.shared)
        .modelContainer(for: ClimbRecord.self, inMemory: true)
}

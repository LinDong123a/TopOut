import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

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
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            LiveDashboardView()
                .tabItem {
                    Label("实时", systemImage: "waveform.path.ecg")
                }
                .tag(0)

            ActiveGymsView()
                .tabItem {
                    Label("围观", systemImage: "binoculars.fill")
                }
                .tag(1)

            NavigationStack {
                RecordsListView()
            }
            .tabItem {
                Label("记录", systemImage: "list.bullet.rectangle.portrait.fill")
            }
            .tag(2)

            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(4)
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
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityService.shared)
        .environmentObject(AuthService.shared)
        .modelContainer(for: ClimbRecord.self, inMemory: true)
}

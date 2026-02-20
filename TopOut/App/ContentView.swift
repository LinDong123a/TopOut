import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authService.isLoggedIn {
                mainTabView
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
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

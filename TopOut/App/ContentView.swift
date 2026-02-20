import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    
    var body: some View {
        mainTabView
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Live Dashboard
            LiveDashboardView()
                .tabItem {
                    Label("实时", systemImage: "waveform.path.ecg")
                }
                .tag(0)
            
            // Active Gyms (Remote Spectating)
            ActiveGymsView()
                .tabItem {
                    Label("围观", systemImage: "binoculars")
                }
                .tag(1)
            
            // Records
            NavigationStack {
                RecordsListView()
            }
            .tabItem {
                Label("记录", systemImage: "list.bullet")
            }
            .tag(2)
            
            // Statistics
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar")
            }
            .tag(3)
            
            // Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
            .tag(4)
        }
        .onAppear {
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

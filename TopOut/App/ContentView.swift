import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Live Dashboard
            LiveDashboardView()
                .tabItem {
                    Label("实时", systemImage: "waveform.path.ecg")
                }
                .tag(0)
            
            // Records
            NavigationStack {
                RecordsListView()
            }
            .tabItem {
                Label("记录", systemImage: "list.bullet")
            }
            .tag(1)
            
            // Statistics
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar")
            }
            .tag(2)
            
            // Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
            .tag(3)
        }
        .onAppear {
            connectivity.setModelContext(modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityService.shared)
        .modelContainer(for: ClimbRecord.self, inMemory: true)
}

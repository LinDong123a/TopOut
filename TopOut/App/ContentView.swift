import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthService
    @StateObject private var climbSession = ClimbSessionState()
    @State private var selectedTab = 0
    @State private var showClimbFinish = false
    @State private var showClimbSheet = false

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
        .environmentObject(climbSession)
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
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("首页", systemImage: "house.fill")
                    }
                    .tag(0)

                NavigationStack {
                    MyClimbsView()
                }
                .tabItem {
                    Label("我的攀爬", systemImage: "person.crop.rectangle.stack.fill")
                }
                .tag(1)

                // Placeholder for center button spacing
                Color.clear
                    .tabItem {
                        Label("", systemImage: "")
                    }
                    .tag(99)

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
            
            // Center climb button overlay
            climbButton
                .offset(y: -24)
        }
        .sheet(isPresented: $showClimbSheet) {
            NavigationStack {
                LiveDashboardView()
                    .environmentObject(climbSession)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showClimbSheet = false
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.headline)
                                    .foregroundStyle(TopOutTheme.textSecondary)
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
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
    
    // MARK: - Center Climb Button
    
    private var climbButton: some View {
        Button {
            if !climbSession.isClimbing {
                climbSession.startSession()
            }
            showClimbSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        climbSession.isClimbing
                            ? TopOutTheme.streakOrange
                            : TopOutTheme.accentGreen
                    )
                    .frame(width: 58, height: 58)
                    .shadow(
                        color: (climbSession.isClimbing ? TopOutTheme.streakOrange : TopOutTheme.accentGreen).opacity(0.4),
                        radius: 10, y: 2
                    )
                
                Image(systemName: climbSession.isClimbing ? "figure.climbing" : "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: climbSession.isClimbing)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityService.shared)
        .environmentObject(AuthService.shared)
        .modelContainer(for: ClimbRecord.self, inMemory: true)
}

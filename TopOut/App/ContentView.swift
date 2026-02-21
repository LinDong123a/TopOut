import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var connectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthService
    @StateObject private var climbSession = ClimbSessionState()
    @StateObject private var checkInStore = CheckInStore()
    @State private var selectedTab = 0
    @State private var showClimbFinish = false
    @State private var showClimbSheet = false
    @State private var showCheckInAlert = false
    @State private var showCheckInSuccess = false
    @State private var checkInGymName = ""

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
        .environmentObject(checkInStore)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authService.isLoggedIn)
        .overlay {
            if showCheckInAlert {
                CheckInAlertView(
                    gymName: checkInGymName,
                    onCheckIn: {
                        checkInStore.checkIn(gymName: checkInGymName)
                        showCheckInAlert = false
                        showCheckInSuccess = true
                    },
                    onDismiss: { showCheckInAlert = false }
                )
                .transition(.opacity)
            }
        }
        .overlay {
            if showCheckInSuccess {
                CheckInSuccessView(
                    gymName: checkInGymName,
                    streakDays: checkInStore.streakDays,
                    holiday: HolidayDetector.current,
                    isPresented: $showCheckInSuccess
                )
                .transition(.opacity)
            }
        }
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
        .task {
            await checkNearbyGymForCheckIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await checkNearbyGymForCheckIn() }
        }
    }
    
    // MARK: - Check-In Detection
    
    private func checkNearbyGymForCheckIn() async {
        let location = LocationService.shared
        guard location.authorizationStatus == .authorizedWhenInUse ||
              location.authorizationStatus == .authorizedAlways else { return }
        
        // Use mock nearby locations (same as GymSelectorView) to detect within 200m
        let nearbyLocations: [(name: String, distanceMeters: Int)] = [
            ("岩时攀岩馆（望京店）", 120),
            ("岩舞空间（三里屯）", 1800),
            ("奥攀攀岩馆", 3200),
            ("首攀攀岩（朝阳大悦城）", 4500),
            ("Rock Plus 攀岩馆", 5100),
            ("蜘蛛侠攀岩（国贸）", 6800),
        ]
        
        // Find first gym within 200m
        if let nearby = nearbyLocations.first(where: { $0.distanceMeters <= 200 }) {
            let gymName = nearby.name
            if checkInStore.shouldShowAlert(gymName: gymName) && !checkInStore.hasCheckedInToday(gymName: gymName) {
                await MainActor.run {
                    checkInGymName = gymName
                    withAnimation { showCheckInAlert = true }
                }
            }
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

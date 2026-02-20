import SwiftUI

struct ClimbingContainerView: View {
    @EnvironmentObject var session: ClimbSessionManager
    @State private var selectedPage = 1
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedPage) {
                LiveDataView()
                    .environmentObject(session)
                    .tag(0)
                
                RouteMarkView()
                    .environmentObject(session)
                    .tag(1)
                
                ControlView()
                    .environmentObject(session)
                    .tag(2)
            }
            .tabViewStyle(.page)
            
            // Notification overlay
            if session.showNotification {
                VStack {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundStyle(.yellow)
                        Text(session.notificationText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: session.showNotification)
                .onTapGesture { session.showNotification = false }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

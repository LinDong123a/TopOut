import SwiftUI

struct ReadyView: View {
    @EnvironmentObject var session: ClimbSessionManager
    
    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Scene indicator (tappable to switch)
                Button { session.goToSceneSelection() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: session.scene.icon)
                            .font(.system(size: 10))
                        Text(session.scene.displayName)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(warmGray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
                
                // Today stats
                if session.todayClimbCount > 0 {
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text("\(session.todayClimbCount)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(warmWhite)
                            Text("条线路")
                                .font(.system(size: 9))
                                .foregroundStyle(warmGray)
                        }
                        VStack(spacing: 1) {
                            Text(session.todayTotalDuration.formattedShortDuration)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(warmWhite)
                            Text("时长")
                                .font(.system(size: 9))
                                .foregroundStyle(warmGray)
                        }
                    }
                } else {
                    Text("今日尚未攀爬")
                        .font(.system(size: 12))
                        .foregroundStyle(warmGray)
                }
                
                Spacer().frame(height: 4)
                
                // Big start button
                Button { session.startClimbing() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 24))
                        Text("开始攀爬")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(width: 100, height: 100)
                    .background(forestGreen, in: Circle())
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await session.setup() }
    }
}

import SwiftUI

struct IdleStartView: View {
    @EnvironmentObject var session: ClimbSessionManager

    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let rockBrown = Color(red: 0.60, green: 0.45, blue: 0.30)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // Scene selection (indoor / outdoor)
                    HStack(spacing: 8) {
                        sceneButton(.indoor)
                        sceneButton(.outdoor)
                    }

                    // Climb type selection (based on scene)
                    HStack(spacing: 6) {
                        ForEach(session.scene.climbTypes, id: \.self) { type in
                            Button {
                                session.selectClimbType(type)
                            } label: {
                                Text(type.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        session.selectedClimbType == type
                                        ? forestGreen.opacity(0.8)
                                        : Color.white.opacity(0.08),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(session.selectedClimbType == type ? .white : warmGray)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Today stats
                    if session.todayClimbCount > 0 {
                        HStack(spacing: 12) {
                            VStack(spacing: 1) {
                                Text("\(session.todayClimbCount)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(warmWhite)
                                Text("条线路")
                                    .font(.system(size: 9))
                                    .foregroundStyle(warmGray)
                            }
                            VStack(spacing: 1) {
                                Text(session.todayTotalDuration.formattedShortDuration)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(warmWhite)
                                Text("时长")
                                    .font(.system(size: 9))
                                    .foregroundStyle(warmGray)
                            }
                        }
                    }

                    Spacer().frame(height: 2)

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
                .padding(.horizontal, 4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await session.setup() }
    }

    private func sceneButton(_ s: ClimbSessionManager.ClimbingScene) -> some View {
        Button {
            session.selectScene(s)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: s.icon)
                    .font(.system(size: 12))
                Text(s.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                session.scene == s
                ? (s == .indoor ? forestGreen : rockBrown)
                : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .foregroundStyle(session.scene == s ? .white : warmGray)
        }
        .buttonStyle(.plain)
    }
}

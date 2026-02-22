import SwiftUI

/// Between-climbs waiting screen: two buttons — start next climb or end session
struct WaitingView: View {
    @EnvironmentObject var session: ClimbSessionManager

    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // Last recorded route confirmation
                    if let lastLog = session.routeLogs.last {
                        HStack(spacing: 6) {
                            Text(lastLog.status.emoji)
                                .font(.system(size: 14))
                            Text(lastLog.difficulty)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(forestGreen)
                            Text("已记录")
                                .font(.system(size: 13))
                                .foregroundStyle(warmGray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06), in: Capsule())
                    }

                    // Session stats
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(session.routeLogs.count)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(warmWhite)
                            Text("条线路")
                                .font(.system(size: 10))
                                .foregroundStyle(warmGray)
                        }
                        VStack(spacing: 2) {
                            Text(session.elapsedTime.formattedDuration)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(warmWhite)
                            Text("运动时长")
                                .font(.system(size: 10))
                                .foregroundStyle(warmGray)
                        }
                    }

                    // Start next climb
                    Button {
                        session.startClimbing()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "figure.climbing")
                                .font(.system(size: 22))
                            Text("开始攀爬")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(forestGreen, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    // End session
                    Button {
                        session.endClimbing()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12))
                            Text("结束运动")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(heartRed.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(heartRed)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

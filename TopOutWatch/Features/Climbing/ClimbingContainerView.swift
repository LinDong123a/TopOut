import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var session: ClimbSessionManager
    @State private var selectedPage = 1

    var body: some View {
        ZStack {
            TabView(selection: $selectedPage) {
                SessionSettingsPage()
                    .environmentObject(session)
                    .tag(0)

                ActiveClimbPage()
                    .environmentObject(session)
                    .tag(1)
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
            // No heart rate prompt
            if session.showNoHRPrompt {
                VStack(spacing: 10) {
                    Spacer()

                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.20))

                        Text("未检测到心率")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(red: 0.94, green: 0.91, blue: 0.86))

                        Text("是否结束攀爬？")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.50, green: 0.46, blue: 0.40))

                        HStack(spacing: 12) {
                            Button {
                                session.endClimbing()
                            } label: {
                                Text("结束")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.85, green: 0.25, blue: 0.20), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)

                            Button {
                                session.dismissNoHRPrompt()
                            } label: {
                                Text("继续")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 8)

                    Spacer()
                }
                .background(Color.black.opacity(0.6))
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3), value: session.showNoHRPrompt)
        .navigationBarBackButtonHidden(true)
    }
}

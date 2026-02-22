import SwiftUI
import WatchKit

struct SessionSettingsPage: View {
    @EnvironmentObject var session: ClimbSessionManager
    @State private var showEndConfirm = false

    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let rockBrown = Color(red: 0.60, green: 0.45, blue: 0.30)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // Scene selection
                    HStack(spacing: 8) {
                        sceneButton(.indoor)
                        sceneButton(.outdoor)
                    }

                    // Climb type selection
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

                    // Session info
                    VStack(spacing: 4) {
                        Text(session.elapsedTime.formattedDuration)
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(warmWhite)
                        Text("\(session.routeLogs.count) 条线路")
                            .font(.system(size: 11))
                            .foregroundStyle(warmGray)
                    }
                    .padding(.vertical, 8)

                    // End session — simple text button
                    Button {
                        showEndConfirm = true
                    } label: {
                        Text("结束训练")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(heartRed)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(heartRed.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
        }
        .confirmationDialog("确定结束训练？", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("结束训练", role: .destructive) {
                session.endClimbing()
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - Scene Button

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

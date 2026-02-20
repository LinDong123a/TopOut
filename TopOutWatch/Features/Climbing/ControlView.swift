import SwiftUI
import WatchKit

struct ControlView: View {
    @EnvironmentObject var session: ClimbSessionManager
    @State private var endConfirmProgress: CGFloat = 0
    @State private var isLongPressing = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showEndConfirmed = false

    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private let amberYellow = Color(red: 0.90, green: 0.65, blue: 0.20)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 16) {
                // Pause/Resume
                Button { session.pauseResume() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 28))
                        Text(session.isPaused ? "继续" : "暂停")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(width: 80, height: 80)
                    .background(
                        session.isPaused ? forestGreen : amberYellow,
                        in: Circle()
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                // End session (long press)
                ZStack {
                    // Pulsing glow when pressing
                    if isLongPressing {
                        Circle()
                            .fill(heartRed.opacity(0.15))
                            .frame(width: 76, height: 76)
                            .scaleEffect(pulseScale)
                    }

                    // Background track
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 64, height: 64)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: endConfirmProgress)
                        .stroke(
                            heartRed,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))

                    // Inner content
                    VStack(spacing: 2) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16))
                        Text("长按结束")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(isLongPressing ? heartRed.opacity(0.5 + 0.5 * endConfirmProgress) : heartRed)
                }
                .scaleEffect(isLongPressing ? 0.93 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isLongPressing)
                .gesture(
                    LongPressGesture(minimumDuration: 1.5)
                        .onChanged { _ in
                            isLongPressing = true
                            withAnimation(.linear(duration: 1.5)) {
                                endConfirmProgress = 1.0
                            }
                            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                                pulseScale = 1.2
                            }
                        }
                        .onEnded { _ in
                            // Completion flash
                            showEndConfirmed = true
                            WKInterfaceDevice.current().play(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                session.endClimbing()
                                endConfirmProgress = 0
                                isLongPressing = false
                                pulseScale = 1.0
                                showEndConfirmed = false
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            if endConfirmProgress < 1.0 {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    endConfirmProgress = 0
                                }
                                isLongPressing = false
                                pulseScale = 1.0
                            }
                        }
                )
            }

            // Completion flash overlay
            if showEndConfirmed {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(forestGreen)
                    Text("已结束")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(warmWhite)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showEndConfirmed)
    }
}

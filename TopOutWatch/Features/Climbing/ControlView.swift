import SwiftUI

struct ControlView: View {
    @EnvironmentObject var session: ClimbSessionManager
    @State private var endConfirmProgress: CGFloat = 0
    @State private var isLongPressing = false
    
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
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 3)
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .trim(from: 0, to: endConfirmProgress)
                        .stroke(heartRed, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16))
                        Text("长按结束")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(heartRed)
                }
                .gesture(
                    LongPressGesture(minimumDuration: 1.5)
                        .onChanged { _ in
                            isLongPressing = true
                            withAnimation(.linear(duration: 1.5)) {
                                endConfirmProgress = 1.0
                            }
                        }
                        .onEnded { _ in
                            session.endClimbing()
                            endConfirmProgress = 0
                            isLongPressing = false
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
                            }
                        }
                )
            }
        }
    }
}

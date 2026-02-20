import SwiftUI

/// Watch climbing interface — big HR, clear status, compact layout
struct ClimbingView: View {
    @StateObject private var viewModel = ClimbingViewModel()
    @State private var buttonPressed = false

    // Earth-tone colors for watch (no theme import needed)
    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let rockBrown = Color(red: 0.60, green: 0.45, blue: 0.30)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private let amberYellow = Color(red: 0.90, green: 0.65, blue: 0.20)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 6) {
                if viewModel.isSessionActive {
                    activeView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    idleView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isSessionActive)
        }
        .task { await viewModel.setup() }
    }

    // MARK: - Active Session

    private var activeView: some View {
        VStack(spacing: 4) {
            // Status pill
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.climbState == .climbing
                          ? forestGreen : amberYellow)
                    .frame(width: 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.climbState)
                Text(viewModel.climbState.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(warmGray)
                    .contentTransition(.interpolate)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.climbState)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06), in: Capsule())

            // Heart rate — big and bold
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(heartRed)
                    .font(.system(size: 16))
                    .symbolEffect(.pulse, options: .repeating,
                                  isActive: viewModel.heartRate > 0)
                Text(viewModel.heartRate > 0
                     ? "\(Int(viewModel.heartRate))"
                     : "--")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.heartRate > 0
                                     ? heartRed : warmGray)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8),
                               value: Int(viewModel.heartRate))
            }

            // Timer
            Text(viewModel.elapsedTime.formattedDuration)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(warmWhite)
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.elapsedTime)

            Spacer().frame(height: 4)

            // Stop
            Button(action: { viewModel.stopSession() }) {
                Image(systemName: "stop.fill")
                    .font(.body)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(heartRed)
            .scaleEffect(buttonPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in buttonPressed = true }
                    .onEnded { _ in buttonPressed = false }
            )
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 10) {
            // Today stats
            VStack(spacing: 4) {
                Text("今日攀爬")
                    .font(.system(size: 11))
                    .foregroundStyle(warmGray)

                HStack(spacing: 14) {
                    VStack(spacing: 2) {
                        Text("\(viewModel.todayClimbCount)")
                            .font(.system(size: 22, weight: .bold,
                                          design: .rounded))
                            .foregroundStyle(warmWhite)
                            .contentTransition(.numericText())
                        Text("次")
                            .font(.system(size: 10))
                            .foregroundStyle(warmGray)
                    }
                    VStack(spacing: 2) {
                        Text(viewModel.todayTotalDuration
                                .formattedShortDuration)
                            .font(.system(size: 22, weight: .bold,
                                          design: .rounded))
                            .foregroundStyle(warmWhite)
                            .contentTransition(.numericText())
                        Text("时长")
                            .font(.system(size: 10))
                            .foregroundStyle(warmGray)
                    }
                }
            }

            Button(action: { viewModel.startSession() }) {
                Label("开始攀爬", systemImage: "figure.climbing")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(forestGreen)

            Text("自动检测已开启")
                .font(.system(size: 10))
                .foregroundStyle(warmGray.opacity(0.7))
        }
    }
}

#Preview {
    ClimbingView()
}

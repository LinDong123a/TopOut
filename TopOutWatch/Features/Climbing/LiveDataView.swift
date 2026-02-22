import SwiftUI

struct ActiveClimbPage: View {
    @EnvironmentObject var session: ClimbSessionManager
    @State private var showCompletionSheet = false

    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private let amberYellow = Color(red: 0.90, green: 0.65, blue: 0.20)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 4) {
                // Status pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(session.climbState == .climbing ? forestGreen : amberYellow)
                        .frame(width: 7, height: 7)
                    Text(session.climbState.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(warmGray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06), in: Capsule())

                // Heart rate
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(heartRed)
                        .font(.system(size: 14))
                        .symbolEffect(.pulse, options: .repeating, isActive: session.heartRate > 0)
                    Text(session.heartRate > 0 ? "\(Int(session.heartRate))" : "--")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(session.heartRate > 0 ? heartRed : warmGray)
                        .contentTransition(.numericText())
                }

                // Timer
                Text(session.elapsedTime.formattedDuration)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(warmWhite)
                    .contentTransition(.numericText(countsDown: false))

                // Route count
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(forestGreen)
                    Text("\(session.routeLogs.count) 条线路")
                        .font(.system(size: 11))
                        .foregroundStyle(warmGray)
                }

                Spacer().frame(height: 4)

                // Complete climb button
                Button {
                    showCompletionSheet = true
                } label: {
                    Text("完攀")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(forestGreen, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }

        }
        .sheet(isPresented: $showCompletionSheet) {
            CompletionFlowView { status, difficulty, starred in
                session.logRoute(
                    type: session.selectedClimbType,
                    difficulty: difficulty,
                    status: status,
                    starred: starred
                )
                // Transition to waiting state (between climbs)
                session.finishCurrentClimb()
            }
            .environmentObject(session)
        }
    }
}

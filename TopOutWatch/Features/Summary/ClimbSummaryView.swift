import SwiftUI

/// Session summary shown after ending a workout
struct SessionSummaryView: View {
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
                    // Title
                    Text("运动总结")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(warmWhite)

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 10) {
                        summaryItem(
                            icon: "clock",
                            value: session.summaryDuration.formattedDuration,
                            label: "时长"
                        )
                        summaryItem(
                            icon: "flag.fill",
                            value: "\(session.summaryRouteCount)",
                            label: "线路"
                        )
                        summaryItem(
                            icon: "heart.fill",
                            value: session.summaryAvgHR > 0 ? "\(Int(session.summaryAvgHR))" : "--",
                            label: "平均心率"
                        )
                        summaryItem(
                            icon: "heart.fill",
                            value: session.summaryMaxHR > 0 ? "\(Int(session.summaryMaxHR))" : "--",
                            label: "最大心率"
                        )
                    }

                    Spacer().frame(height: 8)

                    // Finish button
                    Button {
                        session.finishSummary()
                    } label: {
                        Text("完成")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(forestGreen, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func summaryItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(icon == "heart.fill" ? heartRed : forestGreen)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(warmWhite)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}

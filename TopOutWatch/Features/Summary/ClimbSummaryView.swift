import SwiftUI

struct ClimbSummaryView: View {
    @EnvironmentObject var session: ClimbSessionManager
    
    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 10) {
                    Text("攀爬结束 🎉")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(warmWhite)
                    
                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        statCard("时长", session.summaryDuration.formattedShortDuration, "clock")
                        statCard("线路", "\(session.summaryRouteCount)", "flag.fill")
                        statCard("平均心率", session.summaryAvgHR > 0 ? "\(Int(session.summaryAvgHR))" : "--", "heart.fill")
                        statCard("最高心率", session.summaryMaxHR > 0 ? "\(Int(session.summaryMaxHR))" : "--", "heart.fill")
                    }
                    
                    // Sync status
                    HStack(spacing: 4) {
                        if session.syncedToPhone {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundStyle(forestGreen)
                            Text("已同步到 iPhone")
                                .foregroundStyle(forestGreen)
                        } else {
                            ProgressView()
                                .tint(warmGray)
                            Text("正在同步...")
                                .foregroundStyle(warmGray)
                        }
                    }
                    .font(.system(size: 11))
                    
                    Button { session.finishSummary() } label: {
                        Text("完成")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(forestGreen)
                }
                .padding(.horizontal, 4)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func statCard(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(icon == "heart.fill" ? heartRed : forestGreen)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(warmWhite)
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}

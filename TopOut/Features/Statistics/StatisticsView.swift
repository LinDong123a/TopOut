import SwiftUI
import SwiftData
import Charts

/// Statistics — summary cards, HR trend, GitHub-style heatmap
struct StatisticsView: View {
    @Query(sort: \ClimbRecord.startTime, order: .reverse)
    private var allRecords: [ClimbRecord]
    @State private var selectedPeriod: StatsPeriod = .week

    enum StatsPeriod: String, CaseIterable {
        case week = "本周", month = "本月", all = "全部"
    }

    private var filtered: [ClimbRecord] {
        let now = Date()
        switch selectedPeriod {
        case .week:  return allRecords.filter { $0.startTime >= now.startOfWeek }
        case .month: return allRecords.filter { $0.startTime >= now.startOfMonth }
        case .all:   return allRecords
        }
    }

    private var totalClimbs: Int { filtered.count }
    private var totalDuration: TimeInterval {
        filtered.reduce(0) { $0 + $1.duration }
    }
    private var avgDuration: TimeInterval {
        totalClimbs > 0 ? totalDuration / Double(totalClimbs) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                summaryCards

                if filtered.isEmpty {
                    statsEmptyState
                } else {
                    heartRateTrendChart
                }

                calendarHeatmap
            }
            .padding(16)
        }
        .topOutBackground()
        .navigationTitle("统计")
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SCard(title: "攀爬次数", value: "\(totalClimbs)",
                  icon: "figure.climbing",
                  color: TopOutTheme.accentGreen)
            SCard(title: "总时长",
                  value: totalDuration.formattedShortDuration,
                  icon: "clock.fill",
                  color: TopOutTheme.rockBrown)
            SCard(title: "平均时长",
                  value: avgDuration.formattedShortDuration,
                  icon: "timer",
                  color: TopOutTheme.sageGreen)
        }
    }

    // MARK: - Empty

    private var statsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.4))
            Text("该时段暂无数据")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .topOutCard()
    }

    // MARK: - HR Trend

    private var heartRateTrendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("心率趋势")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)

            Chart {
                ForEach(filtered, id: \.id) { r in
                    PointMark(
                        x: .value("Date", r.startTime),
                        y: .value("Avg", r.averageHeartRate)
                    )
                    .foregroundStyle(TopOutTheme.heartRed)
                    .symbolSize(40)

                    PointMark(
                        x: .value("Date", r.startTime),
                        y: .value("Max", r.maxHeartRate)
                    )
                    .foregroundStyle(TopOutTheme.warningAmber)
                    .symbolSize(40)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [4]))
                        .foregroundStyle(TopOutTheme.textTertiary.opacity(0.25))
                    AxisValueLabel()
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [4]))
                        .foregroundStyle(TopOutTheme.textTertiary.opacity(0.25))
                    AxisValueLabel()
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }

            HStack(spacing: 16) {
                Label("平均心率", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.heartRed)
                Label("最高心率", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.warningAmber)
            }
        }
        .topOutCard()
    }

    // MARK: - Calendar Heatmap

    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("攀爬日历")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)

            let dailyCounts = Dictionary(
                grouping: allRecords,
                by: { Calendar.current.startOfDay(for: $0.startTime) }
            ).mapValues(\.count)

            let weeks = generateWeeks()

            // Weekday labels + grid
            HStack(alignment: .top, spacing: 3) {
                // Weekday labels
                VStack(spacing: 2) {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"],
                            id: \.self) { d in
                        Text(d)
                            .font(.system(size: 9))
                            .foregroundStyle(TopOutTheme.textTertiary)
                            .frame(width: 14, height: 14)
                    }
                }

                // Grid of weeks
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(14), spacing: 2),
                                      count: 7), spacing: 2) {
                    ForEach(weeks, id: \.self) { day in
                        let count = dailyCounts[
                            Calendar.current.startOfDay(for: day)] ?? 0
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heatColor(count))
                            .frame(width: 14, height: 14)
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("少").font(.caption2)
                    .foregroundStyle(TopOutTheme.textTertiary)
                ForEach(0..<5, id: \.self) { lvl in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(lvl))
                        .frame(width: 12, height: 12)
                }
                Text("多").font(.caption2)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .topOutCard()
    }

    private func generateWeeks() -> [Date] {
        let cal = Calendar.current
        let today = Date()
        return (0..<91).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private func heatColor(_ count: Int) -> Color {
        switch count {
        case 0:   return TopOutTheme.textTertiary.opacity(0.12)
        case 1:   return TopOutTheme.accentGreen.opacity(0.30)
        case 2:   return TopOutTheme.accentGreen.opacity(0.50)
        case 3:   return TopOutTheme.accentGreen.opacity(0.72)
        default:  return TopOutTheme.accentGreen.opacity(0.92)
        }
    }
}

// MARK: - Stat Card

private struct SCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .topOutCard()
    }
}

#Preview {
    NavigationStack { StatisticsView() }
        .modelContainer(for: ClimbRecord.self, inMemory: true)
}

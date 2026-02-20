import SwiftUI
import Charts

/// Climb detail — heart rate chart + metric cards + intervals
struct RecordDetailView: View {
    let record: ClimbRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                metricCards
                if !record.heartRateSamples.isEmpty {
                    heartRateChartSection
                }
                if !record.climbIntervals.isEmpty {
                    intervalsSection
                }
            }
            .padding(16)
        }
        .topOutBackground()
        .navigationTitle("攀爬详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startTime.fullDateTimeString)
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                if record.calories > 0 {
                    Label("\(Int(record.calories)) 千卡",
                          systemImage: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(TopOutTheme.streakOrange)
                }
            }
            Spacer()
        }
    }

    // MARK: - Metric Cards

    private var metricCards: some View {
        HStack(spacing: 12) {
            MetricCard(title: "时长",
                       value: record.duration.formattedShortDuration,
                       icon: "clock.fill",
                       color: TopOutTheme.rockBrown)
            MetricCard(title: "平均心率",
                       value: "\(Int(record.averageHeartRate))",
                       icon: "heart.fill",
                       color: TopOutTheme.heartRed)
            MetricCard(title: "最高心率",
                       value: "\(Int(record.maxHeartRate))",
                       icon: "heart.fill",
                       color: TopOutTheme.warningAmber)
        }
    }

    // MARK: - Heart Rate Chart

    private var heartRateChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("心率曲线")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)

            Chart {
                ForEach(Array(record.heartRateSamples.enumerated()),
                        id: \.offset) { _, s in
                    LineMark(x: .value("Time", s.timestamp),
                             y: .value("BPM", s.bpm))
                        .foregroundStyle(TopOutTheme.heartRed)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                    AreaMark(x: .value("Time", s.timestamp),
                             y: .value("BPM", s.bpm))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [
                                    TopOutTheme.heartRed.opacity(0.2),
                                    TopOutTheme.heartRed.opacity(0.0)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                }

                RuleMark(y: .value("Avg", record.averageHeartRate))
                    .foregroundStyle(TopOutTheme.heartRed.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg \(Int(record.averageHeartRate))")
                            .font(.caption2)
                            .foregroundStyle(TopOutTheme.textSecondary)
                    }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [4]))
                        .foregroundStyle(TopOutTheme.textTertiary.opacity(0.25))
                    AxisValueLabel(format: .dateTime.hour().minute())
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
        }
        .topOutCard()
    }

    // MARK: - Intervals

    private var intervalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("攀爬区间")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)

            ForEach(Array(record.climbIntervals.enumerated()),
                    id: \.offset) { _, interval in
                HStack(spacing: 10) {
                    Circle()
                        .fill(interval.isClimbing
                              ? TopOutTheme.accentGreen
                              : TopOutTheme.warningAmber)
                        .frame(width: 8, height: 8)
                    Text(interval.isClimbing ? "攀爬" : "休息")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    Text("\(interval.startTime.timeString) – \(interval.endTime.timeString)")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                    Text(interval.endTime
                            .timeIntervalSince(interval.startTime)
                            .formattedShortDuration)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
            }
        }
        .topOutCard()
    }

    private var shareText: String {
        """
        🧗 TopOut 攀爬记录
        📅 \(record.startTime.fullDateTimeString)
        ⏱️ \(record.duration.formattedShortDuration)
        ❤️ avg \(Int(record.averageHeartRate)) / max \(Int(record.maxHeartRate)) BPM
        """
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
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

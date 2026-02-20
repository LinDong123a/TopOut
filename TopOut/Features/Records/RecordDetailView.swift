import SwiftUI
import Charts

/// P1: Detailed view of a single climb record with heart rate chart
struct RecordDetailView: View {
    let record: ClimbRecord
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                summarySection
                
                // Heart rate chart
                if !record.heartRateSamples.isEmpty {
                    heartRateChartSection
                }
                
                // Climb intervals
                if !record.climbIntervals.isEmpty {
                    intervalsSection
                }
            }
            .padding()
        }
        .navigationTitle("攀爬详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    // MARK: - Summary
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(record.startTime.fullDateTimeString)
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryCard(title: "时长", value: record.duration.formattedShortDuration, icon: "clock", color: .blue)
                SummaryCard(title: "平均心率", value: "\(Int(record.averageHeartRate))", icon: "heart.fill", color: .red)
                SummaryCard(title: "最高心率", value: "\(Int(record.maxHeartRate))", icon: "heart.fill", color: .orange)
            }
            
            if record.calories > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(Int(record.calories)) 千卡")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Heart Rate Chart
    
    private var heartRateChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("心率曲线")
                .font(.headline)
            
            Chart {
                ForEach(Array(record.heartRateSamples.enumerated()), id: \.offset) { _, sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("BPM", sample.bpm)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("BPM", sample.bpm)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.red.opacity(0.0), .red.opacity(0.15)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
                
                // Average line
                RuleMark(y: .value("Avg", record.averageHeartRate))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg \(Int(record.averageHeartRate))")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.7))
                    }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Intervals
    
    private var intervalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("攀爬区间")
                .font(.headline)
            
            ForEach(Array(record.climbIntervals.enumerated()), id: \.offset) { _, interval in
                HStack {
                    Circle()
                        .fill(interval.isClimbing ? .green : .yellow)
                        .frame(width: 8, height: 8)
                    Text(interval.isClimbing ? "攀爬" : "休息")
                        .font(.subheadline)
                    Spacer()
                    Text("\(interval.startTime.timeString) - \(interval.endTime.timeString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(interval.endTime.timeIntervalSince(interval.startTime).formattedShortDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var shareText: String {
        "🧗 TopOut 攀爬记录\n📅 \(record.startTime.fullDateTimeString)\n⏱️ 时长: \(record.duration.formattedShortDuration)\n❤️ 平均心率: \(Int(record.averageHeartRate)) BPM\n🔥 最高心率: \(Int(record.maxHeartRate)) BPM"
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

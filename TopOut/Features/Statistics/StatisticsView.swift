import SwiftUI
import SwiftData
import Charts

/// P2: Statistics page with weekly/monthly/all-time views and calendar heatmap
struct StatisticsView: View {
    @Query(sort: \ClimbRecord.startTime, order: .reverse) private var allRecords: [ClimbRecord]
    @State private var selectedPeriod: StatsPeriod = .week
    
    enum StatsPeriod: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case all = "全部"
    }
    
    private var filteredRecords: [ClimbRecord] {
        let now = Date()
        switch selectedPeriod {
        case .week:
            return allRecords.filter { $0.startTime >= now.startOfWeek }
        case .month:
            return allRecords.filter { $0.startTime >= now.startOfMonth }
        case .all:
            return allRecords
        }
    }
    
    private var totalClimbs: Int { filteredRecords.count }
    private var totalDuration: TimeInterval { filteredRecords.reduce(0) { $0 + $1.duration } }
    private var avgDuration: TimeInterval { totalClimbs > 0 ? totalDuration / Double(totalClimbs) : 0 }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Summary stats
                summaryCards
                
                // Heart rate trend
                if !filteredRecords.isEmpty {
                    heartRateTrendChart
                }
                
                // Calendar heatmap
                calendarHeatmap
            }
            .padding()
        }
        .navigationTitle("统计")
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "攀爬次数", value: "\(totalClimbs)", icon: "figure.climbing", color: .green)
            StatCard(title: "总时长", value: totalDuration.formattedShortDuration, icon: "clock", color: .blue)
            StatCard(title: "平均时长", value: avgDuration.formattedShortDuration, icon: "timer", color: .purple)
        }
    }
    
    // MARK: - Heart Rate Trend
    
    private var heartRateTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("心率趋势")
                .font(.headline)
            
            Chart {
                ForEach(filteredRecords, id: \.id) { record in
                    PointMark(
                        x: .value("Date", record.startTime),
                        y: .value("Avg HR", record.averageHeartRate)
                    )
                    .foregroundStyle(.red)
                    
                    PointMark(
                        x: .value("Date", record.startTime),
                        y: .value("Max HR", record.maxHeartRate)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 200)
            
            HStack(spacing: 16) {
                Label("平均心率", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Label("最高心率", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Calendar Heatmap
    
    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("攀爬日历")
                .font(.headline)
            
            let dailyCounts = Dictionary(
                grouping: allRecords,
                by: { Calendar.current.startOfDay(for: $0.startTime) }
            ).mapValues(\.count)
            
            let weeks = generateWeeks()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(weeks, id: \.self) { day in
                    let count = dailyCounts[Calendar.current.startOfDay(for: day)] ?? 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(count: count))
                        .frame(height: 14)
                        .help(day.shortDateString + " - \(count)次")
                }
            }
            
            // Legend
            HStack(spacing: 4) {
                Text("少")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(count: level))
                        .frame(width: 12, height: 12)
                }
                Text("多")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateWeeks() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var days: [Date] = []
        for i in (0..<91).reversed() {
            if let day = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(day)
            }
        }
        return days
    }
    
    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green.opacity(0.9)
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
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
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
    .modelContainer(for: ClimbRecord.self, inMemory: true)
}

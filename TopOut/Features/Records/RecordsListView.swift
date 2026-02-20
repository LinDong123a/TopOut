import SwiftUI
import SwiftData

/// Climb records — card-based list grouped by date
struct RecordsListView: View {
    @Query(sort: \ClimbRecord.startTime, order: .reverse)
    private var records: [ClimbRecord]

    private var groupedRecords: [(String, [ClimbRecord])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年MM月dd日"
        let grouped = Dictionary(grouping: records) { fmt.string(from: $0.startTime) }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            if records.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(groupedRecords, id: \.0) { date, dayRecords in
                        Section {
                            ForEach(dayRecords, id: \.id) { record in
                                NavigationLink(destination: RecordDetailView(record: record)) {
                                    RecordCard(record: record)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Text(date)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TopOutTheme.textSecondary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .topOutBackground()
        .navigationTitle("攀爬记录")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "figure.climbing")
                .font(.system(size: 52))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.4))
            Text("暂无攀爬记录")
                .font(.title3.weight(.semibold))
                .foregroundStyle(TopOutTheme.textSecondary)
            Text("戴上 Apple Watch 去攀爬吧！")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Record Card

private struct RecordCard: View {
    let record: ClimbRecord

    var body: some View {
        HStack(spacing: 14) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(TopOutTheme.accentGreen)
                .frame(width: 4, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.startTime.timeString)
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                Text(record.duration.formattedShortDuration)
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 18) {
                VStack(alignment: .trailing, spacing: 2) {
                    Label("avg \(Int(record.averageHeartRate))",
                          systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.heartRed.opacity(0.8))
                    Label("max \(Int(record.maxHeartRate))",
                          systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.warningAmber.opacity(0.8))
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .topOutCard()
    }
}

#Preview {
    NavigationStack {
        RecordsListView()
    }
    .modelContainer(for: ClimbRecord.self, inMemory: true)
}

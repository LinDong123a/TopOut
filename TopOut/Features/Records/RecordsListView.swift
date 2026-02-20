import SwiftUI
import SwiftData

/// P1: Climb records list grouped by date
struct RecordsListView: View {
    @Query(sort: \ClimbRecord.startTime, order: .reverse) private var records: [ClimbRecord]
    
    private var groupedRecords: [(String, [ClimbRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        
        let grouped = Dictionary(grouping: records) { record in
            formatter.string(from: record.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    "暂无攀爬记录",
                    systemImage: "figure.climbing",
                    description: Text("戴上 Apple Watch 去攀爬吧！")
                )
            } else {
                ForEach(groupedRecords, id: \.0) { date, dayRecords in
                    Section(header: Text(date)) {
                        ForEach(dayRecords, id: \.id) { record in
                            NavigationLink(destination: RecordDetailView(record: record)) {
                                RecordRowView(record: record)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("攀爬记录")
    }
}

// MARK: - Record Row

struct RecordRowView: View {
    let record: ClimbRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startTime.timeString)
                    .font(.headline)
                Text(record.duration.formattedShortDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                VStack(alignment: .trailing) {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text("avg \(Int(record.averageHeartRate))")
                            .font(.caption)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("max \(Int(record.maxHeartRate))")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RecordsListView()
    }
    .modelContainer(for: ClimbRecord.self, inMemory: true)
}

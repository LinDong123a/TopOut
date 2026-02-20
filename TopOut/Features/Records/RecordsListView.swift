import SwiftUI
import SwiftData

/// Climb records — card-based list grouped by date with swipe-to-delete
struct RecordsListView: View {
    @Query(sort: \ClimbRecord.startTime, order: .reverse)
    private var records: [ClimbRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false
    @State private var recordToDelete: ClimbRecord?

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
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(Array(groupedRecords.enumerated()), id: \.element.0) { groupIndex, group in
                        let (date, dayRecords) = group
                        Section {
                            ForEach(Array(dayRecords.enumerated()), id: \.element.id) { itemIndex, record in
                                let totalIndex = groupIndex * 3 + itemIndex
                                NavigationLink(destination: RecordDetailView(record: record)) {
                                    RecordCard(record: record)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        recordToDelete = record
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(min(totalIndex, 10)) * 0.06),
                                    value: appeared
                                )
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: records.isEmpty)
        .topOutBackground()
        .navigationTitle("攀爬记录")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: StatisticsView()) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .alert("删除这条记录？", isPresented: .init(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        )) {
            Button("删除", role: .destructive) {
                if let record = recordToDelete {
                    for path in record.videoURLs { VideoStorageService.deleteVideo(at: path) }
                    modelContext.delete(record)
                    try? modelContext.save()
                }
                recordToDelete = nil
            }
            Button("取消", role: .cancel) { recordToDelete = nil }
        } message: {
            Text("删除后无法恢复")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "figure.climbing")
                .font(.system(size: 52))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.4))
                .scaleEffect(appeared ? 1 : 0.6)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)
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
    @State private var pressed = false

    var body: some View {
        HStack(spacing: 14) {
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
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

#Preview {
    NavigationStack {
        RecordsListView()
    }
    .modelContainer(for: ClimbRecord.self, inMemory: true)
}

import SwiftUI

struct StickerWallView: View {
    @EnvironmentObject var checkInStore: CheckInStore
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats header
                statsHeader
                
                if checkInStore.records.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(checkInStore.records) { record in
                            stickerCell(record)
                        }
                    }
                }
            }
            .padding(16)
        }
        .topOutBackground()
        .navigationTitle("🎨 我的贴纸")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var statsHeader: some View {
        HStack(spacing: 4) {
            Text("共打卡 \(checkInStore.records.count) 次")
            Text("·")
            Text("\(checkInStore.uniqueGymCount) 家岩馆")
            Text("·")
            Text("连续 \(checkInStore.streakDays) 天")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(TopOutTheme.textSecondary)
        .frame(maxWidth: .infinity)
        .topOutCard()
    }
    
    private func stickerCell(_ record: CheckInRecord) -> some View {
        VStack(spacing: 6) {
            ZStack {
                GymStickerView(
                    gymName: record.gymName,
                    date: record.date,
                    holiday: record.isHoliday
                        ? HolidayInfo(name: record.holidayName ?? "", emoji: "🔥", symbol: "star.fill")
                        : nil,
                    size: 90
                )
                
                // Holiday glow
                if record.isHoliday {
                    Circle()
                        .stroke(TopOutTheme.warningAmber.opacity(0.4), lineWidth: 2)
                        .frame(width: 96, height: 96)
                        .shadow(color: TopOutTheme.warningAmber.opacity(0.5), radius: 8)
                }
            }
            
            Text(record.gymName.prefix(6) + (record.gymName.count > 6 ? "…" : ""))
                .font(.caption2)
                .foregroundStyle(TopOutTheme.textSecondary)
                .lineLimit(1)
            
            Text(record.date.formatted(.dateTime.month().day()))
                .font(.caption2)
                .foregroundStyle(TopOutTheme.textTertiary)
            
            if record.isHoliday {
                Text("🔥限定")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(TopOutTheme.warningAmber)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.square.on.square")
                .font(.system(size: 44))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.4))
            Text("还没有贴纸")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textSecondary)
            Text("到岩馆打卡获取你的第一张贴纸")
                .font(.caption)
                .foregroundStyle(TopOutTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    NavigationStack {
        StickerWallView()
            .environmentObject(CheckInStore())
    }
}

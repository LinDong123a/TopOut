import SwiftUI
import SwiftData

/// Personal climbing profile — works for self (userId=nil) or viewing others
struct MyClimbsView: View {
    let userId: String?
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var checkInStore: CheckInStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClimbRecord.startTime, order: .reverse)
    private var allRecords: [ClimbRecord]
    @State private var appeared = false
    @State private var isFollowing = false
    @State private var recordToDelete: ClimbRecord?
    @State private var likedRecords: Set<UUID> = []
    
    private var isSelf: Bool { userId == nil }
    
    init(userId: String? = nil) {
        self.userId = userId
    }
    
    // Mock profile for other users
    private var profileInfo: ProfileInfo {
        if isSelf {
            return ProfileInfo(
                nickname: authService.currentUser?.nickname ?? "攀岩者",
                avatarSymbol: "figure.climbing",
                grade: "V4 / 5.11a",
                climbingYears: 3
            )
        } else {
            return ProfileInfo(
                nickname: "小岩",
                avatarSymbol: "figure.climbing",
                grade: "V6 / 5.12a",
                climbingYears: 5
            )
        }
    }
    
    private var records: [ClimbRecord] {
        if isSelf {
            return allRecords
        } else {
            // Other users: only show public records
            return allRecords.filter { $0.isPublic }
        }
    }
    
    private var groupedRecords: [(String, [ClimbRecord])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年MM月dd日"
        let grouped = Dictionary(grouping: records) { fmt.string(from: $0.startTime) }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // Stats
    private var totalClimbs: Int { records.count }
    private var totalDuration: TimeInterval { records.reduce(0) { $0 + $1.duration } }
    private var thisMonthCount: Int {
        let cal = Calendar.current
        let now = Date()
        return records.filter { cal.isDate($0.startTime, equalTo: now, toGranularity: .month) }.count
    }
    private var maxDifficulty: String {
        let diffs = records.compactMap(\.difficulty)
        return diffs.first ?? "V4"
    }
    private var streakDays: Int {
        let cal = Calendar.current
        let dates = Set(records.map { cal.startOfDay(for: $0.startTime) }).sorted(by: >)
        guard let first = dates.first else { return 0 }
        var streak = 0
        var check = cal.startOfDay(for: Date())
        if first < cal.date(byAdding: .day, value: -1, to: check)! { return 0 }
        for date in dates {
            if date == check {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            } else if date < check {
                break
            }
        }
        return max(streak, 1)
    }

    // Today's check-in gym
    private var todayGymName: String? {
        let cal = Calendar.current
        return checkInStore.records.first { cal.isDateInToday($0.date) }?.gymName
    }

    // Mock social data
    private var followingCount: Int { isSelf ? 12 : 8 }
    private var followersCount: Int { isSelf ? 8 : 15 }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isSelf, let gym = todayGymName {
                    gymBanner(gym)
                }
                profileCard
                socialBar
                stickerWallEntry
                statsOverview
                recordsList
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .topOutBackground()
        .navigationTitle(isSelf ? "我的攀爬" : profileInfo.nickname)
        .navigationBarTitleDisplayMode(isSelf ? .large : .inline)
        .toolbar {
            if isSelf {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: ProfilePrivacySettingsView()) {
                            Image(systemName: "eye.slash")
                                .foregroundStyle(TopOutTheme.textSecondary)
                        }
                        NavigationLink(destination: StatisticsView()) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(TopOutTheme.accentGreen)
                        }
                    }
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
        .toolbar(isSelf ? .automatic : .hidden, for: .tabBar)
    }

    private func likedBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { likedRecords.contains(id) },
            set: { newVal in
                if newVal { likedRecords.insert(id) }
                else { likedRecords.remove(id) }
            }
        )
    }

    // MARK: - Gym Banner

    private func gymBanner(_ gymName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(TopOutTheme.accentGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("今日打卡")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
                Text(gymName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TopOutTheme.textPrimary)
            }

            Spacer()

            Text("🧗")
                .font(.title2)
        }
        .topOutCard()
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(TopOutTheme.accentGreen.opacity(0.3), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(TopOutTheme.accentGreen.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: profileInfo.avatarSymbol)
                    .font(.title)
                    .foregroundStyle(TopOutTheme.accentGreen)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(profileInfo.nickname)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TopOutTheme.textPrimary)
                
                HStack(spacing: 8) {
                    Text(profileInfo.grade)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TopOutTheme.accentGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
                    
                    Text("攀龄 \(profileInfo.climbingYears) 年")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }
            
            Spacer()
            
            if !isSelf {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isFollowing.toggle()
                    }
                } label: {
                    Text(isFollowing ? "已关注" : "关注")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isFollowing ? TopOutTheme.textTertiary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isFollowing
                                      ? TopOutTheme.textTertiary.opacity(0.15)
                                      : TopOutTheme.accentGreen)
                        )
                }
            }
        }
        .topOutCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Social Bar (Following / Followers)

    private var socialBar: some View {
        HStack(spacing: 0) {
            NavigationLink(destination: FollowingListView()) {
                VStack(spacing: 2) {
                    Text("\(followingCount)")
                        .font(.headline.bold())
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text("关注")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 28)
                .background(TopOutTheme.textTertiary.opacity(0.3))

            NavigationLink(destination: FollowersListView()) {
                VStack(spacing: 2) {
                    Text("\(followersCount)")
                        .font(.headline.bold())
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text("粉丝")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .topOutCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appeared)
    }
    
    // MARK: - Sticker Wall Entry
    
    private var stickerWallEntry: some View {
        NavigationLink(destination: StickerWallView()) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(TopOutTheme.warningAmber.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Text("🎨")
                        .font(.title2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("我的贴纸")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text("查看打卡贴纸墙")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
            .topOutCard()
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.08), value: appeared)
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 10) {
            StatMiniCard(value: "\(totalClimbs)", label: "总攀爬", icon: "figure.climbing", color: TopOutTheme.accentGreen)
            StatMiniCard(value: totalDuration.formattedShortDuration, label: "总时长", icon: "clock.fill", color: TopOutTheme.rockBrown)
            StatMiniCard(value: maxDifficulty, label: "最高难度", icon: "arrow.up.circle.fill", color: TopOutTheme.streakOrange)
            StatMiniCard(value: "\(streakDays)", label: "连续打卡", icon: "flame.fill", color: TopOutTheme.streakOrange)
            StatMiniCard(value: "\(thisMonthCount)", label: "本月攀爬", icon: "calendar", color: TopOutTheme.sageGreen)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }
    
    // MARK: - Records List
    
    private var recordsList: some View {
        VStack(spacing: 16) {
            HStack {
                Text("攀爬记录")
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("\(records.count) 条")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
            
            if records.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(groupedRecords.enumerated()), id: \.element.0) { groupIndex, group in
                        let (date, dayRecords) = group
                        Section {
                            ForEach(Array(dayRecords.enumerated()), id: \.element.id) { itemIndex, record in
                                let totalIndex = groupIndex * 3 + itemIndex
                                NavigationLink(destination: RecordDetailView(record: record)) {
                                    HStack {
                                        MyClimbsRecordCard(record: record)
                                        if !isSelf {
                                            CheerButton(
                                                isLiked: likedBinding(for: record.id),
                                                emoji: "❤️",
                                                likedColor: TopOutTheme.heartRed
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if isSelf {
                                        Button(role: .destructive) {
                                            recordToDelete = record
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(min(totalIndex, 10)) * 0.06 + 0.2),
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
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.climbing")
                .font(.system(size: 44))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.4))
            Text(isSelf ? "暂无攀爬记录" : "暂无公开记录")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Profile Info

private struct ProfileInfo {
    let nickname: String
    let avatarSymbol: String
    let grade: String
    let climbingYears: Int
}

// MARK: - Stat Mini Card

private struct StatMiniCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .topOutCard()
    }
}

// MARK: - Record Card (enhanced with new fields)

private struct MyClimbsRecordCard: View {
    let record: ClimbRecord

    private var climbTypeShort: String {
        switch record.climbType {
        case "indoorBoulder": return "抱石"
        case "indoorLead": return "先锋"
        case "indoorTopRope": return "顶绳"
        case "outdoorBoulder": return "户外抱石"
        case "outdoorLead": return "户外先锋"
        case "outdoorTrad": return "传统"
        case "outdoorBigWall": return "大岩壁"
        default: return record.climbType
        }
    }
    
    private var statusIcon: String {
        switch record.completionStatus {
        case "completed": return "✅"
        case "failed": return "❌"
        case "flash": return "⚡"
        case "onsight": return "👁️"
        default: return "✅"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 2)
                .fill(record.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                .frame(width: 4, height: 56)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.startTime.timeString)
                        .font(.headline)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    
                    Text(climbTypeShort)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(record.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (record.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen).opacity(0.12),
                            in: Capsule()
                        )
                    
                    if let diff = record.difficulty {
                        Text(diff)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TopOutTheme.textPrimary)
                    }
                    
                    Text(statusIcon)
                        .font(.caption)
                    
                    if record.isStarred {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }

                    if !record.videoURLs.isEmpty {
                        Image(systemName: "video.fill")
                            .font(.caption2)
                            .foregroundStyle(TopOutTheme.accentGreen.opacity(0.7))
                    }
                }
                
                HStack(spacing: 8) {
                    Text(record.duration.formattedShortDuration)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textSecondary)
                    
                    if let loc = record.locationName {
                        Text("· \(loc)")
                            .font(.caption)
                            .foregroundStyle(TopOutTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Label("avg \(Int(record.averageHeartRate))", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.heartRed.opacity(0.8))
                
                HStack(spacing: 1) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= record.feeling ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundStyle(i <= record.feeling ? .yellow : TopOutTheme.textTertiary.opacity(0.4))
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TopOutTheme.textTertiary)
        }
        .topOutCard()
    }
}

#Preview {
    NavigationStack {
        MyClimbsView()
    }
    .environmentObject(AuthService.shared)
    .modelContainer(for: ClimbRecord.self, inMemory: true)
}

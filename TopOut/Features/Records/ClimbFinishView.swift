import SwiftUI
import SwiftData
import PhotosUI
import AVKit

/// Full-screen confirmation page shown after a climb ends, before saving
struct ClimbFinishView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Raw data from the watch session
    let sessionData: ClimbSessionData
    var onSaved: (() -> Void)?
    var onDiscarded: (() -> Void)?

    // Editable fields
    @State private var climbType = "indoorBoulder"
    @State private var difficulty = ""
    @State private var completionStatus = "completed"
    @State private var feeling: Int = 3
    @State private var isStarred = false
    @State private var notes = ""
    @State private var isPublic = false
    @State private var videoPaths: [String] = []

    // Pickers
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showCamera = false
    @State private var showVideoSourceSheet = false
    @State private var showDiscardAlert = false

    private let climbTypes = [
        ("indoorBoulder", "室内抱石"),
        ("indoorLead", "室内先锋"),
        ("indoorTopRope", "室内顶绳"),
        ("outdoorBoulder", "户外抱石"),
        ("outdoorLead", "户外先锋"),
        ("outdoorTrad", "户外传统"),
        ("outdoorBigWall", "大岩壁"),
    ]

    private let completionStatuses = [
        ("completed", "完攀 ✅"),
        ("failed", "未完攀 ❌"),
        ("flash", "Flash ⚡"),
        ("onsight", "Onsight 👁️"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    climbTypeSection
                    difficultySection
                    completionSection
                    feelingSection
                    starSection
                    videoSection
                    notesSection
                    publicToggle
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .topOutBackground()
            .navigationTitle("攀爬完成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("放弃") { showDiscardAlert = true }
                        .foregroundStyle(TopOutTheme.heartRed)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomButtons
            }
            .alert("放弃这条记录？", isPresented: $showDiscardAlert) {
                Button("放弃", role: .destructive) {
                    // Clean up imported videos
                    for path in videoPaths { VideoStorageService.deleteVideo(at: path) }
                    onDiscarded?()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这条攀爬记录将不会被保存")
            }
            .sheet(isPresented: $showPhotoPicker) {
                VideoPhotoPickerView { url in
                    importVideo(from: url)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                VideoDocumentPickerView { url in
                    importVideo(from: url)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                VideoCameraView { url in
                    importVideo(from: url)
                }
            }
            .confirmationDialog("添加视频", isPresented: $showVideoSourceSheet) {
                Button("从相册选择") { showPhotoPicker = true }
                Button("从文件导入") { showDocumentPicker = true }
                Button("拍摄视频") { showCamera = true }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("🧗 攀爬总结")
                .font(.title3.weight(.bold))
                .foregroundStyle(TopOutTheme.textPrimary)

            HStack(spacing: 20) {
                SummaryItem(icon: "clock.fill", value: sessionData.duration.formattedShortDuration, label: "时长", color: TopOutTheme.rockBrown)
                SummaryItem(icon: "heart.fill", value: "\(Int(sessionData.averageHeartRate))", label: "平均心率", color: TopOutTheme.heartRed)
                SummaryItem(icon: "heart.fill", value: "\(Int(sessionData.maxHeartRate))", label: "最高心率", color: TopOutTheme.warningAmber)
            }
        }
        .topOutCard()
    }

    // MARK: - Climb Type

    private var climbTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("攀岩类型")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(climbTypes, id: \.0) { key, name in
                    Button {
                        climbType = key
                    } label: {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(climbType == key ? .white : TopOutTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(climbType == key ? TopOutTheme.accentGreen : TopOutTheme.backgroundCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(climbType == key ? TopOutTheme.accentGreen : TopOutTheme.cardStroke, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .topOutCard()
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("难度")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)
            TextField("例如 V4 / 5.11a", text: $difficulty)
                .foregroundStyle(TopOutTheme.textPrimary)
                .padding(12)
                .background(TopOutTheme.backgroundPrimary, in: RoundedRectangle(cornerRadius: 10))
        }
        .topOutCard()
    }

    // MARK: - Completion Status

    private var completionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("完攀状态")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(completionStatuses, id: \.0) { key, name in
                    Button {
                        completionStatus = key
                    } label: {
                        Text(name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(completionStatus == key ? .white : TopOutTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(completionStatus == key ? TopOutTheme.accentGreen : TopOutTheme.backgroundCard)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(completionStatus == key ? TopOutTheme.accentGreen : TopOutTheme.cardStroke, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .topOutCard()
    }

    // MARK: - Feeling

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("感受评分")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        feeling = i
                    } label: {
                        Image(systemName: i <= feeling ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(i <= feeling ? .yellow : TopOutTheme.textTertiary)
                    }
                }
                Spacer()
            }
        }
        .topOutCard()
    }

    // MARK: - Star

    private var starSection: some View {
        HStack {
            Text("好线标记")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)
            Spacer()
            Button {
                isStarred.toggle()
            } label: {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(isStarred ? .yellow : TopOutTheme.textTertiary)
            }
        }
        .topOutCard()
    }

    // MARK: - Video

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("攀爬视频")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Button { showVideoSourceSheet = true } label: {
                    Label("添加", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
            }

            if !videoPaths.isEmpty {
                VideoThumbnailGrid(videoPaths: videoPaths) { path in
                    VideoStorageService.deleteVideo(at: path)
                    videoPaths.removeAll { $0 == path }
                }
            }
        }
        .topOutCard()
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TopOutTheme.textPrimary)
            TextField("写点什么…", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .foregroundStyle(TopOutTheme.textPrimary)
                .padding(12)
                .background(TopOutTheme.backgroundPrimary, in: RoundedRectangle(cornerRadius: 10))
        }
        .topOutCard()
    }

    // MARK: - Public Toggle

    private var publicToggle: some View {
        Toggle(isOn: $isPublic) {
            HStack(spacing: 8) {
                Image(systemName: isPublic ? "eye" : "eye.slash")
                    .foregroundStyle(isPublic ? TopOutTheme.accentGreen : TopOutTheme.textTertiary)
                Text("公开这条记录")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textPrimary)
            }
        }
        .tint(TopOutTheme.accentGreen)
        .topOutCard()
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button {
                showDiscardAlert = true
            } label: {
                Text("放弃")
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.heartRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(TopOutTheme.heartRed.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            }

            Button {
                saveRecord()
            } label: {
                Text("保存")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(TopOutTheme.accentGreen, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TopOutTheme.backgroundPrimary)
    }

    // MARK: - Actions

    private func saveRecord() {
        let record = ClimbRecord(
            id: sessionData.id,
            startTime: sessionData.startTime,
            endTime: sessionData.endTime,
            duration: sessionData.duration,
            averageHeartRate: sessionData.averageHeartRate,
            maxHeartRate: sessionData.maxHeartRate,
            minHeartRate: sessionData.minHeartRate,
            calories: sessionData.calories,
            heartRateSamples: sessionData.heartRateSamples,
            climbIntervals: sessionData.climbIntervals,
            climbType: climbType,
            difficulty: difficulty.isEmpty ? nil : difficulty,
            completionStatus: completionStatus,
            isStarred: isStarred,
            feeling: feeling,
            notes: notes.isEmpty ? nil : notes,
            locationName: sessionData.locationName,
            isOutdoor: climbType.hasPrefix("outdoor"),
            isPublic: isPublic,
            videoURLs: videoPaths
        )
        modelContext.insert(record)
        try? modelContext.save()
        onSaved?()
        dismiss()
    }

    private func importVideo(from url: URL) {
        Task {
            do {
                let path = try await VideoStorageService.importVideo(from: url)
                await MainActor.run { videoPaths.append(path) }
            } catch {
                print("Video import failed: \(error)")
            }
        }
    }
}

// MARK: - Summary Item

private struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Data (passed from Watch → Phone)

struct ClimbSessionData {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let averageHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double
    let calories: Double
    let heartRateSamples: [HeartRateSample]
    let climbIntervals: [ClimbInterval]
    let locationName: String?

    static func from(message: [String: Any]) -> ClimbSessionData {
        let recordId = (message["recordId"] as? String).flatMap { UUID(uuidString: $0) } ?? UUID()
        let startTime = (message["startTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let endTime = (message["endTime"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let duration = message["duration"] as? TimeInterval ?? 0
        let avgHR = message["averageHeartRate"] as? Double ?? 0
        let maxHR = message["maxHeartRate"] as? Double ?? 0
        let minHR = message["minHeartRate"] as? Double ?? 0
        let calories = message["calories"] as? Double ?? 0

        var samples: [HeartRateSample] = []
        if let samplesString = message["heartRateSamples"] as? String,
           let data = samplesString.data(using: .utf8) {
            samples = (try? JSONDecoder().decode([HeartRateSample].self, from: data)) ?? []
        }

        return ClimbSessionData(
            id: recordId,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            minHeartRate: minHR,
            calories: calories,
            heartRateSamples: samples,
            climbIntervals: [],
            locationName: nil
        )
    }
}

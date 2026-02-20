import SwiftUI
import Charts
import AVKit

/// Climb detail — heart rate chart + metric cards + intervals + videos
struct RecordDetailView: View {
    @Bindable var record: ClimbRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteAlert = false
    @State private var showVideoSourceSheet = false
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                climbInfoHeader
                publicToggle
                headerSection
                metricCards
                if !record.videoURLs.isEmpty {
                    videoSection
                }
                if !record.heartRateSamples.isEmpty {
                    heartRateChartSection
                }
                if let notes = record.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                if !record.climbIntervals.isEmpty {
                    intervalsSection
                }
                deleteButton
            }
            .padding(16)
        }
        .topOutBackground()
        .navigationTitle("攀爬详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button { showVideoSourceSheet = true } label: {
                        Image(systemName: "video.badge.plus")
                            .foregroundStyle(TopOutTheme.accentGreen)
                    }
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(TopOutTheme.textSecondary)
                    }
                }
            }
        }
        .alert("删除这条记录？", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                // Delete associated videos
                for path in record.videoURLs {
                    VideoStorageService.deleteVideo(at: path)
                }
                modelContext.delete(record)
                try? modelContext.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复")
        }
        .confirmationDialog("添加视频", isPresented: $showVideoSourceSheet) {
            Button("从相册选择") { showPhotoPicker = true }
            Button("从文件导入") { showDocumentPicker = true }
            Button("拍摄视频") { showCamera = true }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showPhotoPicker) {
            VideoPhotoPickerView { url in importVideo(from: url) }
        }
        .sheet(isPresented: $showDocumentPicker) {
            VideoDocumentPickerView { url in importVideo(from: url) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            VideoCameraView { url in importVideo(from: url) }
        }
    }

    // MARK: - Public Toggle

    private var publicToggle: some View {
        Toggle(isOn: $record.isPublic) {
            HStack(spacing: 8) {
                Image(systemName: record.isPublic ? "eye" : "eye.slash")
                    .foregroundStyle(record.isPublic ? TopOutTheme.accentGreen : TopOutTheme.textTertiary)
                Text("公开这条记录")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textPrimary)
            }
        }
        .tint(TopOutTheme.accentGreen)
        .topOutCard()
    }

    // MARK: - Video Section

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("攀爬视频")
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("\(record.videoURLs.count) 个")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }

            VideoThumbnailGrid(videoPaths: record.videoURLs) { path in
                VideoStorageService.deleteVideo(at: path)
                record.videoURLs.removeAll { $0 == path }
            }
        }
        .topOutCard()
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("删除这条记录")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TopOutTheme.heartRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(TopOutTheme.heartRed.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }

    // MARK: - Climb Info Header (new fields)

    private var climbInfoHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text(climbTypeDisplayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(climbTypeColor, in: Capsule())

                if let diff = record.difficulty {
                    Text(diff)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TopOutTheme.accentGreen)
                }

                Spacer()

                if record.isStarred {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }

                Text(completionStatusIcon)
                    .font(.title2)
            }

            if let loc = record.locationName {
                HStack(spacing: 6) {
                    Image(systemName: record.isOutdoor ? "mountain.2.fill" : "building.2.fill")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                    Text(loc)
                        .font(.subheadline)
                        .foregroundStyle(TopOutTheme.textSecondary)
                    Spacer()
                }
            }

            HStack(spacing: 4) {
                Text("感受")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= record.feeling ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(i <= record.feeling ? .yellow : TopOutTheme.textTertiary)
                }
                Spacer()
            }
        }
        .topOutCard()
    }

    private var climbTypeDisplayName: String {
        switch record.climbType {
        case "indoorBoulder": return "室内抱石"
        case "indoorLead": return "室内先锋"
        case "indoorTopRope": return "室内顶绳"
        case "outdoorBoulder": return "户外抱石"
        case "outdoorLead": return "户外先锋"
        case "outdoorTrad": return "户外传统"
        case "outdoorBigWall": return "大岩壁"
        default: return record.climbType
        }
    }

    private var climbTypeColor: Color {
        record.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen
    }

    private var completionStatusIcon: String {
        switch record.completionStatus {
        case "completed": return "✅"
        case "failed": return "❌"
        case "flash": return "⚡"
        case "onsight": return "👁️"
        default: return "✅"
        }
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .topOutCard()
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

    private func importVideo(from url: URL) {
        Task {
            do {
                let path = try await VideoStorageService.importVideo(from: url)
                await MainActor.run { record.videoURLs.append(path) }
            } catch {
                print("Video import failed: \(error)")
            }
        }
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

import SwiftUI
import PhotosUI
import AVFoundation

/// Route recording sheet — single page: media buttons at top, route info below
struct RouteRecorderView: View {
    @EnvironmentObject var sessionState: ClimbSessionState
    @Environment(\.dismiss) private var dismiss
    
    @State private var difficulty = "V3"
    @State private var sendStatus: RouteRecord.SendStatus = .sent
    @State private var isStarred = false
    @State private var note = ""
    @State private var showCamera = false
    @State private var showVideoCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaPath: String?
    @State private var mediaType: RouteRecord.MediaType?
    @State private var thumbnailImage: UIImage?
    @State private var cameraReady = false
    
    private let boulderGrades = (0...16).map { "V\($0)" }
    private let ropeGrades = [
        "5.6", "5.7", "5.8", "5.9",
        "5.10a", "5.10b", "5.10c", "5.10d",
        "5.11a", "5.11b", "5.11c", "5.11d",
        "5.12a", "5.12b", "5.12c", "5.12d",
        "5.13a", "5.13b", "5.13c", "5.13d",
        "5.14a", "5.14b", "5.14c", "5.14d",
        "5.15a", "5.15b", "5.15c", "5.15d"
    ]
    
    private var allGrades: [String] { boulderGrades + ropeGrades }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TopOutTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Media buttons + preview
                        mediaSection
                        
                        // MARK: - Difficulty
                        difficultySection
                        
                        // MARK: - Send status
                        sendStatusSection
                        
                        // MARK: - Star + Note
                        extrasSection
                        
                        // MARK: - Confirm
                        confirmButton
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("记录这条线")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
            }
            .onAppear {
                // Pre-authorize camera so the button responds instantly
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    Task { @MainActor in cameraReady = granted }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(sourceType: .camera, mediaTypes: ["public.image"]) { url in
                    if let url { handleMediaURL(url) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showVideoCamera) {
                ImagePickerView(sourceType: .camera, mediaTypes: ["public.movie"]) { url in
                    if let url { handleMediaURL(url) }
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, item in
                Task {
                    guard let item else { return }
                    // Try loading as video first, then image
                    if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                        handleMediaURL(movie.url)
                    } else if let data = try? await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) {
                        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
                        try? image.jpegData(compressionQuality: 0.8)?.write(to: tmp)
                        handleMediaURL(tmp)
                    }
                }
            }
        }
    }
    
    // MARK: - Media Section
    
    private var mediaSection: some View {
        VStack(spacing: 12) {
            // Three buttons: photo, video, album
            HStack(spacing: 10) {
                Button {
                    showCamera = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.body)
                        Text("拍照")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(TopOutTheme.accentGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(TopOutTheme.accentGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showVideoCamera = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.body)
                        Text("录像")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(TopOutTheme.accentGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(TopOutTheme.accentGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .any(of: [.images, .videos])) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.body)
                        Text("相册")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(TopOutTheme.accentGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(TopOutTheme.accentGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Preview thumbnail if media selected
            if let thumbnailImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Remove button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.thumbnailImage = nil
                            self.mediaPath = nil
                            self.mediaType = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding(8)
                    
                    // Video badge
                    if mediaType == .video {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "video.fill")
                                    .font(.caption)
                                Text("视频")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Difficulty
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("难度")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)
            
            Picker("难度", selection: $difficulty) {
                ForEach(allGrades, id: \.self) { grade in
                    Text(grade).tag(grade)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .topOutCard()
        }
    }
    
    // MARK: - Send Status
    
    private var sendStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("完攀状态")
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)
            
            HStack(spacing: 12) {
                ForEach(RouteRecord.SendStatus.allCases, id: \.rawValue) { status in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            sendStatus = status
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(status.emoji)
                                .font(.title)
                            Text(status.rawValue)
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            sendStatus == status
                                ? TopOutTheme.accentGreen.opacity(0.2)
                                : TopOutTheme.backgroundCard,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    sendStatus == status
                                        ? TopOutTheme.accentGreen
                                        : TopOutTheme.cardStroke,
                                    lineWidth: sendStatus == status ? 2 : 1
                                )
                        )
                    }
                    .foregroundStyle(TopOutTheme.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Extras
    
    private var extrasSection: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $isStarred) {
                HStack(spacing: 6) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? TopOutTheme.warningAmber : TopOutTheme.textTertiary)
                    Text("标记好线")
                        .foregroundStyle(TopOutTheme.textPrimary)
                }
            }
            .tint(TopOutTheme.warningAmber)
            .topOutCard()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("一句话感受（可选）")
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textSecondary)
                TextField("今天这条线手感不错…", text: $note)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(TopOutTheme.backgroundCard, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(TopOutTheme.textPrimary)
            }
        }
    }
    
    // MARK: - Confirm
    
    private var confirmButton: some View {
        Button {
            let record = RouteRecord(
                difficulty: difficulty,
                sendStatus: sendStatus,
                isStarred: isStarred,
                note: note.isEmpty ? nil : note,
                mediaPath: mediaPath,
                mediaType: mediaType,
                timestamp: Date()
            )
            sessionState.addRecord(record)
            dismiss()
        } label: {
            Text("记录")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(TopOutTheme.accentGreen, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Helpers
    
    private func handleMediaURL(_ url: URL) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let isVideo = url.pathExtension.lowercased() == "mov" || url.pathExtension.lowercased() == "mp4"
        let ext = isVideo ? "mov" : "jpg"
        let dest = docs.appendingPathComponent("route_\(UUID().uuidString).\(ext)")
        try? FileManager.default.copyItem(at: url, to: dest)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            mediaPath = dest.path
            mediaType = isVideo ? .video : .photo
            
            if isVideo {
                // Generate video thumbnail
                generateVideoThumbnail(url: dest)
            } else {
                thumbnailImage = UIImage(contentsOfFile: dest.path)
            }
        }
    }
    
    private func generateVideoThumbnail(url: URL) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        
        Task {
            if let cgImage = try? await generator.image(at: .zero).image {
                await MainActor.run {
                    thumbnailImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}

// MARK: - Video transferable for PhotosPicker

struct VideoTransferable: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: tmp)
            return Self(url: tmp)
        }
    }
}

// MARK: - UIImagePickerController wrapper

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let mediaTypes: [String]
    let completion: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes
        picker.delegate = context.coordinator
        if mediaTypes.contains("public.movie") {
            picker.videoMaximumDuration = 60
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (URL?) -> Void
        init(completion: @escaping (URL?) -> Void) { self.completion = completion }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let url = info[.mediaURL] as? URL {
                completion(url)
            } else if let image = info[.originalImage] as? UIImage {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
                try? image.jpegData(compressionQuality: 0.8)?.write(to: tmp)
                completion(tmp)
            } else {
                completion(nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            completion(nil)
        }
    }
}

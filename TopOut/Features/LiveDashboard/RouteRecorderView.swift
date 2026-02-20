import SwiftUI
import PhotosUI

/// Route recording sheet — capture media + log route info
struct RouteRecorderView: View {
    @EnvironmentObject var sessionState: ClimbSessionState
    @Environment(\.dismiss) private var dismiss
    
    @State private var difficulty = "V3"
    @State private var sendStatus: RouteRecord.SendStatus = .sent
    @State private var isStarred = false
    @State private var note = ""
    @State private var showMediaPicker = false
    @State private var showCamera = false
    @State private var showVideoCam = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaPath: String?
    @State private var mediaType: RouteRecord.MediaType?
    @State private var showMediaActionSheet = false
    @State private var step: RecordStep = .media
    
    enum RecordStep {
        case media, info
    }
    
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
                    VStack(spacing: 24) {
                        if step == .media {
                            mediaStep
                        } else {
                            infoStep
                        }
                    }
                    .padding()
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
            .confirmationDialog("添加照片/视频", isPresented: $showMediaActionSheet) {
                Button("📷 拍照") { showCamera = true }
                Button("🎬 录像") { showVideoCam = true }
                Button("📂 从相册选择") { showMediaPicker = true }
                Button("⏭️ 跳过", role: .cancel) {
                    step = .info
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(sourceType: .camera, mediaTypes: ["public.image"]) { url in
                    if let url {
                        mediaPath = saveToDocuments(url: url, type: .photo)
                        mediaType = .photo
                    }
                    step = .info
                }
            }
            .sheet(isPresented: $showVideoCam) {
                ImagePickerView(sourceType: .camera, mediaTypes: ["public.movie"]) { url in
                    if let url {
                        mediaPath = saveToDocuments(url: url, type: .video)
                        mediaType = .video
                    }
                    step = .info
                }
            }
        }
    }
    
    // MARK: - Media Step
    
    private var mediaStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(TopOutTheme.accentGreen)
            
            Text("记录你的攀爬")
                .font(.title2.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
            
            Text("拍照、录像或从相册选择")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textSecondary)
            
            Button {
                showMediaActionSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加照片/视频")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(TopOutTheme.accentGreen, in: RoundedRectangle(cornerRadius: 14))
            }
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .any(of: [.images, .videos])) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("从相册选择")
                }
                .font(.headline)
                .foregroundStyle(TopOutTheme.accentGreen)
                .frame(maxWidth: .infinity)
                .padding()
                .background(TopOutTheme.accentGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            }
            .onChange(of: selectedPhotoItem) { _, item in
                if item != nil {
                    // For simplicity, treat as photo
                    mediaType = .photo
                    step = .info
                }
            }
            
            Button {
                step = .info
            } label: {
                Text("⏭️ 跳过，直接记录")
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - Info Step
    
    private var infoStep: some View {
        VStack(spacing: 24) {
            // Difficulty picker
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
            
            // Send status
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
            
            // Star toggle
            Toggle(isOn: $isStarred) {
                HStack(spacing: 6) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? TopOutTheme.warningAmber : TopOutTheme.textTertiary)
                    Text("标记好线 ⭐")
                        .foregroundStyle(TopOutTheme.textPrimary)
                }
            }
            .tint(TopOutTheme.warningAmber)
            .topOutCard()
            
            // Note
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
            
            // Confirm button
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
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("记录")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(TopOutTheme.accentGreen, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func saveToDocuments(url: URL, type: RouteRecord.MediaType) -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ext = type == .photo ? "jpg" : "mov"
        let dest = docs.appendingPathComponent("route_\(UUID().uuidString).\(ext)")
        try? FileManager.default.copyItem(at: url, to: dest)
        return dest.path
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

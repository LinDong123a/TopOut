import SwiftUI
import AVKit

/// Grid of video thumbnails with play and delete
struct VideoThumbnailGrid: View {
    let videoPaths: [String]
    let onDelete: (String) -> Void
    @State private var playingPath: String?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(videoPaths, id: \.self) { path in
                VideoThumbnailCell(path: path) {
                    playingPath = path
                } onDelete: {
                    onDelete(path)
                }
            }
        }
        .fullScreenCover(item: $playingPath) { path in
            VideoPlayerSheet(url: VideoStorageService.fullURL(for: path))
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Thumbnail Cell

private struct VideoThumbnailCell: View {
    let path: String
    let onPlay: () -> Void
    let onDelete: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onPlay) {
                ZStack {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 90)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(TopOutTheme.backgroundPrimary)
                            .frame(height: 90)
                            .overlay {
                                ProgressView()
                                    .tint(TopOutTheme.textTertiary)
                            }
                    }

                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(radius: 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, TopOutTheme.heartRed)
                    .shadow(radius: 2)
            }
            .offset(x: 4, y: -4)
        }
        .task {
            thumbnail = await VideoStorageService.generateThumbnail(for: path)
        }
    }
}

// MARK: - Video Player Sheet

private struct VideoPlayerSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .black.opacity(0.5))
                    .padding(16)
            }
        }
        .background(.black)
    }
}

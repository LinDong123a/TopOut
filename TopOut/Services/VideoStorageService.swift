import Foundation
import AVFoundation
import UIKit

/// Manages climb video storage in Documents/ClimbVideos/
enum VideoStorageService {
    static let maxVideoSize: Int64 = 100 * 1024 * 1024 // 100 MB

    private static var videosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("ClimbVideos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Copy a video file into app storage, returns relative path "ClimbVideos/<uuid>.mov"
    static func importVideo(from sourceURL: URL) async throws -> String {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        let attrs = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        if let size = attrs[.size] as? Int64, size > maxVideoSize {
            throw VideoError.fileTooLarge
        }

        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let filename = "\(UUID().uuidString).\(ext)"
        let destURL = videosDirectory.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        return "ClimbVideos/\(filename)"
    }

    /// Resolve a relative path to full URL
    static func fullURL(for relativePath: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(relativePath)
    }

    /// Delete a video file
    static func deleteVideo(at relativePath: String) {
        let url = fullURL(for: relativePath)
        try? FileManager.default.removeItem(at: url)
    }

    /// Generate thumbnail for a video
    static func generateThumbnail(for relativePath: String) async -> UIImage? {
        let url = fullURL(for: relativePath)
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 300, height: 300)
        do {
            let cgImage = try generator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }

    enum VideoError: LocalizedError {
        case fileTooLarge
        var errorDescription: String? {
            switch self {
            case .fileTooLarge: return "视频文件超过 100MB 限制"
            }
        }
    }
}

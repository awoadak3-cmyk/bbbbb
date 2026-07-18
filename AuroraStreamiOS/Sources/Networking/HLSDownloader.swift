import Foundation
import AVFoundation

enum DownloadResult {
    case success(String)
    case failure(String)
}

/// Downloads an HLS stream (.m3u8) and re-packages it as a playable file using AVFoundation's
/// AVAssetExportSession — this is the natural iOS equivalent of the Android FFmpeg-less
/// MediaMuxer remux approach, since AVFoundation understands HLS natively.
actor HLSDownloader {
    static let shared = HLSDownloader()

    private let session = URLSession(configuration: .default)

    func download(m3u8URL: String, referer: String?, onProgress: @escaping (Double) -> Void) async -> DownloadResult {
        guard let url = URL(string: m3u8URL) else { return .failure("رابط غير صالح") }

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": referer.map { ["Referer": $0, "Origin": $0] } ?? [:]
        ])

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return .failure("تعذّر تجهيز جلسة التصدير")
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AuroraStream_\(Int(Date().timeIntervalSince1970))")
            .appendingPathExtension("mp4")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        let progressTask = Task {
            while exportSession.status == .waiting || exportSession.status == .exporting {
                onProgress(Double(exportSession.progress))
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }

        await exportSession.export()
        progressTask.cancel()

        switch exportSession.status {
        case .completed:
            guard let savedPath = await saveToPhotoLibraryOrFiles(outputURL) else {
                return .failure("فشل حفظ الملف النهائي")
            }
            return .success(savedPath)
        default:
            let message = exportSession.error?.localizedDescription ?? "فشل غير معروف أثناء التصدير"
            return .failure(message)
        }
    }

    /// Saves into the app's Documents folder (visible via the Files app under "On My iPhone").
    /// A Photos-library save would need NSPhotoLibraryAddUsageDescription + PHPhotoLibrary APIs;
    /// Files-app export keeps this dependency-free and works out of the box.
    private func saveToPhotoLibraryOrFiles(_ tempURL: URL) async -> String? {
        do {
            let docs = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let destination = docs.appendingPathComponent(tempURL.lastPathComponent)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: tempURL, to: destination)
            return destination.lastPathComponent
        } catch {
            return nil
        }
    }
}

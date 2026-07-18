import Foundation

/// Pulls the same `data/index.json` + `data/<file>.json` structure the Android app reads,
/// straight from raw.githubusercontent.com — no backend server required.
final class GitHubDataService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    private func rawBase(repo: String, branch: String) -> String {
        "https://raw.githubusercontent.com/\(repo)/\(branch)"
    }

    func fetchIndex(repo: String, branch: String = "main") async -> [String] {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        guard let url = URL(string: "\(rawBase(repo: repo, branch: branch))/data/index.json?t=\(ts)") else { return [] }
        guard let data = await execute(url) else { return [] }
        return (try? decoder.decode([String].self, from: data)) ?? []
    }

    func fetchFile(repo: String, file: String, branch: String = "main") async -> [MediaItem] {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        guard let url = URL(string: "\(rawBase(repo: repo, branch: branch))/data/\(file)?t=\(ts)") else { return [] }
        guard let data = await execute(url) else { return [] }
        let category = String(file.split(separator: "_").first ?? "")
        let items = (try? decoder.decode([MediaItem].self, from: data)) ?? []
        return items.map { item in
            var copy = item
            copy.category = category
            return copy
        }
    }

    private func execute(_ url: URL) async -> Data? {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            return data
        } catch {
            return nil
        }
    }

    /// Sorts file names newest-first based on the numeric timestamp embedded in the filename.
    func sortByTimestampDesc(_ files: [String]) -> [String] {
        func extractTimestamp(_ f: String) -> Int64 {
            let digits = f.filter { $0.isNumber }
            // Grab the longest digit run (mirrors the Kotlin regex \d+ "first match" behavior closely enough)
            var best = ""
            var current = ""
            for ch in f {
                if ch.isNumber {
                    current.append(ch)
                } else {
                    if current.count > best.count { best = current }
                    current = ""
                }
            }
            if current.count > best.count { best = current }
            _ = digits
            return Int64(best) ?? 0
        }
        return files.sorted { extractTimestamp($0) > extractTimestamp($1) }
    }
}

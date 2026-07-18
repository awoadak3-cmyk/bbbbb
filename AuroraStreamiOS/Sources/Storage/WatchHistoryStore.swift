import Foundation
import Combine

@MainActor
final class WatchHistoryStore: ObservableObject {
    @Published private(set) var entries: [WatchHistoryEntry] = []

    private let defaults = UserDefaults.standard
    private let key = "aurora_watch_history_v1"
    private let maxEntries = 25

    init() {
        load()
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WatchHistoryEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.lastWatchedAt > $1.lastWatchedAt }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }

    func recordPlay(item: MediaItem, season: Int?, episode: Int?) {
        entries.removeAll { $0.item.id == item.id }
        let entry = WatchHistoryEntry(item: item, season: season, episode: episode, lastWatchedAt: Date().timeIntervalSince1970 * 1000)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        persist()
    }

    func remove(itemId: Int) {
        entries.removeAll { $0.item.id == itemId }
        persist()
    }

    func entry(for itemId: Int) -> WatchHistoryEntry? {
        entries.first { $0.item.id == itemId }
    }
}

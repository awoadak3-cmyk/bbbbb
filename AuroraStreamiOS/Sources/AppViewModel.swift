import Foundation
import Combine

struct EpisodeContext: Equatable {
    let item: MediaItem
    let season: Int
    let episode: Int
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var categories: [String: [MediaItem]] = [:]
    @Published var heroCandidates: [MediaItem] = []
    @Published var isLoading = true
    @Published var isBatchLoading = false
    @Published var loadError: String?
    @Published var hasMore = true

    @Published var selectedItem: MediaItem?
    @Published var playingURL: String?
    @Published var episodeContext: EpisodeContext?

    let settings: SettingsStore
    let watchHistory: WatchHistoryStore
    private let repository: LibraryRepository

    private static let vidApiBase = "https://vaplayer.ru/embed"

    init(settings: SettingsStore, watchHistory: WatchHistoryStore, repository: LibraryRepository = LibraryRepository(dataService: GitHubDataService())) {
        self.settings = settings
        self.watchHistory = watchHistory
        self.repository = repository
    }

    func loadInitial() async {
        guard !settings.settings.repo.isEmpty else {
            isLoading = false
            loadError = "أدخل مستودع GitHub بالإعدادات أول (owner/repo)"
            return
        }
        isLoading = true
        loadError = nil
        categories = [:]
        _ = await repository.refreshIndex(repo: settings.settings.repo, branch: settings.settings.branch)
        await loadMore()
        isLoading = false
    }

    func loadMore() async {
        guard !isBatchLoading else { return }
        isBatchLoading = true
        let batch = await repository.loadNextBatch(repo: settings.settings.repo, branch: settings.settings.branch, count: 3)
        mergeBatch(batch)
        hasMore = await repository.hasMoreFiles
        isBatchLoading = false
    }

    private func mergeBatch(_ items: [MediaItem]) {
        for item in items {
            guard let cat = item.category else { continue }
            categories[cat, default: []].append(item)
        }
        rebuildHeroCandidates()
    }

    private func rebuildHeroCandidates() {
        let trending = categories[LibraryCategory.trending.rawValue] ?? []
        heroCandidates = Array(trending.prefix(5))
    }

    // MARK: - Selection / playback

    func selectItem(_ item: MediaItem) { selectedItem = item }
    func clearSelectedItem() { selectedItem = nil }

    func playMovie(_ item: MediaItem) {
        playingURL = "\(Self.vidApiBase)/movie/\(item.id)?autoplay=1"
        episodeContext = nil
        watchHistory.recordPlay(item: item, season: nil, episode: nil)
    }

    func playEpisode(_ item: MediaItem, season: Int, episode: Int) {
        playingURL = "\(Self.vidApiBase)/tv/\(item.id)/\(season)/\(episode)?autoplay=1"
        episodeContext = EpisodeContext(item: item, season: season, episode: episode)
        watchHistory.recordPlay(item: item, season: season, episode: episode)
    }

    func stopPlayback() {
        playingURL = nil
        episodeContext = nil
    }

    var hasNextEpisode: Bool {
        guard let ctx = episodeContext else { return false }
        return WatchHistoryEntry(item: ctx.item, season: ctx.season, episode: ctx.episode, lastWatchedAt: 0).nextEpisode != nil
    }

    func playNextEpisode() {
        guard let ctx = episodeContext else { return }
        guard let next = WatchHistoryEntry(item: ctx.item, season: ctx.season, episode: ctx.episode, lastWatchedAt: 0).nextEpisode else { return }
        playEpisode(ctx.item, season: next.season, episode: next.episode)
    }

    func resumeFromHistory(_ entry: WatchHistoryEntry) {
        if let season = entry.season, let episode = entry.episode {
            selectedItem = entry.item
            _ = season; _ = episode // details screen drives the actual episode picker; we just open it
        } else {
            selectedItem = entry.item
        }
    }

    // MARK: - Search

    func searchPool() async -> [MediaItem] {
        await repository.loadAllForSearch(repo: settings.settings.repo, branch: settings.settings.branch)
    }

    func search(_ query: String, in pool: [MediaItem]) -> [MediaItem] {
        repository.searchLocally(query: query, pool: pool)
    }
}

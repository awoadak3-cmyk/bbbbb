import Foundation

/// Mirrors the Android WatchHistoryStore entry: tracks which episode/movie you were on,
/// not an exact playback second (the player is a web embed, so we can't read that reliably).
struct WatchHistoryEntry: Codable, Hashable, Identifiable {
    var id: Int { item.id }
    let item: MediaItem
    let season: Int?
    let episode: Int?
    let lastWatchedAt: Double

    var resumeLabel: String {
        if let season, let episode, season > 0, episode > 0 {
            return "الموسم \(season) • الحلقة \(episode)"
        }
        return "استكمال المشاهدة"
    }

    var nextEpisode: (season: Int, episode: Int)? {
        guard let season, let episode else { return nil }
        guard let currentSeasonInfo = item.validSeasons.first(where: { $0.seasonNumber == season }) else { return nil }
        if episode < currentSeasonInfo.episodeCount {
            return (season, episode + 1)
        }
        if let nextSeason = item.validSeasons.first(where: { $0.seasonNumber == season + 1 }) {
            return (nextSeason.seasonNumber, 1)
        }
        return nil
    }
}

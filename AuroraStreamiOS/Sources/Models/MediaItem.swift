import Foundation

struct SeasonInfo: Codable, Hashable {
    let seasonNumber: Int
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
    }

    init(seasonNumber: Int = 0, episodeCount: Int = 0) {
        self.seasonNumber = seasonNumber
        self.episodeCount = episodeCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seasonNumber = (try? c.decode(Int.self, forKey: .seasonNumber)) ?? 0
        episodeCount = (try? c.decode(Int.self, forKey: .episodeCount)) ?? 0
    }
}

/// A single actor entry for the cast row. JSON shape: { "name", "role", "photo_url" }
struct CastMember: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let role: String
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, role
        case photoUrl = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        role = (try? c.decode(String.self, forKey: .role)) ?? ""
        photoUrl = try? c.decode(String.self, forKey: .photoUrl)
    }
}

struct MediaItem: Codable, Hashable, Identifiable {
    var id: Int
    let title: String?
    let name: String?
    let titleEn: String?
    let overview: String?
    let overviewEn: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let firstAirDate: String?
    let mediaType: String?
    let originalTitle: String?
    let originalName: String?
    let seasons: [SeasonInfo]?
    let cast: [CastMember]?
    let dateAdded: Double?
    var category: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview, seasons, cast, category
        case titleEn = "title_en"
        case overviewEn = "overview_en"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case mediaType = "media_type"
        case originalTitle = "original_title"
        case originalName = "original_name"
        case dateAdded = "date_added"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        title = try? c.decode(String.self, forKey: .title)
        name = try? c.decode(String.self, forKey: .name)
        titleEn = try? c.decode(String.self, forKey: .titleEn)
        overview = try? c.decode(String.self, forKey: .overview)
        overviewEn = try? c.decode(String.self, forKey: .overviewEn)
        posterPath = try? c.decode(String.self, forKey: .posterPath)
        backdropPath = try? c.decode(String.self, forKey: .backdropPath)
        voteAverage = try? c.decode(Double.self, forKey: .voteAverage)
        releaseDate = try? c.decode(String.self, forKey: .releaseDate)
        firstAirDate = try? c.decode(String.self, forKey: .firstAirDate)
        mediaType = try? c.decode(String.self, forKey: .mediaType)
        originalTitle = try? c.decode(String.self, forKey: .originalTitle)
        originalName = try? c.decode(String.self, forKey: .originalName)
        seasons = try? c.decode([SeasonInfo].self, forKey: .seasons)
        cast = try? c.decode([CastMember].self, forKey: .cast)
        dateAdded = try? c.decode(Double.self, forKey: .dateAdded)
        category = try? c.decode(String.self, forKey: .category)
    }

    init(
        id: Int, title: String? = nil, name: String? = nil, titleEn: String? = nil,
        overview: String? = nil, overviewEn: String? = nil, posterPath: String? = nil,
        backdropPath: String? = nil, voteAverage: Double? = nil, releaseDate: String? = nil,
        firstAirDate: String? = nil, mediaType: String? = nil, originalTitle: String? = nil,
        originalName: String? = nil, seasons: [SeasonInfo]? = nil, cast: [CastMember]? = nil,
        dateAdded: Double? = nil, category: String? = nil
    ) {
        self.id = id; self.title = title; self.name = name; self.titleEn = titleEn
        self.overview = overview; self.overviewEn = overviewEn; self.posterPath = posterPath
        self.backdropPath = backdropPath; self.voteAverage = voteAverage; self.releaseDate = releaseDate
        self.firstAirDate = firstAirDate; self.mediaType = mediaType; self.originalTitle = originalTitle
        self.originalName = originalName; self.seasons = seasons; self.cast = cast
        self.dateAdded = dateAdded; self.category = category
    }

    // MARK: - Derived, mirrors the Kotlin computed properties exactly

    var displayTitle: String { title ?? name ?? "بدون عنوان" }

    var year: String {
        let raw = releaseDate ?? firstAirDate ?? ""
        return String(raw.prefix(4))
    }

    var resolvedType: String {
        if let mediaType { return mediaType }
        if let category { return category == "movies" ? "movie" : "tv" }
        return title != nil ? "movie" : "tv"
    }

    var ratingText: String {
        guard let voteAverage else { return "0.0" }
        return String(format: "%.1f", voteAverage)
    }

    var validSeasons: [SeasonInfo] {
        (seasons ?? []).filter { $0.seasonNumber > 0 && $0.episodeCount > 0 }
    }

    var castList: [CastMember] {
        (cast ?? []).filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var isRecentlyAdded: Bool {
        guard let dateAdded else { return false }
        let now = Date().timeIntervalSince1970 * 1000
        return (now - dateAdded) < 48 * 60 * 60 * 1000
    }

    static let imgBaseW500 = "https://image.tmdb.org/t/p/w500"
    static let imgBaseOriginal = "https://image.tmdb.org/t/p/original"

    var posterUrl: URL? {
        guard let posterPath else { return nil }
        return URL(string: Self.imgBaseW500 + posterPath)
    }

    var backdropUrl: URL? {
        guard let path = backdropPath ?? posterPath else { return nil }
        return URL(string: Self.imgBaseOriginal + path)
    }
}

enum LibraryCategory: String, CaseIterable, Identifiable {
    case trending, latest, movies, series, kdrama, anime

    var id: String { rawValue }

    var displayNameAr: String {
        switch self {
        case .trending: return "الأكثر رواجاً"
        case .latest: return "الأحدث على الإنترنت"
        case .movies: return "أفلام"
        case .series: return "مسلسلات"
        case .kdrama: return "دراما كورية"
        case .anime: return "أنمي"
        }
    }

    static let order: [LibraryCategory] = [.trending, .latest, .movies, .series, .kdrama, .anime]
}

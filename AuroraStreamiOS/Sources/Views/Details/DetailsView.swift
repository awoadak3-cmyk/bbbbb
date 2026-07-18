import SwiftUI

struct DetailsView: View {
    let item: MediaItem
    var onDismiss: () -> Void
    var onPlayMovie: (MediaItem) -> Void
    var onPlayEpisode: (MediaItem, Int, Int) -> Void
    var onRepair: (MediaItem) -> Void

    @State private var selectedSeason: Int = 0
    @State private var selectedEpisode: Int = 1

    private var isTv: Bool { !item.validSeasons.isEmpty || item.resolvedType == "tv" }

    var body: some View {
        ZStack(alignment: .top) {
            AuroraColor.deepBlack.ignoresSafeArea()

            ScrollView {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: item.backdropUrl) { phase in
                        switch phase {
                        case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                        default: Rectangle().fill(AuroraColor.cardDark)
                        }
                    }
                    .frame(height: 260)
                    .clipped()

                    LinearGradient(colors: [.clear, AuroraColor.deepBlack], startPoint: .top, endPoint: .bottom)
                        .frame(height: 260)
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5), in: Circle())
                    }
                    .padding(14)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        AsyncImage(url: item.posterUrl) { phase in
                            switch phase {
                            case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                            default: Rectangle().fill(AuroraColor.cardDark)
                            }
                        }
                        .frame(width: 100, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .offset(y: -40)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.displayTitle).font(.system(size: 20, weight: .black)).foregroundStyle(.white)
                            if let en = item.titleEn, !en.isEmpty, en != item.displayTitle {
                                Text(en).font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
                            }
                            HStack(spacing: 6) {
                                if !item.year.isEmpty { pill(item.year) }
                                HStack(spacing: 2) {
                                    Text("IMDb").font(.system(size: 9, weight: .black)).foregroundStyle(.black)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(AuroraColor.imdbGold, in: RoundedRectangle(cornerRadius: 4))
                                    Text(item.ratingText).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top, -20)

                    if let overview = item.overview, !overview.isEmpty {
                        Text(overview).font(.system(size: 13)).foregroundStyle(.white.opacity(0.8)).lineLimit(6)
                    }

                    CastRow(cast: item.castList)

                    if isTv {
                        seasonEpisodePicker
                        Button {
                            onPlayEpisode(item, max(selectedSeason, 1), selectedEpisode)
                        } label: {
                            playLabel
                        }
                    } else {
                        Button { onPlayMovie(item) } label: { playLabel }
                    }

                    Button {
                        onRepair(item)
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("إبلاغ عن مشكلة بهذا العمل")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let first = item.validSeasons.first { selectedSeason = first.seasonNumber }
        }
    }

    private var playLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.fill")
            Text("مشاهدة الآن").fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AuroraColor.brandRed, in: RoundedRectangle(cornerRadius: 14))
    }

    private var seasonEpisodePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            if item.validSeasons.count > 1 {
                Text("الموسم").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(item.validSeasons, id: \.seasonNumber) { season in
                            chip("موسم \(season.seasonNumber)", selected: season.seasonNumber == selectedSeason) {
                                selectedSeason = season.seasonNumber
                                selectedEpisode = 1
                            }
                        }
                    }
                }
            }

            let episodeCount = item.validSeasons.first(where: { $0.seasonNumber == selectedSeason })?.episodeCount ?? 0
            if episodeCount > 0 {
                Text("الحلقة").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...episodeCount, id: \.self) { ep in
                            chip("\(ep)", selected: ep == selectedEpisode) { selectedEpisode = ep }
                        }
                    }
                }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? AuroraColor.brandRed : AuroraColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }
}

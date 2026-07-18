import SwiftUI
import Combine

struct HeroCarousel: View {
    let items: [MediaItem]
    let onPlay: (MediaItem) -> Void

    @State private var index = 0
    private let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            let item = items[index % items.count]

            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: item.backdropUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(AuroraColor.cardDark)
                    }
                }
                .frame(height: 460)
                .clipped()
                .id(item.id)
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))

                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.55), AuroraColor.deepBlack],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 460)

                VStack(alignment: .leading, spacing: 10) {
                    Text(item.displayTitle)
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if !item.year.isEmpty {
                            Text(item.year)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        }
                        Text("IMDb")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(AuroraColor.imdbGold, in: RoundedRectangle(cornerRadius: 6))
                        HStack(spacing: 2) {
                            Text(item.ratingText).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(AuroraColor.goldStar)
                        }
                    }

                    Text((item.overview?.isEmpty == false ? item.overview : nil) ?? "محتوى حصري مضاف وجاهز للمشاهدة الفورية.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(3)

                    Button { onPlay(item) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("مشاهدة الآن").fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26).padding(.vertical, 12)
                        .background(AuroraColor.brandRed, in: Capsule())
                    }
                    .padding(.top, 4)

                    // Pagination dots
                    HStack(spacing: 5) {
                        ForEach(0..<min(items.count, 6), id: \.self) { i in
                            Capsule()
                                .fill(i == index % items.count ? AuroraColor.brandRed : Color.white.opacity(0.3))
                                .frame(width: i == index % items.count ? 16 : 5, height: 5)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .frame(height: 460)
            .onReceive(timer) { _ in
                withAnimation { index = (index + 1) % items.count }
            }
        }
    }
}

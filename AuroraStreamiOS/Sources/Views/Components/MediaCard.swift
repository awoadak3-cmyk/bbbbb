import SwiftUI

struct MediaCard: View {
    let item: MediaItem
    var rank: Int? = nil
    var width: CGFloat = 128

    @State private var pressed = false

    private var isTopRank: Bool { rank == 1 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                AsyncImage(url: item.posterUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(AuroraColor.cardDark)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .aspectRatio(2.0/3.0, contentMode: .fit)

            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .init(x: 0.5, y: 0.55),
                endPoint: .bottom
            )

            // Rating chip bottom-trailing
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(AuroraColor.goldStar)
                        Text(item.ratingText).font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 5))
                    .padding(6)
                }
            }

            // Rank badge or "NEW" badge, top-leading
            if let rank {
                Text("\(rank)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(rankColor(rank), in: UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 0))
            } else if item.isRecentlyAdded {
                Text("جديد")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(AuroraColor.rankGreen, in: UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 0))
            }

            // Title bottom-leading
            VStack {
                Spacer()
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.leading, 8).padding(.trailing, 42).padding(.bottom, 8)
                    Spacer()
                }
            }
        }
        .frame(width: width)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTopRank ? AuroraColor.brandRed.opacity(0.6) : Color.white.opacity(0.05), lineWidth: isTopRank ? 1.5 : 1)
        )
        .shadow(color: isTopRank ? AuroraColor.brandRed.opacity(0.5) : .black.opacity(0.3), radius: isTopRank ? 10 : 3)
        .scaleEffect(pressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            pressed = isPressing
        }, perform: {})
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return AuroraColor.rankCrimson
        case 2: return AuroraColor.rankGreen
        default: return AuroraColor.rankGold
        }
    }
}

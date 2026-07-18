import SwiftUI

struct ContinueWatchingRow: View {
    let entries: [WatchHistoryEntry]
    let onResume: (WatchHistoryEntry) -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("متابعة المشاهدة")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(entries) { entry in
                            card(entry)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func card(_ entry: WatchHistoryEntry) -> some View {
        ZStack(alignment: .topTrailing) {
            Button { onResume(entry) } label: {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: entry.item.backdropUrl ?? entry.item.posterUrl) { phase in
                        switch phase {
                        case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                        default: Rectangle().fill(AuroraColor.cardDark)
                        }
                    }
                    .frame(width: 220, height: 124)
                    .clipped()

                    LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .init(x: 0.5, y: 0.35), endPoint: .bottom)

                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.45), in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.item.displayTitle)
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                        Text(entry.resumeLabel)
                            .font(.system(size: 10, weight: .semibold)).foregroundStyle(AuroraColor.brandRed)
                    }
                    .padding(8)
                }
                .frame(width: 220, height: 124)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button { onRemove(entry.item.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.5), in: Circle())
            }
            .padding(4)
        }
    }
}

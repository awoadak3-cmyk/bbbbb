import SwiftUI

struct CategoryRow: View {
    let title: String
    let items: [MediaItem]
    let showRank: Bool
    let categoryKey: String?
    let onTap: (MediaItem) -> Void

    private var accent: Color { AuroraColor.categoryAccent(for: title) }

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [accent.opacity(0.35), accent.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 26, height: 26)
                        Image(systemName: AuroraColor.categoryIcon(for: categoryKey))
                            .font(.system(size: 13))
                            .foregroundStyle(accent)
                    }
                    Text(title).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            Button { onTap(item) } label: {
                                MediaCard(item: item, rank: showRank ? index + 1 : nil)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

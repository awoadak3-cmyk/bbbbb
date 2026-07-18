import SwiftUI

struct CastRow: View {
    let cast: [CastMember]

    var body: some View {
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("الفنان").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(cast) { member in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(AuroraColor.cardDark)
                                    if let url = member.photoUrl.flatMap(URL.init) {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let image) = phase {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                initials(member.name)
                                            }
                                        }
                                        .clipShape(Circle())
                                    } else {
                                        initials(member.name)
                                    }
                                }
                                .frame(width: 72, height: 72)
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))

                                Text(member.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                if !member.role.isEmpty {
                                    Text(member.role)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 76)
                        }
                    }
                }
            }
        }
    }

    private func initials(_ name: String) -> some View {
        Text(name.trimmingCharacters(in: .whitespaces).first.map(String.init)?.uppercased() ?? "?")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white.opacity(0.7))
    }
}

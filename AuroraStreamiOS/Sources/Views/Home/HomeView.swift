import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        ZStack {
            AuroraColor.deepBlack.ignoresSafeArea()

            if vm.isLoading {
                ProgressView().tint(AuroraColor.brandRed)
            } else if let error = vm.loadError, vm.categories.values.allSatisfy({ $0.isEmpty }) {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash").font(.system(size: 32)).foregroundStyle(.white.opacity(0.4))
                    Text(error).font(.system(size: 14)).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center)
                }
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        HeroCarousel(items: vm.heroCandidates) { item in vm.selectItem(item) }

                        ContinueWatchingRow(
                            entries: vm.watchHistory.entries,
                            onResume: { vm.resumeFromHistory($0) },
                            onRemove: { vm.watchHistory.remove(itemId: $0) }
                        )

                        ForEach(LibraryCategory.order) { cat in
                            let items = vm.categories[cat.rawValue] ?? []
                            CategoryRow(
                                title: cat.displayNameAr,
                                items: items,
                                showRank: cat == .trending,
                                categoryKey: cat.rawValue,
                                onTap: { vm.selectItem($0) }
                            )
                        }

                        if vm.hasMore {
                            ProgressView()
                                .tint(AuroraColor.brandRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .onAppear { Task { await vm.loadMore() } }
                        } else {
                            Spacer().frame(height: 30)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .task {
            if vm.categories.isEmpty { await vm.loadInitial() }
        }
    }
}

import SwiftUI

enum RootTab: String, CaseIterable {
    case home, search, settings

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .home: return "الرئيسية"
        case .search: return "بحث"
        case .settings: return "الإعدادات"
        }
    }
}

struct RootView: View {
    @StateObject private var settings = SettingsStore()
    @StateObject private var watchHistory = WatchHistoryStore()
    @StateObject private var vm: AppViewModel

    @State private var tab: RootTab = .home

    init() {
        let s = SettingsStore()
        let w = WatchHistoryStore()
        _settings = StateObject(wrappedValue: s)
        _watchHistory = StateObject(wrappedValue: w)
        _vm = StateObject(wrappedValue: AppViewModel(settings: s, watchHistory: w))
    }

    var body: some View {
        ZStack {
            AuroraColor.deepBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    switch tab {
                    case .home: HomeView()
                    case .search: SearchView()
                    case .settings: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                floatingTabBar
            }

            // Full-screen layers — declared last so they draw on top, matching the
            // "no separate window, just top z-order" fix used on Android.
            if let item = vm.selectedItem {
                DetailsView(
                    item: item,
                    onDismiss: { vm.clearSelectedItem() },
                    onPlayMovie: { vm.playMovie($0) },
                    onPlayEpisode: { vm.playEpisode($0, season: $1, episode: $2) },
                    onRepair: { _ in }
                )
                .transition(.move(edge: .bottom))
                .zIndex(10)
            }

            if let url = vm.playingURL {
                PlayerView(
                    url: url,
                    episodeLabel: vm.episodeContext.map { "الموسم \($0.season) • الحلقة \($0.episode)" },
                    hasNextEpisode: vm.hasNextEpisode,
                    onNextEpisode: { vm.playNextEpisode() },
                    onClose: { vm.stopPlayback() }
                )
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .environmentObject(vm)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: vm.selectedItem)
        .animation(.easeInOut(duration: 0.25), value: vm.playingURL)
    }

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { t in
                Button { tab = t } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon).font(.system(size: 20))
                        Text(t.label).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(tab == t ? AuroraColor.brandRed : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 10)
        .background(AuroraColor.surfaceDark, in: RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}

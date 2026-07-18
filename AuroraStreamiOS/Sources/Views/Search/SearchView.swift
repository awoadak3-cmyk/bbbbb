import SwiftUI

struct SearchView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var query = ""
    @State private var pool: [MediaItem] = []
    @State private var results: [MediaItem] = []
    @State private var loadingPool = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        ZStack {
            AuroraColor.deepBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.5))
                    TextField("", text: $query, prompt: Text("صيف ابدي").foregroundStyle(.white.opacity(0.4)))
                        .foregroundStyle(.white)
                        .onChange(of: query) { _, newValue in
                            results = vm.search(newValue, in: pool)
                        }
                }
                .padding(12)
                .background(AuroraColor.surfaceDark, in: RoundedRectangle(cornerRadius: 14))
                .padding()

                if loadingPool {
                    ProgressView().tint(AuroraColor.brandRed)
                    Spacer()
                } else if results.isEmpty && !query.isEmpty {
                    Spacer()
                    Text("ما فيه نتائج مطابقة").foregroundStyle(.white.opacity(0.5))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(results) { item in
                                Button { vm.selectItem(item) } label: {
                                    MediaCard(item: item, width: 110)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
        .task {
            loadingPool = true
            pool = await vm.searchPool()
            loadingPool = false
        }
    }
}

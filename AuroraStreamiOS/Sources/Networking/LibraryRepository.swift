import Foundation

actor LibraryRepository {
    private let dataService: GitHubDataService
    private var fileQueue: [String] = []
    private var allFilesCache: [String] = []
    private var searchCache: [MediaItem]?

    init(dataService: GitHubDataService) {
        self.dataService = dataService
    }

    var hasMoreFiles: Bool { !fileQueue.isEmpty }

    /// Step 1: pull data/index.json and reset internal batching state.
    func refreshIndex(repo: String, branch: String) async -> [String] {
        let files = await dataService.fetchIndex(repo: repo, branch: branch)
        let sorted = dataService.sortByTimestampDesc(files)
        allFilesCache = sorted
        fileQueue = sorted
        searchCache = nil
        return sorted
    }

    /// Step 2: pop up to `count` files off the queue and fetch them concurrently.
    func loadNextBatch(repo: String, branch: String, count: Int) async -> [MediaItem] {
        guard !fileQueue.isEmpty else { return [] }
        let take = min(count, fileQueue.count)
        let batch = Array(fileQueue.prefix(take))
        fileQueue.removeFirst(take)

        return await withTaskGroup(of: [MediaItem].self) { group in
            for file in batch {
                group.addTask { [dataService] in
                    await dataService.fetchFile(repo: repo, file: file, branch: branch)
                }
            }
            var all: [MediaItem] = []
            for await result in group { all.append(contentsOf: result) }
            return all
        }
    }

    /// Loads (and caches) every file for the global search feature.
    func loadAllForSearch(repo: String, branch: String) async -> [MediaItem] {
        if let searchCache { return searchCache }
        let files = allFilesCache.isEmpty ? await dataService.fetchIndex(repo: repo, branch: branch) : allFilesCache
        let all = await withTaskGroup(of: [MediaItem].self) { group in
            for file in files {
                group.addTask { [dataService] in
                    await dataService.fetchFile(repo: repo, file: file, branch: branch)
                }
            }
            var acc: [MediaItem] = []
            for await result in group { acc.append(contentsOf: result) }
            return acc
        }
        searchCache = all
        return all
    }

    nonisolated func searchLocally(query: String, pool: [MediaItem]) -> [MediaItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2 else { return [] }
        var seen = Set<Int>()
        var results: [MediaItem] = []
        for item in pool {
            let titleAr = (item.title ?? item.name ?? "").lowercased()
            let titleEn = (item.titleEn ?? "").lowercased()
            if titleAr.contains(q) || titleEn.contains(q) {
                if !seen.contains(item.id) {
                    seen.insert(item.id)
                    results.append(item)
                }
            }
        }
        return results
    }
}

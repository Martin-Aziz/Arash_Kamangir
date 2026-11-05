#if os(macOS)
import Foundation
import SwiftUI
import ArashCore

struct SavedPoem: Identifiable {
    let fullURL: String
    let title: String
    let poetName: String
    var id: String { fullURL }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var poets: [GanjoorPoet] = []
    @Published private(set) var selectedPoet: GanjoorPoet?
    @Published private(set) var category: GanjoorCategory?
    @Published private(set) var poem: GanjoorPoem?
    @Published private(set) var isLoading = false
    @Published private(set) var isDownloading = false
    @Published private(set) var importedPoets = Set<String>()
    @Published private(set) var downloadDone = 0
    @Published private(set) var downloadTotal = 0
    @Published private(set) var downloadMessage = ""
    @Published private(set) var bookmarks: Set<String>
    @Published private(set) var savedPoems: [SavedPoem] = []
    @Published private(set) var offlineRecords: [OfflinePoetRecord] = []
    @Published private(set) var isRemovingOfflinePoet = false
    @Published var errorMessage: String?

    private let client = GanjoorClient()
    private let library = GanjoorDiskLibrary()
    private var history: [GanjoorCategory] = []

    var canGoBack: Bool { !history.isEmpty }
    var hasSelectedPoetOffline: Bool {
        guard let selectedPoet else { return false }
        return importedPoets.contains(selectedPoet.slug)
    }

    init() {
        bookmarks = Set(UserDefaults.standard.stringArray(forKey: "bookmarkedPoems") ?? [])
    }

    func bootstrap() async {
        // The cached catalog keeps the app usable with no network.
        if let cached: GanjoorManifest = try? await library.load("manifest.json", as: GanjoorManifest.self) {
            poets = cached.poets
        }
        await refreshOfflineLibrary()
        await refreshCatalog(showError: poets.isEmpty)
        await refreshBookmarks()
    }

    func refreshCatalog(showError: Bool = true) async {
        do {
            let (manifest, data) = try await client.manifest()
            try await library.save(data, at: "manifest.json")
            poets = manifest.poets
        } catch {
            if showError { errorMessage = error.localizedDescription }
        }
    }

    func selectPoet(_ poet: GanjoorPoet) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let newCategory: GanjoorCategory = try await cachedOrRemote(
                GanjoorPath.category(poet.fullURL), as: GanjoorCategory.self)
            guard newCategory.fullURL == poet.fullURL else { throw GanjoorClientError.invalidData }
            selectedPoet = poet
            category = newCategory
            poem = nil
            history = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openCategory(_ entry: GanjoorEntry) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let next: GanjoorCategory = try await cachedOrRemote(
                GanjoorPath.category(entry.fullURL), as: GanjoorCategory.self)
            guard next.fullURL == entry.fullURL else { throw GanjoorClientError.invalidData }
            if let category { history.append(category) }
            category = next
            poem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goBack() {
        guard let previous = history.popLast() else { return }
        category = previous
        poem = nil
    }

    func openPoem(_ entry: GanjoorEntry) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let next: GanjoorPoem = try await cachedOrRemote(
                GanjoorPath.poem(entry.fullURL), as: GanjoorPoem.self)
            guard next.fullURL == entry.fullURL else { throw GanjoorClientError.invalidData }
            poem = next
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func downloadCurrentPoet() async {
        guard !isDownloading, let poet = selectedPoet else { return }
        isDownloading = true
        downloadTotal = 0
        downloadDone = 0
        downloadMessage = "Preparing offline library…"
        defer { isDownloading = false }
        do {
            try await GanjoorImporter(client: client, library: library)
                .importPoet(poet) { [weak self] completed, total in
                    Task { @MainActor [weak self] in
                        self?.downloadDone = completed
                        self?.downloadTotal = total
                        self?.downloadMessage = "Saving \(completed) / \(total) poems"
                    }
                }
            await refreshOfflineLibrary()
            downloadMessage = "Offline download complete."
        } catch is CancellationError {
            downloadMessage = "Download stopped. Already downloaded files are kept."
        } catch {
            downloadMessage = "Download interrupted. You can try again to resume."
            errorMessage = error.localizedDescription
        }
    }

    func refreshOfflineLibrary() async {
        do {
            let records = try await library.offlinePoetRecords()
            offlineRecords = records
            importedPoets = Set(records.map(\.slug))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeOfflinePoet(_ slug: String) async {
        // Avoid racing a download with deletion of the same directory.
        guard !isDownloading, !isRemovingOfflinePoet else { return }
        isRemovingOfflinePoet = true
        defer { isRemovingOfflinePoet = false }
        do {
            try await library.removeOfflinePoet(slug)
            await refreshOfflineLibrary()
            if selectedPoet?.slug == slug {
                downloadMessage = "Local copy removed. Online reading is still available."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshBookmarks() async {
        var records: [SavedPoem] = []
        for fullURL in bookmarks.sorted() {
            guard let segments = try? GanjoorPath.segments(fullURL),
                  segments.count >= 2,
                  let relative = try? GanjoorPath.poem(fullURL) else { continue }
            let cached: GanjoorPoem? = try? await library.load(relative, as: GanjoorPoem.self)
            let poetName = poets.first(where: { $0.slug == segments[0] })?.nickname ?? segments[0]
            records.append(SavedPoem(
                fullURL: fullURL,
                title: cached?.title ?? segments.last ?? fullURL,
                poetName: poetName
            ))
        }
        savedPoems = records
    }

    func openSavedPoem(_ fullURL: String) async {
        guard !isLoading else { return }
        guard let segments = try? GanjoorPath.segments(fullURL),
              segments.count >= 2,
              let poet = poets.first(where: { $0.slug == segments[0] }) else {
            errorMessage = "This bookmark has an invalid or unavailable poet."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let next: GanjoorPoem = try await cachedOrRemote(
                GanjoorPath.poem(fullURL), as: GanjoorPoem.self)
            guard next.fullURL == fullURL else { throw GanjoorClientError.invalidData }
            let parentURL = "/" + segments.dropLast().joined(separator: "/")
            let parent: GanjoorCategory = try await cachedOrRemote(
                GanjoorPath.category(parentURL), as: GanjoorCategory.self)
            guard parent.fullURL == parentURL else { throw GanjoorClientError.invalidData }
            selectedPoet = poet
            category = parent
            history = []
            poem = next
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBookmark(_ fullURL: String) {
        bookmarks.remove(fullURL)
        UserDefaults.standard.set(bookmarks.sorted(), forKey: "bookmarkedPoems")
        Task { await refreshBookmarks() }
    }

    func toggleBookmark() {
        guard let poem else { return }
        if !bookmarks.insert(poem.fullURL).inserted {
            bookmarks.remove(poem.fullURL)
        }
        UserDefaults.standard.set(bookmarks.sorted(), forKey: "bookmarkedPoems")
        Task { await refreshBookmarks() }
    }

    private func cachedOrRemote<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        if let cached: T = try await library.load(path, as: type) { return cached }
        let data = try await client.download(path)
        let value = try JSONDecoder().decode(type, from: data)
        try await library.save(data, at: path)
        return value
    }
}
#endif

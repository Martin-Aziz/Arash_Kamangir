#if os(macOS)
import Foundation
import SwiftUI
import ArashCore

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
        if let saved = try? await library.importedPoetSlugs() {
            importedPoets = saved
        }
        await refreshCatalog(showError: poets.isEmpty)
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
            importedPoets = try await library.importedPoetSlugs()
            downloadMessage = "Offline download complete."
        } catch is CancellationError {
            downloadMessage = "Download stopped. Already downloaded files are kept."
        } catch {
            downloadMessage = "Download interrupted. You can try again to resume."
            errorMessage = error.localizedDescription
        }
    }

    func toggleBookmark() {
        guard let poem else { return }
        if !bookmarks.insert(poem.fullURL).inserted {
            bookmarks.remove(poem.fullURL)
        }
        UserDefaults.standard.set(bookmarks.sorted(), forKey: "bookmarkedPoems")
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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum GanjoorClientError: LocalizedError {
    case badResponse
    case http(Int)
    case tooLarge
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .badResponse: return "The Ganjoor data server did not return an HTTP response."
        case .http(let code): return "The Ganjoor data server returned HTTP \(code)."
        case .tooLarge: return "The downloaded file exceeds the configured size limit."
        case .invalidData: return "A downloaded archive record does not match its requested path."
        }
    }
}

public struct GanjoorClient {
    /// Ganjoor's documented, static public export. Content is not bundled in the app.
    public static let officialBaseURL = URL(string: "https://cdn.jsdelivr.net/gh/ganjoor/ganjoor-data@main/")!
    public let baseURL: URL

    public init(baseURL: URL = GanjoorClient.officialBaseURL) {
        self.baseURL = baseURL
    }

    public func manifest() async throws -> (GanjoorManifest, Data) {
        let data = try await download("manifest.json")
        let manifest = try JSONDecoder().decode(GanjoorManifest.self, from: data)
        guard (1...4).contains(manifest.schemaVersion) else { throw GanjoorClientError.invalidData }
        return (manifest, data)
    }

    public func download(_ relativePath: String) async throws -> Data {
        guard GanjoorPath.isSafeRelative(relativePath),
              let url = URL(string: relativePath, relativeTo: baseURL)?.absoluteURL,
              url.scheme == "https" || (baseURL.isFileURL && url.isFileURL) else {
            throw ArchivePathError.unsafePath
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 35
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw GanjoorClientError.badResponse }
        guard (200...299).contains(response.statusCode) else { throw GanjoorClientError.http(response.statusCode) }
        guard data.count <= 20_000_000 else { throw GanjoorClientError.tooLarge }
        return data
    }
}

/// A completed offline poet and its actual storage footprint.
public struct OfflinePoetRecord: Identifiable, Equatable, Sendable {
    public let slug: String
    public let bytes: Int64
    public let fileCount: Int

    public var id: String { slug }

    public init(slug: String, bytes: Int64, fileCount: Int) {
        self.slug = slug
        self.bytes = bytes
        self.fileCount = fileCount
    }
}

/// A private, application-support data directory. No downloaded data is executed or rendered as HTML.
public actor GanjoorDiskLibrary {
    public let root: URL

    public init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ArashKam", isDirectory: true)
            .appendingPathComponent("GanjoorData", isDirectory: true)
    }

    /// Return raw bytes across the actor boundary. Callers decode on their own
    /// isolation domain, avoiding crossing a potentially actor-isolated Decodable
    /// conformance in Swift 6. The archive itself never executes any content.
    public func loadData(_ relative: String) throws -> Data? {
        let path = try fileURL(relative)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        return try Data(contentsOf: path)
    }

    public func load<T: Decodable>(_ relative: String, as type: T.Type) throws -> T? {
        guard let data = try loadData(relative) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    public func exists(_ relative: String) throws -> Bool {
        FileManager.default.fileExists(atPath: try fileURL(relative).path)
    }

    public func save(_ data: Data, at relative: String) throws {
        let path = try fileURL(relative)
        try FileManager.default.createDirectory(at: path.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: path, options: [.atomic])
    }

    public func importedPoetSlugs() throws -> Set<String> {
        let directory = try fileURL("completed")
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let contents = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        return Set(contents.compactMap { name in
            guard name.hasSuffix(".complete") else { return nil }
            let slug = String(name.dropLast(".complete".count))
            return GanjoorPath.isSafeRelative(slug) && !slug.contains("/") ? slug : nil
        })
    }

    public func markImported(_ poetSlug: String) throws {
        guard GanjoorPath.isSafeRelative(poetSlug), !poetSlug.contains("/") else {
            throw ArchivePathError.unsafePath
        }
        try save(Data(), at: "completed/\(poetSlug).complete")
    }

    /// Enumerate only complete offline poets; exclude partial/resumable downloads.
    public func offlinePoetRecords() throws -> [OfflinePoetRecord] {
        try importedPoetSlugs().sorted().map { slug in
            try validatePoetSlug(slug)
            let directory = try fileURL("poets/\(slug)")
            var bytes: Int64 = 0
            var count = 0
            if let iterator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let url as URL in iterator {
                    let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    guard values.isRegularFile == true else { continue }
                    bytes += Int64(values.fileSize ?? 0)
                    count += 1
                }
            }
            return OfflinePoetRecord(slug: slug, bytes: bytes, fileCount: count)
        }
    }

    /// Remove one explicitly chosen poet's local files and completion marker.
    /// It never touches the source manifest, other poets or user bookmarks.
    public func removeOfflinePoet(_ slug: String) throws {
        try validatePoetSlug(slug)
        // Refuse to traverse a symlinked archive root or a symlinked parent
        // directory, even if the final slug itself was lexically validated.
        for parent in [root,
                       root.appendingPathComponent("poets"),
                       root.appendingPathComponent("completed")] {
            if let values = try? parent.resourceValues(forKeys: [.isSymbolicLinkKey]),
               values.isSymbolicLink == true {
                throw ArchivePathError.unsafePath
            }
        }
        let directory = try fileURL("poets/\(slug)")
        let completion = try fileURL("completed/\(slug).complete")
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        if FileManager.default.fileExists(atPath: completion.path) {
            try FileManager.default.removeItem(at: completion)
        }
    }

    private func validatePoetSlug(_ slug: String) throws {
        guard GanjoorPath.isSafeRelative(slug), !slug.contains("/") else {
            throw ArchivePathError.unsafePath
        }
    }

    private func fileURL(_ relative: String) throws -> URL {
        guard GanjoorPath.isSafeRelative(relative) else { throw ArchivePathError.unsafePath }
        return root.appendingPathComponent(relative)
    }
}

/// Downloads one poet in full, then atomically writes its completion marker.
/// Partial downloads stay cached and can be safely resumed on retry.
public struct GanjoorImporter {
    public let client: GanjoorClient
    public let library: GanjoorDiskLibrary

    public init(client: GanjoorClient, library: GanjoorDiskLibrary) {
        self.client = client
        self.library = library
    }

    public func importPoet(_ poet: GanjoorPoet,
                           progress: @escaping (Int, Int) -> Void) async throws {
        let poetPath = try GanjoorPath.poet(poet.fullURL)
        let poetData = try await client.download(poetPath)
        try await library.save(poetData, at: poetPath)

        var pending = [poet.fullURL]
        var seen = Set<String>()
        var poems = Set<String>()

        while let fullURL = pending.popLast() {
            try Task.checkCancellation()
            guard seen.insert(fullURL).inserted else { continue }
            guard seen.count <= 10_000 else { throw GanjoorClientError.invalidData }
            let path = try GanjoorPath.category(fullURL)
            let data = try await client.download(path)
            let category = try JSONDecoder().decode(GanjoorCategory.self, from: data)
            guard category.fullURL == fullURL else { throw GanjoorClientError.invalidData }
            try await library.save(data, at: path)
            for child in category.childCategories {
                guard child.fullURL == poet.fullURL ||
                      child.fullURL.hasPrefix(poet.fullURL + "/") else {
                    throw GanjoorClientError.invalidData
                }
                pending.append(child.fullURL)
            }
            for item in category.poems {
                guard item.fullURL.hasPrefix(poet.fullURL + "/") else {
                    throw GanjoorClientError.invalidData
                }
                poems.insert(try GanjoorPath.poem(item.fullURL))
            }
        }

        let files = poems.sorted()
        var finished = 0
        progress(finished, files.count)

        // Bounded parallelism avoids creating thousands of simultaneous network requests.
        for start in stride(from: 0, to: files.count, by: 6) {
            try Task.checkCancellation()
            let end = min(start + 6, files.count)
            try await withThrowingTaskGroup(of: Void.self) { group in
                for path in files[start..<end] {
                    group.addTask {
                        try Task.checkCancellation()
                        if try await library.exists(path) { return }
                        let data = try await client.download(path)
                        let poem = try JSONDecoder().decode(GanjoorPoem.self, from: data)
                        guard try GanjoorPath.poem(poem.fullURL) == path else {
                            throw GanjoorClientError.invalidData
                        }
                        try await library.save(data, at: path)
                    }
                }
                for try await _ in group {
                    finished += 1
                    progress(finished, files.count)
                }
            }
        }
        try Task.checkCancellation()
        try await library.markImported(poet.slug)
    }
}

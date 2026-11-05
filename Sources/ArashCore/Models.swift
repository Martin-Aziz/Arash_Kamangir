import Foundation

/// Decoded from Ganjoor's public ganjoor-data manifest, not the historical .s3db schema.
public struct GanjoorManifest: Decodable {
    public let schemaVersion: Int
    public let generatedAtUTC: String
    public let poets: [GanjoorPoet]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "SchemaVersion"
        case generatedAtUTC = "GeneratedAtUtc"
        case poets = "Poets"
    }
}

public struct GanjoorPoet: Decodable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let nickname: String
    public let fullURL: String

    public var slug: String { String(fullURL.dropFirst()) }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case nickname = "Nickname"
        case fullURL = "FullUrl"
    }
}

public struct GanjoorEntry: Decodable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let fullURL: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case title = "Title"
        case fullURL = "FullUrl"
    }
}

public struct GanjoorCategory: Decodable, Identifiable {
    public let id: Int
    public let title: String
    public let fullURL: String
    public let childCategories: [GanjoorEntry]
    public let poems: [GanjoorEntry]

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case title = "Title"
        case fullURL = "FullUrl"
        case childCategories = "ChildCats"
        case poems = "Poems"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        fullURL = try container.decode(String.self, forKey: .fullURL)
        childCategories = try container.decodeIfPresent([GanjoorEntry].self, forKey: .childCategories) ?? []
        poems = try container.decodeIfPresent([GanjoorEntry].self, forKey: .poems) ?? []
    }
}

public struct GanjoorVerse: Decodable, Identifiable {
    public let order: Int
    public let position: String?
    public let text: String
    public let coupletIndex: Int?

    public var id: Int { order }

    enum CodingKeys: String, CodingKey {
        case order = "VOrder"
        case position = "Position"
        case text = "Text"
        case coupletIndex = "CoupletIndex"
    }
}

public struct GanjoorPoem: Decodable, Identifiable {
    public let id: Int
    public let title: String
    public let fullTitle: String?
    public let fullURL: String
    public let verses: [GanjoorVerse]

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case title = "Title"
        case fullTitle = "FullTitle"
        case fullURL = "FullUrl"
        case verses = "Verses"
    }

    /// The category row is the authoritative selection target. Never display a
    /// cached or downloaded poem whose identity differs from the tapped row.
    public func matches(_ entry: GanjoorEntry) -> Bool {
        id == entry.id && fullURL == entry.fullURL
    }

    public var orderedVerses: [GanjoorVerse] { verses.sorted { $0.order < $1.order } }
    public var plainText: String { orderedVerses.map(\.text).joined(separator: "\n") }

    /// Preserve the original half-lines and their ordering, including single-line verse.
    public var readingGroups: [VerseGroup] {
        var groups: [VerseGroup] = []
        for verse in orderedVerses {
            if let index = verse.coupletIndex,
               let last = groups.indices.last,
               groups[last].coupletIndex == index {
                groups[last].verses.append(verse)
            } else {
                groups.append(VerseGroup(id: verse.order, coupletIndex: verse.coupletIndex, verses: [verse]))
            }
        }
        return groups
    }
}

public struct VerseGroup: Identifiable {
    public let id: Int
    public let coupletIndex: Int?
    public var verses: [GanjoorVerse]
}

public enum ArchivePathError: LocalizedError {
    case unsafePath

    public var errorDescription: String? { "The archive contains an invalid or unsafe content path." }
}

/// Only relative, slug-based paths are accepted. Never interpolate an untrusted URL directly.
public enum GanjoorPath {
    public static func segments(_ fullURL: String) throws -> [String] {
        guard fullURL.hasPrefix("/"), !fullURL.hasPrefix("//") else { throw ArchivePathError.unsafePath }
        let parts = fullURL.split(separator: "/", omittingEmptySubsequences: false).dropFirst().map(String.init)
        guard !parts.isEmpty, parts.allSatisfy(isSlug) else { throw ArchivePathError.unsafePath }
        return parts
    }

    public static func poet(_ fullURL: String) throws -> String {
        let parts = try segments(fullURL)
        guard parts.count == 1 else { throw ArchivePathError.unsafePath }
        return "poets/\(parts[0])/poet.json"
    }

    public static func category(_ fullURL: String) throws -> String {
        "poets/" + (try segments(fullURL)).joined(separator: "/") + "/_cat.json"
    }

    public static func poem(_ fullURL: String) throws -> String {
        let parts = try segments(fullURL)
        guard parts.count >= 2 else { throw ArchivePathError.unsafePath }
        return "poets/" + parts.joined(separator: "/") + ".json"
    }

    public static func isSafeRelative(_ relative: String) -> Bool {
        guard !relative.hasPrefix("/"), !relative.contains("\\"), !relative.contains("%") else { return false }
        let parts = relative.split(separator: "/", omittingEmptySubsequences: false)
        return !parts.isEmpty && parts.allSatisfy { part in
            !part.isEmpty && part != "." && part != ".." &&
            part.unicodeScalars.allSatisfy { scalar in
                let c = scalar.value
                return (65...90).contains(c) || (97...122).contains(c) ||
                       (48...57).contains(c) || c == 45 || c == 95 || c == 46
            }
        }
    }

    private static func isSlug(_ value: String) -> Bool {
        !value.isEmpty && value.unicodeScalars.allSatisfy { scalar in
            let c = scalar.value
            return (65...90).contains(c) || (97...122).contains(c) ||
                   (48...57).contains(c) || c == 45 || c == 95
        }
    }
}

public enum PersianNormalizer {
    /// For title filtering. Full-text indexing will use this same normalization in a later phase.
    public static func normalize(_ text: String) -> String {
        let replacements: [Character: Character] = ["ي": "ی", "ى": "ی", "ك": "ک", "ۀ": "ه"]
        let scalars = String(text.map { replacements[$0] ?? $0 })
        let cleaned = scalars.unicodeScalars.filter {
            let n = $0.value
            return !(0x064B...0x065F).contains(n) &&
                   n != 0x0670 && !(0x06D6...0x06ED).contains(n) &&
                   n != 0x200C && n != 0x200D && n != 0x0640
        }
        return String(String.UnicodeScalarView(cleaned)).lowercased()
    }

    public static func contains(_ text: String, query: String) -> Bool {
        let needle = normalize(query).trimmingCharacters(in: .whitespacesAndNewlines)
        return needle.isEmpty || normalize(text).contains(needle)
    }
}

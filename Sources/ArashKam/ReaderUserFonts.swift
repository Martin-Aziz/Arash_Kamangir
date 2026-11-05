#if os(macOS)
import AppKit
import CoreText
import Foundation
import ArashCore

enum ReaderFontImportError: LocalizedError {
    case unsupported
    case invalidFile
    case tooLarge
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .unsupported: return "Choose a .ttf, .otf or .ttc font."
        case .invalidFile: return "The selected font file is unavailable or not a regular file."
        case .tooLarge: return "Font files must be 16 MB or smaller."
        case .registrationFailed: return "macOS could not register this font."
        }
    }
}

/// User-picked font binaries are copied to user-private Application Support,
/// registered only in this process, and NEVER committed or redistributed.
enum ReaderUserFonts {
    private static let allowedExtensions: Set<String> = ["ttf", "otf", "ttc"]
    private static let maxSize: Int64 = 16 * 1_024 * 1_024

    static func directory(applicationSupport: URL? = nil, bundleID: String? = nil) -> URL {
        let support = applicationSupport ??
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let identity = bundleID ?? Bundle.main.bundleIdentifier
        return GanjoorLibraryLocation.userFontRoot(
            applicationSupport: support, bundleID: identity)
    }

    static func registerExisting() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory(), includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey])) ?? []
        for file in files where allowedExtensions.contains(file.pathExtension.lowercased()) {
            if isSafeRegularFile(file) {
                _ = CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
            }
        }
    }

    static func importUserFont(_ source: URL) throws {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }

        let ext = source.pathExtension.lowercased()
        guard allowedExtensions.contains(ext) else { throw ReaderFontImportError.unsupported }
        guard isSafeRegularFile(source) else { throw ReaderFontImportError.invalidFile }

        let folder = directory()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appendingPathComponent(UUID().uuidString + "." + ext)
        try FileManager.default.copyItem(at: source, to: destination)
        guard CTFontManagerRegisterFontsForURL(destination as CFURL, .process, nil) else {
            try? FileManager.default.removeItem(at: destination)
            throw ReaderFontImportError.registrationFailed
        }
    }

    private static func isSafeRegularFile(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(
            forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
              values.isRegularFile == true,
              values.isSymbolicLink != true,
              let bytes = values.fileSize else { return false }
        return bytes > 0 && Int64(bytes) <= maxSize
    }
}
#endif

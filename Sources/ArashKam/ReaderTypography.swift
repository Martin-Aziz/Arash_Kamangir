#if os(macOS)
import AppKit
import CoreText
import SwiftUI

enum ReaderPageStyle: String, CaseIterable, Identifiable {
    case minimal
    case illuminated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minimal: return "Quiet · ساده"
        case .illuminated: return "Illuminated · تذهیب"
        }
    }
}

struct ReaderFontChoice: Identifiable, Hashable {
    let name: String // Exact PostScript name, not font-family display name.
    let label: String
    var id: String { name }
}

/// Discover fonts the person installed in Font Book, including local typefaces
/// not committed to the repository. Never ship or copy third-party font binaries.
enum ReaderFontCatalog {
    private static let preferred = [
        "IranNastaliq", "NotoNastaliqUrdu", "Amiri",
        "Vazirmatn", "Estedad", "Shabnam", "Sahel",
        "Samim", "Parastoo", "GeezaPro", "AlNile"
    ]

    static func available() -> [ReaderFontChoice] {
        let names = NSFontManager.shared.availableFonts
        return names.filter(supportsPersian)
            .map { name in
                let font = NSFont(name: name, size: 24)
                let family = font?.familyName ?? name
                let descriptor = name == family ? family : "\(family) — \(name)"
                return ReaderFontChoice(name: name, label: descriptor)
            }
            .sorted { lhs, rhs in
                let a = rank(lhs.name)
                let b = rank(rhs.name)
                if a != b { return a < b }
                return lhs.label.localizedStandardCompare(rhs.label) == .orderedAscending
            }
    }

    static func isAvailable(_ name: String) -> Bool {
        !name.isEmpty && supportsPersian(name)
    }

    static func font(_ name: String, size: CGFloat) -> Font {
        if isAvailable(name) { return .custom(name, fixedSize: size) }
        return .system(size: size, design: .serif)
    }

    private static func rank(_ name: String) -> Int {
        let normalized = name.lowercased().filter { $0.isLetter || $0.isNumber }
        return preferred.firstIndex(where: {
            normalized.contains($0.lowercased())
        }) ?? preferred.count
    }

    private static func supportsPersian(_ postScriptName: String) -> Bool {
        guard NSFont(name: postScriptName, size: 24) != nil else { return false }
        // Require distinct Persian letters, not only Arabic/Latin coverage.
        let font = CTFontCreateWithName(postScriptName as CFString, 24, nil)
        var characters = Array("پژگچسی".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        return characters.withUnsafeMutableBufferPointer { chars in
            glyphs.withUnsafeMutableBufferPointer { output in
                guard let c = chars.baseAddress, let g = output.baseAddress else { return false }
                return CTFontGetGlyphsForCharacters(font, c, g, chars.count)
            }
        }
    }
}
#endif

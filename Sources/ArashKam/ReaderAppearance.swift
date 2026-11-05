#if os(macOS)
import SwiftUI
import AppKit

/// The page is a quiet, legible reading surface. Liquid Glass is reserved for
/// controls; historical palette references are expressed as original colors.
enum ReaderAppearance: String, CaseIterable, Identifiable {
    case system
    case paper
    case night
    case rose
    case lapis
    case jade

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .paper: return "Ivory · عاجی"
        case .night: return "Midnight · شب"
        case .rose: return "Rose · گل‌سرخ"
        case .lapis: return "Lapis · لاجورد"
        case .jade: return "Jade · یشم"
        }
    }

    /// Surrounding desktop-style surface, separate from the paper itself.
    var background: Color {
        switch self {
        case .system: return Color(nsColor: .windowBackgroundColor)
        case .paper: return Color(red: 0.92, green: 0.88, blue: 0.79)
        case .night: return Color(red: 0.075, green: 0.09, blue: 0.13)
        case .rose: return Color(red: 0.94, green: 0.86, blue: 0.84)
        case .lapis: return Color(red: 0.08, green: 0.17, blue: 0.30)
        case .jade: return Color(red: 0.82, green: 0.88, blue: 0.83)
        }
    }

    var page: Color {
        switch self {
        case .system: return Color(nsColor: .textBackgroundColor)
        case .paper: return Color(red: 0.985, green: 0.963, blue: 0.911)
        case .night: return Color(red: 0.12, green: 0.15, blue: 0.20)
        case .rose: return Color(red: 0.996, green: 0.957, blue: 0.938)
        case .lapis: return Color(red: 0.12, green: 0.23, blue: 0.36)
        case .jade: return Color(red: 0.955, green: 0.971, blue: 0.927)
        }
    }

    var foreground: Color {
        switch self {
        case .system: return .primary
        case .paper: return Color(red: 0.19, green: 0.16, blue: 0.13)
        case .night: return Color(red: 0.95, green: 0.92, blue: 0.86)
        case .rose: return Color(red: 0.30, green: 0.16, blue: 0.19)
        case .lapis: return Color(red: 0.98, green: 0.95, blue: 0.86)
        case .jade: return Color(red: 0.15, green: 0.25, blue: 0.20)
        }
    }

    var ornament: Color {
        switch self {
        case .system: return Color(nsColor: .secondaryLabelColor)
        case .paper: return Color(red: 0.59, green: 0.43, blue: 0.21)
        case .night: return Color(red: 0.76, green: 0.61, blue: 0.39)
        case .rose: return Color(red: 0.66, green: 0.33, blue: 0.36)
        case .lapis: return Color(red: 0.87, green: 0.69, blue: 0.40)
        case .jade: return Color(red: 0.38, green: 0.54, blue: 0.41)
        }
    }

    var linkTint: Color {
        switch self {
        case .system: return .accentColor
        case .paper: return Color(red: 0.48, green: 0.27, blue: 0.16)
        case .night: return Color(red: 0.85, green: 0.72, blue: 0.48)
        case .rose: return Color(red: 0.51, green: 0.19, blue: 0.30)
        case .lapis: return Color(red: 0.98, green: 0.77, blue: 0.49)
        case .jade: return Color(red: 0.19, green: 0.43, blue: 0.31)
        }
    }
}
#endif

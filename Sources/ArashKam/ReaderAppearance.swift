#if os(macOS)
import SwiftUI
import AppKit

enum ReaderAppearance: String, CaseIterable, Identifiable {
    case system
    case paper
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .paper: return "Paper"
        case .night: return "Night"
        }
    }

    var background: Color {
        switch self {
        case .system: return Color(nsColor: .textBackgroundColor)
        case .paper: return Color(red: 0.975, green: 0.955, blue: 0.91)
        case .night: return Color(red: 0.10, green: 0.12, blue: 0.15)
        }
    }

    var foreground: Color {
        switch self {
        case .system: return .primary
        case .paper: return Color(red: 0.22, green: 0.19, blue: 0.16)
        case .night: return Color(red: 0.94, green: 0.93, blue: 0.89)
        }
    }

    var linkTint: Color {
        switch self {
        case .system: return .accentColor
        case .paper: return Color(red: 0.47, green: 0.27, blue: 0.13)
        case .night: return Color(red: 0.66, green: 0.79, blue: 0.98)
        }
    }
}
#endif

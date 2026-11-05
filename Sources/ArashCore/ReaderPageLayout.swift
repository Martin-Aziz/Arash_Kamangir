import Foundation

/// Sizes the manuscript within its actual viewport, including outer margins.
public struct ReaderPageLayout {
    public let pageWidth: Double
    public let innerPadding: Double
    public let outerPadding: Double

    public init(viewportWidth: Double, preferredWidth: Double, illuminated: Bool) {
        let viewport = max(0, viewportWidth)
        outerPadding = min(18, viewport / 4)
        pageWidth = min(max(0, preferredWidth), max(0, viewport - 2 * outerPadding))
        let desiredPadding: Double = illuminated ? (pageWidth >= 630 ? 52 : 26) : 24
        innerPadding = min(desiredPadding, pageWidth / 4)
    }
}

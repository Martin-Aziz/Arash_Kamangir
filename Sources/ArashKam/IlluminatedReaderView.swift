#if os(macOS)
import SwiftUI
import ArashCore

/// A clean literary page. The decorative borders are views, not manuscript
/// raster images; verses retain copyability and VoiceOver access.
struct IlluminatedReaderView: View {
    let poem: GanjoorPoem
    let poetName: String
    let collectionName: String
    let appearance: ReaderAppearance
    let style: ReaderPageStyle
    let fontName: String
    let fontSize: Double
    let lineSpacing: Double
    let contentWidth: Double

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 22) {
                    if style == .illuminated {
                        ArashMark(color: appearance.ornament)
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                    }

                    VStack(spacing: 7) {
                        Text(poetName)
                            .font(ReaderFontCatalog.font(fontName, size: 18))
                            .foregroundStyle(appearance.ornament)
                        if !collectionName.isEmpty {
                            Text(collectionName)
                                .font(.caption)
                                .foregroundStyle(appearance.ornament.opacity(0.9))
                        }
                        Text(poem.title)
                            .font(ReaderFontCatalog.font(fontName, size: CGFloat(fontSize + 9)))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("reader-poem-title")
                            .accessibilityValue(Text(poem.fullURL))
                    }
                    .frame(maxWidth: .infinity)

                    ManuscriptDivider(color: appearance.ornament)
                        .padding(.horizontal, 16)

                    VStack(spacing: 22 + lineSpacing) {
                        ForEach(poem.readingGroups) { group in
                            if group.verses.count == 2 &&
                                group.verses[0].position == "Right" &&
                                group.verses[1].position == "Left" {
                                couplet(group.verses, in: geometry.size.width)
                            } else {
                                VStack(alignment: .trailing, spacing: 10) {
                                    ForEach(group.verses) { verse in
                                        verseText(verse.text)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                            }
                        }
                    }
                    .padding(.top, 10)

                    ManuscriptDivider(color: appearance.ornament)
                        .padding(.top, 10)
                        .padding(.horizontal, 16)

                    if let source = URL(string: "https://ganjoor.net" + poem.fullURL) {
                        Link("مشاهده در گنجور · Original source", destination: source)
                            .font(.caption)
                            .padding(.top, 2)
                    }
                }
                .foregroundStyle(appearance.foreground)
                .tint(appearance.linkTint)
                .frame(maxWidth: max(480, contentWidth - 112))
                .padding(.horizontal, style == .illuminated ? 55 : 27)
                .padding(.top, style == .illuminated ? 52 : 32)
                .padding(.bottom, style == .illuminated ? 65 : 40)
                .background(appearance.page)
                .overlay {
                    if style == .illuminated {
                        ManuscriptFrame(color: appearance.ornament)
                    }
                }
                .frame(maxWidth: contentWidth)
                .padding(.vertical, 30)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .accessibilityIdentifier("poetry-scroll-view")
        }
        .background(appearance.background)
    }

    @ViewBuilder
    private func couplet(_ verses: [GanjoorVerse], in availableWidth: CGFloat) -> some View {
        // At narrow widths each hemistich gets its own line rather than
        // squeezing a two-column layout into an unreadable column.
        if availableWidth >= 820 && fontSize <= 31 {
            HStack(alignment: .firstTextBaseline, spacing: 28) {
                verseText(verses[0].text)
                verseText(verses[1].text)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .trailing, spacing: 8) {
                verseText(verses[0].text)
                verseText(verses[1].text)
                    .padding(.trailing, 22)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func verseText(_ value: String) -> some View {
        Text(value)
            .font(ReaderFontCatalog.font(fontName, size: CGFloat(fontSize)))
            .multilineTextAlignment(.trailing)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(value)
    }
}
#endif

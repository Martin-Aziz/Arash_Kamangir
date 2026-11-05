#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers
import ArashCore

/// A small memento of a *real* poem, with the original Ganjoor attribution.
/// This intentionally does not generate or rewrite poetry.
struct PoetryKeepsakeCard: View {
    let poem: GanjoorPoem
    let poetName: String
    let verses: [String]
    let appearance: ReaderAppearance
    let fontName: String
    let template: ManuscriptTemplate

    var body: some View {
        VStack(spacing: 30) {
            PersianIlluminatedHeadpiece(template: template)
                .frame(height: 176)
                .padding(.horizontal, 1)
                .accessibilityHidden(true)

            Text("یادگار شعر")
                .font(ReaderFontCatalog.font(fontName, size: 28))
                .foregroundStyle(appearance.ornament)

            Spacer(minLength: 12)

            VStack(spacing: 23) {
                ForEach(verses.indices, id: \.self) { i in
                    Text(verses[i])
                        .font(ReaderFontCatalog.font(fontName, size: 35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(13)
                        .lineLimit(6)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .environment(\.layoutDirection, .rightToLeft)
                }
            }
            .frame(maxWidth: 620)
            .accessibilityElement(children: .combine)

            Spacer(minLength: 12)

            ManuscriptDivider(color: appearance.ornament)

            VStack(spacing: 5) {
                Text(poetName)
                    .font(ReaderFontCatalog.font(fontName, size: 24))
                Text(poem.title)
                    .font(ReaderFontCatalog.font(fontName, size: 18))
            }
            .foregroundStyle(appearance.foreground)

            Text("ganjoor.net\(poem.fullURL)")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(appearance.ornament)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 64)
        .frame(width: 720, height: 900)
        .background(appearance.page)
        .overlay {
            PersianIlluminatedFrame(template: template)
        }
        .foregroundStyle(appearance.foreground)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct PoetryKeepsakeSheet: View {
    let poem: GanjoorPoem
    let poetName: String
    let appearance: ReaderAppearance
    let fontName: String
    let template: ManuscriptTemplate

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0
    @State private var errorMessage: String?

    private var groups: [VerseGroup] {
        poem.readingGroups.filter { !$0.verses.isEmpty }
    }

    private var selectedVerses: [String] {
        guard !groups.isEmpty else { return [] }
        let safeIndex = min(max(0, selectedIndex), groups.count - 1)
        return Array(groups[safeIndex].verses.prefix(2)).map(\.text)
    }

    private var card: PoetryKeepsakeCard {
        PoetryKeepsakeCard(
            poem: poem,
            poetName: poetName,
            verses: selectedVerses,
            appearance: appearance,
            fontName: fontName,
            template: template)
    }

    var body: some View {
        VStack(spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A little piece of poetry")
                        .font(.title3.weight(.semibold))
                    Text("یادگار شعر · Choose a real couplet to keep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 22)
            .padding(.top, 19)

            HStack(spacing: 16) {
                Button {
                    selectedIndex = max(0, selectedIndex - 1)
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(selectedIndex == 0)
                .accessibilityIdentifier("keepsake-previous-couplet")

                Spacer()

                Text(groups.isEmpty
                     ? "No verses in this poem"
                     : "بیت \(selectedIndex + 1) از \(groups.count)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .accessibilityIdentifier("keepsake-couplet-position")

                Spacer()

                Button {
                    selectedIndex = min(groups.count - 1, selectedIndex + 1)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(groups.isEmpty || selectedIndex >= groups.count - 1)
                .accessibilityIdentifier("keepsake-next-couplet")
            }
            .padding(.horizontal, 24)

            ScrollView([.vertical, .horizontal]) {
                card
                    .scaleEffect(0.58, anchor: .topLeading)
                    .frame(width: 418, height: 522, alignment: .topLeading)
                    .padding(12)
            }
            .accessibilityIdentifier("poetry-keepsake-preview")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(appearance.background.opacity(0.55))

            HStack(spacing: 12) {
                Button {
                    let copy = selectedVerses.joined(separator: "\n")
                        + "\n— \(poetName), \(poem.title)"
                        + "\nhttps://ganjoor.net\(poem.fullURL)"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(copy, forType: .string)
                } label: {
                    Label("Copy with attribution", systemImage: "doc.on.doc")
                }
                .disabled(groups.isEmpty)

                Spacer()

                Button {
                    savePNG()
                } label: {
                    Label("Save PNG…", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(groups.isEmpty)
                .accessibilityIdentifier("keepsake-save-png")
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
        .frame(width: 550, height: 760)
        .alert("Could not create keepsake", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func savePNG() {
        // The native renderer creates a full-size, 2x image of the original
        // SwiftUI card. It does not capture unrelated desktop windows.
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.0
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            errorMessage = "The poem could not be rendered to an image."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Arash-\(poem.id)-couplet-\(selectedIndex + 1).png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try png.write(to: url, options: .atomic)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif

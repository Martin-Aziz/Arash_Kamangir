#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ArashCore

@main
struct ArashKamApp: App {
    var body: some Scene {
        WindowGroup("آرش کمانگیر") {
            LibraryWindow()
                .frame(minWidth: 920, minHeight: 600)
        }
        .defaultSize(width: 1220, height: 780)
    }
}

struct LibraryWindow: View {
    @StateObject private var model = AppModel()
    @State private var poetSearch = ""
    @State private var contentSearch = ""
    @State private var downloadTask: Task<Void, Never>?
    @State private var downloadedOnly = false
    @State private var showingLibraryManager = false
    @State private var showingBookmarks = false
    @State private var showingReadingSettings = false
    @State private var splitVisibility: NavigationSplitViewVisibility = .all
    @State private var showingFilesSettings = false
    @State private var fontQuery = ""
    @State private var installedPersianFonts: [ReaderFontChoice] = []
    @AppStorage("readerFontPostScriptName") private var readerFontName = ""
    @AppStorage("readerPageStyle") private var readerPageStyle = ReaderPageStyle.illuminated.rawValue
    @AppStorage("readerFontSize") private var fontSize = 24.0
    @AppStorage("readerLineSpacing") private var lineSpacing = 5.0
    @AppStorage("readerContentWidth") private var readerContentWidth = 820.0
    @AppStorage("readerTheme") private var readerTheme = ReaderAppearance.paper.rawValue

    private var pageStyle: ReaderPageStyle {
        ReaderPageStyle(rawValue: readerPageStyle) ?? .illuminated
    }

    private var matchingFonts: [ReaderFontChoice] {
        guard !fontQuery.isEmpty else { return installedPersianFonts }
        return installedPersianFonts.filter {
            $0.label.localizedCaseInsensitiveContains(fontQuery) ||
            $0.name.localizedCaseInsensitiveContains(fontQuery)
        }
    }

    private func refreshFonts() {
        installedPersianFonts = ReaderFontCatalog.available()
    }

    private var readerAppearance: ReaderAppearance {
        ReaderAppearance(rawValue: readerTheme) ?? .system
    }

    private var visiblePoets: [GanjoorPoet] {
        model.poets.filter {
            (!downloadedOnly || model.importedPoets.contains($0.slug))
                && PersianNormalizer.contains($0.nickname, query: poetSearch)
        }
    }
    private var visibleCategories: [GanjoorEntry] {
        (model.category?.childCategories ?? []).filter {
            PersianNormalizer.contains($0.title, query: contentSearch)
        }
    }
    private var visiblePoems: [GanjoorEntry] {
        (model.category?.poems ?? []).filter {
            PersianNormalizer.contains($0.title, query: contentSearch)
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $splitVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 210, ideal: 245, max: 350)
        } content: {
            collection
                .navigationSplitViewColumnWidth(min: 245, ideal: 310, max: 450)
        } detail: {
            reader
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            showingReadingSettings.toggle()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .help("Poetry appearance and fonts")
                        .popover(isPresented: $showingReadingSettings, arrowEdge: .bottom) {
                            readingSettings
                        }

                        Button {
                            splitVisibility = splitVisibility == .detailOnly ? .all : .detailOnly
                        } label: {
                            Image(systemName: splitVisibility == .detailOnly ?
                                  "sidebar.left" : "book.closed")
                        }
                        .help(splitVisibility == .detailOnly ?
                              "Show library columns" : "Focus on the poem")
                        .accessibilityIdentifier("toggle-poetry-focus")

                        Button {
                            showingFilesSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .help("Library, import and export")
                        .accessibilityIdentifier("open-library-files-settings")

                        Button {
                            fontSize = max(17, fontSize - 2)
                        } label: { Image(systemName: "textformat.size.smaller") }
                            .help("Smaller Persian text")

                        Button {
                            fontSize = min(42, fontSize + 2)
                        } label: { Image(systemName: "textformat.size.larger") }
                            .help("Larger Persian text")

                        if let poem = model.poem {
                            Button {
                                model.toggleBookmark()
                            } label: {
                                Image(systemName: model.bookmarks.contains(poem.fullURL)
                                      ? "bookmark.fill" : "bookmark")
                            }
                            .help("Bookmark this poem")

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(poem.plainText, forType: .string)
                            } label: { Image(systemName: "doc.on.doc") }
                                .help("Copy poem text")
                        }
                    }
                }
        }
        .navigationTitle("آرش کمانگیر")
        .task { await model.bootstrap() }
        .onAppear(perform: refreshFonts)
        .sheet(isPresented: $showingFilesSettings) {
            LibraryFilesSettings(
                model: model,
                startDownload: {
                    downloadTask = Task { await model.downloadCurrentPoet() }
                },
                stopDownload: { downloadTask?.cancel() },
                exportCurrentPoem: exportCurrentPoem)
        }
        .sheet(isPresented: $showingLibraryManager) {
            LibraryManagerView(model: model)
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarksView(model: model)
        }
        .alert("Arash Kamangir", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ArashMark(color: readerAppearance.ornament)
                    .frame(width: 30, height: 30)
                    .help("Arash the Archer · آرش کمانگیر")
                VStack(alignment: .leading, spacing: 1) {
                    Text("آرش کمانگیر").font(.headline)
                    Text("Persian Poetry Library")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if Bundle.main.bundleIdentifier == GanjoorLibraryLocation.qaBundleID {
                        Label("QA build · Isolated data", systemImage: "checkmark.shield")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("qa-isolated-bundle")
                    }
                }
                Spacer()
                Button {
                    Task { await model.refreshCatalog() }
                } label: { Image(systemName: "arrow.clockwise") }
                    .help("Refresh the official Ganjoor catalog")
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 12)

            TextField("Find a poet · جستجوی شاعر", text: $poetSearch)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.bottom, 7)

            Toggle(isOn: $downloadedOnly) {
                Label("Downloaded only", systemImage: "arrow.down.circle")
                    .font(.caption)
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            List {
                Section("Poets · شاعران") {
                    ForEach(visiblePoets) { poet in
                        Button {
                            contentSearch = ""
                            Task { await model.selectPoet(poet) }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.crop.circle")
                                    .foregroundStyle(.secondary)
                                Text(poet.nickname)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                if model.importedPoets.contains(poet.slug) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .help("Available offline")
                                }
                            }
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(model.selectedPoet?.id == poet.id
                                           ? Color.accentColor.opacity(0.12) : Color.clear)
                    }
                }
            }
            .listStyle(.sidebar)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(model.importedPoets.count) poets downloaded for offline reading")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    showingBookmarks = true
                } label: {
                    Label("Saved poetry (\(model.bookmarks.count))", systemImage: "bookmark")
                }
                .accessibilityIdentifier("open-saved-poetry")
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showingLibraryManager = true
                } label: {
                    Label("Manage offline library", systemImage: "externaldrive")
                }
                .accessibilityIdentifier("open-offline-library")
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
                Link("Source: Ganjoor", destination: URL(string: "https://ganjoor.net")!)
                    .font(.caption)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var collection: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.goBack()
                } label: { Image(systemName: "chevron.left") }
                    .disabled(!model.canGoBack || model.isLoading)
                    .help("Back to previous collection")
                Spacer(minLength: 5)
                Text(model.category?.title ?? "کتابخانه")
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(13)

            if model.category != nil {
                TextField("Filter titles · جستجو", text: $contentSearch)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                List {
                    if !visibleCategories.isEmpty {
                        Section("Collections · مجموعه‌ها") {
                            ForEach(visibleCategories) { entry in
                                Button {
                                    contentSearch = ""
                                    Task { await model.openCategory(entry) }
                                } label: {
                                    HStack {
                                        Image(systemName: "folder")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(entry.title)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(model.isLoading)
                                .accessibilityIdentifier("category-row-\(entry.id)")
                            }
                        }
                    }
                    if !visiblePoems.isEmpty {
                        Section("Poems · شعرها") {
                            ForEach(visiblePoems) { entry in
                                Button {
                                    Task { await model.openPoem(entry) }
                                } label: {
                                    HStack {
                                        if model.bookmarks.contains(entry.fullURL) {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(entry.title)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                                .disabled(model.isLoading)
                                .accessibilityLabel(Text(entry.title))
                                .accessibilityIdentifier("poem-row-\(entry.id)")
                                .accessibilityHint(Text("Opens \(entry.title)"))
                                .listRowBackground(
                                    model.poem?.fullURL == entry.fullURL
                                        ? Color.accentColor.opacity(0.10) : Color.clear)
                            }
                        }
                    }
                }
                .listStyle(.inset)
                Text("Filters titles in this collection. Full-text search is planned.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Library · کتابخانه")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if model.hasSelectedPoetOffline {
                            Label("Offline", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    Button {
                        showingFilesSettings = true
                    } label: {
                        Label("Library & file settings", systemImage: "gearshape.2")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("open-library-files-settings-from-collection")
                    if model.isDownloading {
                        if model.downloadTotal > 0 {
                            ProgressView(value: Double(model.downloadDone),
                                         total: Double(model.downloadTotal))
                        } else {
                            ProgressView()
                        }
                    }
                    if !model.downloadMessage.isEmpty {
                        Text(model.downloadMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(13)
            } else {
                EmptyPanel(symbol: "books.vertical", headline: "Choose a poet",
                           subtitle: "Select a poet from the sidebar to browse Ganjoor's collection.")
            }
        }
    }

    private var reader: some View {
        ZStack(alignment: .bottomTrailing) {
            if let poem = model.poem {
                IlluminatedReaderView(
                    poem: poem,
                    poetName: model.selectedPoet?.nickname ?? "دیوان شعر",
                    collectionName: model.category?.title ?? "",
                    appearance: readerAppearance,
                    style: pageStyle,
                    fontName: readerFontName,
                    fontSize: fontSize,
                    lineSpacing: lineSpacing,
                    contentWidth: readerContentWidth)
                    .id(poem.fullURL)

                Button {
                    showingReadingSettings = true
                } label: {
                    Label("Style", systemImage: "paintpalette")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .modifier(ReaderGlassChrome())
                .help("Change poetry fonts, colors and page ornament")
                .padding(20)
            } else if model.isLoading {
                VStack(spacing: 12) {
                    ProgressView {
                        Text(model.requestedPoem.map { "Opening \($0.title)…" } ?? "Loading…")
                    }
                    if let requested = model.requestedPoem {
                        Text(requested.fullURL)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("reader-loading-path")
                    }
                }
                .accessibilityIdentifier("reader-loading")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 15) {
                    ArashMark(color: readerAppearance.ornament)
                        .frame(width: 55, height: 55)
                    Text("در باغ سخن")
                        .font(ReaderFontCatalog.font(readerFontName, size: 29))
                        .foregroundStyle(readerAppearance.foreground)
                    Text("Choose a poem and let the page become its home.")
                        .foregroundStyle(readerAppearance.foreground.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(readerAppearance.background)
    }

    private var readingSettings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Poetry appearance").font(.headline)
                        Text("خط و رنگ · Make this page yours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset") {
                        readerTheme = ReaderAppearance.paper.rawValue
                        readerPageStyle = ReaderPageStyle.illuminated.rawValue
                        readerFontName = ""
                        fontSize = 24
                        lineSpacing = 5
                        readerContentWidth = 820
                    }
                    .font(.caption)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("Palette · رنگ").font(.subheadline.weight(.medium))
                    HStack(spacing: 12) {
                        ForEach(ReaderAppearance.allCases) { appearance in
                            Button {
                                readerTheme = appearance.rawValue
                            } label: {
                                Circle()
                                    .fill(appearance.page)
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(appearance.ornament, lineWidth: 2))
                                    .overlay {
                                        if readerTheme == appearance.rawValue {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(appearance.foreground)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .help(appearance.title)
                            .accessibilityLabel(appearance.title)
                            .accessibilityIdentifier("palette-\(appearance.rawValue)")
                        }
                    }
                    Text(readerAppearance.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Page style · صفحه", selection: $readerPageStyle) {
                    ForEach(ReaderPageStyle.allCases) { style in
                        Text(style.title).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("reader-page-style")

                Divider()

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Persian typeface · قلم")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button {
                            refreshFonts()
                        } label: {
                            Label("Refresh fonts", systemImage: "arrow.clockwise")
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }

                    TextField("Filter installed fonts…", text: $fontQuery)
                        .textFieldStyle(.roundedBorder)

                    Picker("Typeface", selection: $readerFontName) {
                        Text("System serif · پیش‌فرض").tag("")
                        if !readerFontName.isEmpty &&
                            !matchingFonts.contains(where: { $0.name == readerFontName }) {
                            Text("Selected: \(readerFontName)").tag(readerFontName)
                        }
                        ForEach(matchingFonts) { option in
                            Text(option.label).tag(option.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("reader-font-picker")

                    if !readerFontName.isEmpty && !ReaderFontCatalog.isAvailable(readerFontName) {
                        Text("This font is unavailable. The reader is using the system serif until it is installed.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text("Installed fonts are discovered from macOS Font Book. No third-party font files are redistributed.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("به جهان خرم از آنم که جهان خرم از اوست")
                        .font(ReaderFontCatalog.font(readerFontName, size: 24))
                        .foregroundStyle(readerAppearance.foreground)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(readerAppearance.page, in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("font-preview")
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Text size: \(Int(fontSize)) pt")
                        .font(.subheadline)
                    Slider(value: $fontSize, in: 17...42, step: 1)
                        .accessibilityIdentifier("reader-text-size")
                    Text("Verse spacing")
                        .font(.subheadline)
                    Slider(value: $lineSpacing, in: 0...20, step: 1)
                        .accessibilityIdentifier("reader-verse-spacing")
                    Text("Reading width")
                        .font(.subheadline)
                    Slider(value: $readerContentWidth, in: 620...960, step: 20)
                        .accessibilityIdentifier("reader-reading-width")
                }

                Text("These settings are saved separately for each app identity on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .frame(width: 430, height: 610)
    }

    private func exportCurrentPoem() {
        guard let poem = model.poem else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = poem.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-") + ".txt"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let document = """
        \(poem.fullTitle ?? poem.title)

        \(poem.plainText)

        Source: https://ganjoor.net\(poem.fullURL)
        """
        do {
            try document.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            model.errorMessage = "Could not export the poem: \(error.localizedDescription)"
        }
    }

}

struct EmptyPanel: View {
    let symbol: String
    let headline: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text(headline).font(.title3.weight(.semibold))
            Text(subtitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
#else
// Buildable on Linux for core-model tests; GUI is macOS-only.
@main
enum ArashKamUnavailable {
    static func main() { print("Arash Kamangir requires macOS 13 or later.") }
}
#endif

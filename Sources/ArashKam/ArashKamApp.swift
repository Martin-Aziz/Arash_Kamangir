#if os(macOS)
import SwiftUI
import AppKit
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
    @AppStorage("readerFontSize") private var fontSize = 24.0
    @AppStorage("readerLineSpacing") private var lineSpacing = 5.0
    @AppStorage("readerContentWidth") private var readerContentWidth = 820.0
    @AppStorage("readerTheme") private var readerTheme = ReaderAppearance.system.rawValue

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
        NavigationSplitView {
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
                        .help("Reading preferences")
                        .popover(isPresented: $showingReadingSettings, arrowEdge: .bottom) {
                            readingSettings
                        }

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
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("آرش کمانگیر").font(.headline)
                    Text("Persian Poetry Library")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showingLibraryManager = true
                } label: {
                    Label("Manage offline library", systemImage: "externaldrive")
                }
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
                    .disabled(!model.canGoBack)
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
                                }.buttonStyle(.plain)
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
                                }.buttonStyle(.plain)
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
                        Text("Offline library").font(.subheadline.weight(.semibold))
                        Spacer()
                        if model.hasSelectedPoetOffline {
                            Label("Downloaded", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    if model.isDownloading {
                        if model.downloadTotal > 0 {
                            ProgressView(value: Double(model.downloadDone),
                                         total: Double(model.downloadTotal))
                        } else {
                            ProgressView()
                        }
                        Text(model.downloadMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Stop download", role: .cancel) {
                            downloadTask?.cancel()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            downloadTask = Task { await model.downloadCurrentPoet() }
                        } label: {
                            Label(model.hasSelectedPoetOffline ? "Refresh offline poet" : "Download poet",
                                  systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.selectedPoet == nil)
                        if !model.downloadMessage.isEmpty {
                            Text(model.downloadMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
        Group {
            if let poem = model.poem {
                ScrollView {
                    VStack(spacing: 24) {
                        Text(poem.fullTitle ?? poem.title)
                            .font(.system(size: 27, weight: .semibold, design: .serif))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Divider()
                        VStack(spacing: 20 + lineSpacing) {
                            ForEach(poem.readingGroups) { group in
                                if group.verses.count == 2 &&
                                    group.verses[0].position == "Right" &&
                                    group.verses[1].position == "Left" {
                                    HStack(alignment: .firstTextBaseline, spacing: 24) {
                                        verseText(group.verses[0].text)
                                        verseText(group.verses[1].text)
                                    }
                                } else {
                                    ForEach(group.verses) { verse in
                                        verseText(verse.text)
                                    }
                                }
                            }
                        }
                        .environment(\.layoutDirection, .rightToLeft)
                        if let source = URL(string: "https://ganjoor.net" + poem.fullURL) {
                            Link("View original on Ganjoor · مشاهده در گنجور",
                                 destination: source)
                                .font(.caption)
                                .padding(.top, 18)
                        }
                    }
                    .frame(maxWidth: readerContentWidth)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 44)
                    .frame(maxWidth: .infinity)
                }
            } else if model.isLoading {
                ProgressView("Loading poem…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyPanel(symbol: "text.book.closed", headline: "A place for poetry",
                           subtitle: "Browse a collection and select a poem to begin reading.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(readerAppearance.background)
        .foregroundStyle(readerAppearance.foreground)
        .tint(readerAppearance.linkTint)
    }

    private var readingSettings: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Reading preferences")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    readerTheme = ReaderAppearance.system.rawValue
                    fontSize = 24
                    lineSpacing = 5
                    readerContentWidth = 820
                }
                .font(.caption)
            }
            Picker("Theme", selection: $readerTheme) {
                ForEach(ReaderAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance.rawValue)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 6) {
                Text("Text size: \(Int(fontSize)) pt")
                    .font(.subheadline)
                Slider(value: $fontSize, in: 17...42, step: 1)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Verse spacing")
                    .font(.subheadline)
                Slider(value: $lineSpacing, in: 0...20, step: 1)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Reading width")
                    .font(.subheadline)
                Slider(value: $readerContentWidth, in: 620...960, step: 20)
            }
            Text("These settings are saved on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(width: 320)
    }

    private func verseText(_ value: String) -> some View {
        Text(value)
            .font(.system(size: fontSize, design: .serif))
            .multilineTextAlignment(.trailing)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
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

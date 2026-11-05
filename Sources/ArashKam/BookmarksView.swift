#if os(macOS)
import SwiftUI
import ArashCore

struct BookmarksView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var visible: [SavedPoem] {
        model.savedPoems.filter {
            PersianNormalizer.contains($0.title + " " + $0.poetName, query: query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Saved Poetry", systemImage: "bookmark.fill")
                        .font(.title2.weight(.semibold))
                    Text("Your bookmarks stay on this Mac.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            TextField("Find saved poems · جستجو", text: $query)
                .textFieldStyle(.roundedBorder)

            if model.savedPoems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(.secondary)
                    Text("Your favorite poems belong here")
                        .font(.headline)
                    Text("Open a poem and select the bookmark button to save it.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visible.isEmpty {
                Text("No bookmarks match this search.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(visible) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: "text.book.closed")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(entry.title)
                                    .multilineTextAlignment(.trailing)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Text(entry.poetName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            Button("Read") {
                                Task {
                                    await model.openSavedPoem(entry.fullURL)
                                    if model.poem?.fullURL == entry.fullURL { dismiss() }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isLoading)
                            Button {
                                model.removeBookmark(entry.fullURL)
                            } label: {
                                Image(systemName: "bookmark.slash")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove bookmark")
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(22)
        .frame(minWidth: 600, minHeight: 450)
        .task { await model.refreshBookmarks() }
    }
}
#endif

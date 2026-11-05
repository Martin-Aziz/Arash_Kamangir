#if os(macOS)
import SwiftUI
import ArashCore

/// Manage only fully downloaded poets. Partial archives remain resumable and
/// are deliberately excluded from destructive actions in this first version.
struct LibraryManagerView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var pendingRemoval: OfflinePoetRecord?
    @State private var showingRemovalConfirmation = false

    private var totalBytes: Int64 {
        model.offlineRecords.reduce(Int64(0)) { $0 + $1.bytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Offline Library", systemImage: "externaldrive")
                        .font(.title2.weight(.semibold))
                    Text("Manage the poets you've downloaded to this Mac.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }

            HStack(spacing: 16) {
                metric(title: "Downloaded poets",
                       value: "\(model.offlineRecords.count)",
                       icon: "books.vertical")
                metric(title: "Local storage",
                       value: ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file),
                       icon: "internaldrive")
            }

            if model.offlineRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(.secondary)
                    Text("No completed downloads")
                        .font(.headline)
                    Text("Choose a poet in the sidebar and select Download poet to read offline.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(model.offlineRecords) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(model.poets.first(where: { $0.slug == item.slug })?.nickname ?? item.slug)
                                    .font(.headline)
                                Text("\(item.fileCount) cached files • \(ByteCountFormatter.string(fromByteCount: item.bytes, countStyle: .file))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let poet = model.poets.first(where: { $0.slug == item.slug }) {
                                Button("Read") {
                                    Task {
                                        await model.selectPoet(poet)
                                        dismiss()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(model.isLoading)
                            }
                            Button(role: .destructive) {
                                pendingRemoval = item
                                showingRemovalConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                            }
                            .help("Remove this poet's downloaded files")
                            .disabled(model.isDownloading || model.isRemovingOfflinePoet)
                        }
                        .padding(.vertical, 7)
                    }
                }
                .listStyle(.inset)
            }

            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Removing an offline copy does not remove your bookmarks or the original poems on Ganjoor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .padding(22)
        .frame(minWidth: 650, minHeight: 450)
        .task { await model.refreshOfflineLibrary() }
        .alert("Remove downloaded poet?", isPresented: $showingRemovalConfirmation) {
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
            Button("Remove Download", role: .destructive) {
                guard let item = pendingRemoval else { return }
                pendingRemoval = nil
                Task { await model.removeOfflinePoet(item.slug) }
            }
        } message: {
            Text("This removes the selected poet's cached poems from this Mac. It cannot be undone, but you can download the poet again.")
        }
    }

    private func metric(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.headline.monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}
#endif

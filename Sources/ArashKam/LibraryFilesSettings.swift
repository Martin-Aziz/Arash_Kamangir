#if os(macOS)
import SwiftUI
import AppKit

/// An intentional place for library transfer actions. We do not present
/// unsupported external book formats as working importers.
struct LibraryFilesSettings: View {
    @ObservedObject var model: AppModel
    let startDownload: () -> Void
    let stopDownload: () -> Void
    let exportCurrentPoem: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack(spacing: 12) {
                Image(systemName: "books.vertical")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Library & Files").font(.title2.weight(.semibold))
                    Text("Import, download, and export from one place.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            Divider()

            VStack(alignment: .leading, spacing: 9) {
                Label("From Ganjoor · دریافت اشعار", systemImage: "square.and.arrow.down")
                    .font(.headline)
                Text(model.selectedPoet.map {
                    "Selected poet: \($0.nickname)"
                } ?? "Choose a poet in the sidebar before downloading.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if model.isDownloading {
                    if model.downloadTotal > 0 {
                        ProgressView(value: Double(model.downloadDone),
                                     total: Double(model.downloadTotal))
                    } else {
                        ProgressView()
                    }
                    Button("Stop download", action: stopDownload)
                } else {
                    Button {
                        startDownload()
                    } label: {
                        Label(model.hasSelectedPoetOffline ?
                              "Refresh selected poet" : "Download selected poet",
                              systemImage: "arrow.down.circle")
                    }
                    .disabled(model.selectedPoet == nil)
                    .accessibilityIdentifier("download-selected-poet")
                }

                if !model.downloadMessage.isEmpty {
                    Text(model.downloadMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 9) {
                Label("Export · برون‌بری", systemImage: "square.and.arrow.up")
                    .font(.headline)
                Text("Save the open poem as a UTF-8 text document, including its source attribution.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Export current poem…", action: exportCurrentPoem)
                    .disabled(model.poem == nil)
                    .accessibilityIdentifier("export-current-poem")
            }

            Divider()

            Text("Importing local books (.s3db, PDF, EPUB) is not supported yet. Only the official Ganjoor download and single-poem text export are active in this version.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(25)
        .frame(width: 570, height: 510)
    }
}
#endif

# Arash Kamangir — development roadmap

## Product principles

- **Truly native:** SwiftUI and Apple platform frameworks; no Electron/WebView wrapper.
- **Offline first:** when a poet is downloaded, every listed poem is available offline.
- **Respect text:** preserve verse order, couplet boundaries, Persian/Arabic character variations and attribution.
- **Explicit downloads:** user controls network traffic, local data, cancellation and future deletion.
- **Secure defaults:** reject unsafe paths, validate imported schemas, keep user state separate from source archives.

## P1 — Native foundation (this pull request)

- [x] Bootstrap Swift Package macOS app
- [x] Official manifest and navigation
- [x] Persian title filtering and right-to-left reading
- [x] Selective full-poet download with progress and cancellation
- [x] Persistent local JSON cache and import completion markers
- [x] Bookmarks, copy and original links
- [x] Model/path/storage unit tests
- [ ] Verify UI and app-bundle launch on Apple Silicon and Intel macOS
- [ ] Accessibility keyboard and VoiceOver walkthrough

## P2 — Local search & library control

- [ ] SQLite+FTS5 with normalized search terms and incremental indexing
- [ ] Search poems by verse text, poet and category
- [ ] Display download size and estimated poem count before download
- [x] Manage completed downloads: list, disk usage, explicit confirmed removal
- [ ] Remaining management: retry, repair, verify, update and partial-cache cleanup
- [x] Dedicated offline-only browsing filter
- [ ] Database integrity and migration tests
- [ ] Download concurrency/backoff limits for 429/5xx
- [ ] Cancel / resume UI integration tests

## P3 — Legacy compatibility

- [ ] Import user-provided .s3db databases with read-only schema validation
- [ ] User-provided ZIP support with zip-slip and decompression-bomb protections
- [ ] Preserve source attribution and migration provenance
- [ ] Export and import a user-backup archive

## P4 — Reader quality

- [ ] Better typography with explicit font fallback and bidi layout tests
- [x] Adjustable reading themes, verse spacing, font and reading width
- [x] Saved Poetry view with bookmark navigation, filtering and removal
- [ ] Reading history, full accessibility pass and typography refinements
- [ ] Audio recitations where usage rights permit
- [ ] Notes and tags, fully local until opt-in sync

## P5 — Distribution

- [ ] App icon, naming and accessibility verification
- [ ] macOS build/test matrix, launch smoke tests
- [ ] Signed, notarized installer and update channel
- [ ] Privacy notice and licensing review for source datasets

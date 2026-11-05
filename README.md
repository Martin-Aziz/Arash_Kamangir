# آرش کمانگیر — Arash Kamangir

A **native SwiftUI macOS reader for Persian poetry**, powered by the public Ganjoor data export. This is an independent open-source application, not an official Ganjoor release.

## Phase 1 — implemented

- Native macOS three-column window with poet, collection and poem navigation
- Official Ganjoor poet catalog with Persian-title filtering
- Right-to-left reader with preserved couplet/hemistich structure, adjustable font size and dark-mode-compatible system colors
- Bookmarks saved on this Mac, copying poems, links to the original Ganjoor poem
- Download **one selected poet** for offline access directly from the official data export
- Bounded concurrent downloads (six files at a time), progress, cancellation and resumable partial file cache
- Private Application Support storage, no bundled poetry corpus, path validation and JSON decoding
- Core unit tests for schema, paths, verse ordering, Persian normalization and offline storage

The download button downloads a **complete selected poet**: poet profile, category tree and all referenced poem JSON files. A completion marker appears only once every file succeeds. If interrupted, run it again; already cached poem files are skipped. Browsed poems and collections are cached too.

## Phase 2A — GUI and local library management (in review)

- Offline library management sheet: see completed poet downloads, file counts and actual local storage sizes; open a downloaded poet or remove its files after confirmation
- Optional **Downloaded only** sidebar filter
- **Saved Poetry** sheet: browse/filter bookmarks, reopen saved poems and remove bookmarks
- Reader preferences: system, warm paper and night appearances, adjustable font size, verse spacing and reading width (persisted per Mac)
- Storage tests for inventory, deletion isolation, invalid slugs and symlinked parents

**Still pending:** SQLite/FTS5 full-text search, partial-download cache cleanup/repair, .s3db import, notarized DMG, VoiceOver/UI automation and physical Mac verification. These additions have not been certified on macOS yet. Use [the local Mac QA checklist](docs/LOCAL_MAC_QA.md) before distribution.

### Source and importing

Ganjoor documents this static API:

https://github.com/ganjoor/ganjoor-data/blob/main/API.md

Data base: https://cdn.jsdelivr.net/gh/ganjoor/ganjoor-data@main/

The app starts by fetching manifest.json; it does **not** ship copyrighted poetry files or download the entire corpus without user action. The upstream schema is versioned, and unknown future versions will be rejected until the app is updated.

The **official current JSON export** is supported in Phase 1. Importing an older Windows Desktop Ganjoor .s3db database, zip-file import, local full-text search, and a packaged signed .dmg are future phases, not current features.

### Requirements

- macOS 13 or later (Apple Silicon or Intel)
- Xcode 15 or later and Swift 5.9+
- Internet connection for initial catalog and downloading; downloaded poet collections are readable offline

### Development

Open Package.swift in Xcode, select the ArashKam executable, and Run.

Alternatively, from Terminal on a Mac:

    swift test
    swift run ArashKam

To create a **local, unsigned/notarization-free** .app bundle for testing:

    bash scripts/package-macos.sh
    open dist/ArashKam.app

The local packaging script uses an ad-hoc code signature; it does not produce an Apple-notarized distributed application.

### Data location

    ~/Library/Application Support/ArashKam/GanjoorData/

Poet completions are recorded in completed/; files are stored under their original relative paths in poets/. Bookmarks use macOS UserDefaults.

### Privacy and security

- No accounts, analytics, tracking SDKs or external JavaScript
- Only requests to Ganjoor's documented static export; no HTML is injected into the reader
- Strict URL/path validation protects the local archive from traversal
- Offline downloads are explicit and cancellable
- Network failures cannot mark a partially downloaded poet as complete
- Text and metadata come from an external source and must be treated as untrusted

### Project roadmap

1. **Foundation:** SwiftUI browsing, poem rendering, selective offline import (this PR).
2. **Library engine:** offline library manager, deletion and storage stats (Phase 2A); SQLite/FTS5, robust diacritic-insensitive local poem search and repair workflows still pending.
3. **Compatibility:** Import older Ganjoor .s3db and user-supplied ZIP backups, import validation, backup/restore.
4. **Reading experience:** Persian typography refinement, annotations, favorites library, recent reads, recitations.
5. **Release:** app icon, accessibility verification, Mac CI, signed/notarized DMG, updates.

### Attribution and rights

Poetry and metadata are retrieved from Ganjoor (https://ganjoor.net) and its public data project (https://github.com/ganjoor/ganjoor-data). This repository's MIT license applies **only to this application's original source code**. It does not grant rights to redistribute the downloaded corpus, third-party annotations or recordings. Confirm upstream licensing and individual content rights before distributing datasets, reproducing poem collections, or packaging recordings.

The application name is inspired by Arash the Archer (آرش کمانگیر).

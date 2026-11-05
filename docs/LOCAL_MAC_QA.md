# Local Mac verification — Phase 2A

This branch has not been compiled, launched or visually inspected on a Mac by the initial author. Do not treat a code review as macOS GUI certification.

## Environment

- macOS 13+ (prefer current Apple Silicon Mac).
- Xcode 15+ with Command Line Tools selected.
- Internet access for the first Ganjoor catalog fetch.
- A **nonessential** downloaded poet to test removal; removal is destructive to that poet's offline cache.

## Run

From the repository root:

    xcode-select -p
    swift --version
    swift test
    swift build
    swift run ArashKam

Inspect compiler warnings. If SwiftPM build or launch fails, collect the full diagnostic and fix it before using the app for real data.

If the executable launches correctly, also test local .app packaging:

    bash scripts/package-macos.sh
    open dist/ArashKam.app

The package script produces an **ad-hoc signed, unnotarized** app for local testing only.

## Functional checks

1. **Navigation:** open Hafez → ghazals → poem 1; check the poet/category/poem selections and the back button.
2. **Persian rendering:** verify right-to-left couplet reading order, correct joined characters, diacritics, long-line wrapping, dark-mode contrast and text selection.
3. **Reading preferences:** test System/Paper/Night, font size at min and max, verse spacing and reading width; close and reopen to confirm persistence. The Reset control should restore defaults.
4. **Bookmarks:** save a poem, open **Saved poetry**, filter it using Persian variants, reopen it, then remove its bookmark. Close/reopen the app and confirm persistence.
5. **Offline management:** download one small poet; the manager should report a completed poet, cached-file count and disk space. Open the poet through **Read**. Toggle **Downloaded only**.
6. **Offline restart:** disconnect Wi-Fi (after download), restart the app, read previously downloaded poems and confirm the cached catalog works.
7. **Deletion:** reconnect, confirm the manager's removal dialog, cancel once, then remove a **test** poet. Verify only that poet's directory and completion marker are removed. Other downloaded poets and bookmarks must remain. Avoid deleting valuable existing downloads.
8. **Concurrency:** while a download runs, verify removal is disabled. Test cancel + retry, and do not mark an incomplete poet as fully offline.
9. **Accessibility:** keyboard-only navigation, toolbar tooltips, VoiceOver reading order, text contrast and usability at narrow but supported window sizes.
10. **Resilience:** empty offline library, empty Saved Poetry, invalid/unavailable network, stale bookmarks, repeated reopen and close, and large collections.

## Evidence to collect

- Exact macOS, Xcode and Swift versions and CPU architecture.
- Swift test and build outcomes.
- Screenshots of the main library, night reader, paper reader, bookmarks and offline manager (avoid personal data).
- Any reproducible crash/console log, and regression tests added for a fix.
- A short PASS / FAIL / BLOCKED checklist for each item above.

Do not merge or publish release artifacts until Mac build and essential end-to-end flows pass.

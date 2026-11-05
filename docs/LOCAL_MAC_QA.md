# Local Mac verification — Phase 2A

Earlier Mac QA (macOS 27.2, Swift 6.4.2) passed 11 unit tests and debug/release builds, and verified Hafez 1 → 2 → 1 with existing cached data. The fresh-network GUI flow and broader end-to-end checks remain unverified. No release certification is implied.

For repeatable, isolated network GUI testing and app-only screenshot capture, follow the [separate QA app guide](ISOLATED_MAC_QA.md). The QA helper itself still needs its first Mac verification.

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

## Regression: Hafez ghazal 1 vs 2 (previously blocked)

The Ganjoor source data maps category row ID 2130 to **/hafez/ghazal/sh1**
and ID 2131 to **/hafez/ghazal/sh2**. The reader must never display a
previously opened poem while a different poem is loading.

1. Open Hafez → Ghazals; locate the actual **غزل شمارهٔ ۱** row.
2. With Accessibility Inspector or GUI automation, select the button with
   `accessibilityIdentifier == "poem-row-2130"`. Avoid coordinate-only clicks
   in a scrolling list whose row heights can change.
3. If the loading state is visible, its path must be **/hafez/ghazal/sh1**.
   Wait until the loading state disappears. Inspect the heading with
   identifier **reader-poem-title**; the title must contain **غزل شمارهٔ ۱**
   and its accessibility value must be **/hafez/ghazal/sh1**.
4. Select **poem-row-2131**. The previous poem must clear promptly, then
   the reader must show **غزل شمارهٔ ۲** and **/hafez/ghazal/sh2**.
5. Repeat 2130 → 2131 → 2130 with both fresh/network and cached data.
   Verify row tap identity and completed reader identity separately.
6. Test a click during an active load: other poem rows must be disabled,
   never silently display a stale previous result.
7. If the identity still differs, inspect (do not delete or overwrite) the
   local cache at
   `~/Library/Application Support/ArashKam/GanjoorData/poets/hafez/ghazal/`.
   Compare `_cat.json`, `sh1.json`, `sh2.json` fields `Id`,
   `FullUrl` and `Title` against the displayed row and reader heading.
   Save the findings/screenshots; never wipe user data to make a test pass.

This is a **release-blocking** regression test. A successful unit test alone
does not establish that the GUI action targeted the correct row.

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

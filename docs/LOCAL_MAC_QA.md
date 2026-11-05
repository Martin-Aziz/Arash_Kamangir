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

## New reader visual/typography QA (illuminated branch)

1. Open Hafez poem 1 and toggle **Focus on poem**; the two browsing columns
   should hide, the poem should reflow without clipping, and toggling again
   restores navigation without losing the selected poem.
2. Click the floating **Style** control or the toolbar preferences button.
   Try **System, Ivory, Midnight, Rose, Lapis, Jade**. Verify legibility,
   icon contrast, the poetic heading and a functional source link.
3. Switch **Quiet** vs **Illuminated**. Confirm the original floral border
   does not obscure text, capture clicks or appear as a VoiceOver verse.
4. Choose at least two installed Persian typefaces, then import a user-owned
   .ttf/.otf/.ttc through **Add font…**. Confirm typeface preview AND actual
   poem change. Reopen the app and verify the same font still renders.
   Test a missing selected font and invalid/unreadable font file. Never
   commit, redistribute or publish the user's font binary.
5. Inspect ligatures, diacritics, Persian ی/ک and mixed-script typography
   with Hafez. Test 17pt and 42pt, long hemistiches and narrow windows.
6. Open **Library & Files** from the toolbar or collection, then download
   the selected poet, stop if needed, and verify status. Test **Export
   current poem…** and inspect the exported UTF-8 text and Ganjoor link.
   Cancel the save dialog and verify no unexpected file exists.
7. Confirm the packaged app has a visible bow-and-arrow icon in Finder,
   and that the QA bundle remains separate from production. Verify
   Liquid Glass-style controls on macOS 26+; older OS uses native material.
8. Run a full regression of bookmarks, Hafez sh1/sh2 identity, cached
   navigation and offline library manager. Incomplete Babataher download
   with upstream HTTP 403 remains tracked separately in issue #10.

This branch is not Mac-certified until all applicable checks pass. Record
explicit PASS/FAIL/BLOCKED, screenshots, warnings and source paths.

## P0 visual regression — genuine Focus and a Poetry Keepsake

At main `d6237b29` the Focus toolbar changed its label but retained **both**
leading macOS columns. The supplied QA archive includes
`qa-artifacts/focus.png` as the regression evidence. Apple documents that
macOS may keep the content column visible when `NavigationSplitViewVisibility`
changes. The fix must use a separate full-window view, not just update the
toolbar icon.

1. Open cached Hafez ghazal 1. Click the toolbar's **Focus on the poem**,
   then capture a QA-window-only screenshot. Both poet and poem-list columns
   must be **absent**; the decorated poem must be centered with real room to
   read. Inspect `focus-poetry-reader` and `reader-poem-title`.
2. Press **Command–Shift–F**, or click **Return to library**. The **same**
   Hafez poem and bookmark must remain selected. Repeat 1 → 2 → 1 and
   the focus toggle after selecting poem 2.
3. Open appearance via the toolbar. On macOS 14+, the control should display
   a **trailing inspector**, not a popover obscuring multiple couplets.
   Confirm changes to font/palette are visible live. On macOS 13, the
   compatibility sheet must still work.
4. Open **Keepsake Studio** with **Command–Shift–K** from an open poem.
   Check that navigating couplets preserves the original order and that
   the actual Persian words and poet/title/source are not rewritten.
5. Save a PNG using a QA-only destination, check the file is actually
   1440×1800 pixels and legible, no missing diacritics/glyphs, no clipped
   lines or missing source URL. Verify **Copy with attribution** includes the
   correct `https://ganjoor.net/hafez/ghazal/sh1` reference.
6. Test **Noto Nastaliq**, imported Vazirmatn and fallback serif; six
   palettes; 17 and 42pt; Quiet/Illuminated; 920, 1220 and 1600px-wide
   windows. Check that content does **not** overflow or scroll horizontally
   merely because the old 480px minimum page was forced.
7. Turn **Reduce Motion** on in macOS accessibility. No decorative
   upward-slide animation should play on a new poem. With reduced motion
   off, the one-shot reveal must remain brief and not obscure scrolling.
8. Exercise bookmarks, Ganjoor source links, copy, download status, QA
   isolation and relaunch. Existing Babataher HTTP403 is tracked in #10.

Report PASS/FAIL/BLOCKED for each. Save Focus-before/after, inspector,
six palettes, two fonts, Keepsake preview, PNG export and narrow window
screenshots. Do not auto-merge an unverified PR or delete any original
download/font from the user's checkout.

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

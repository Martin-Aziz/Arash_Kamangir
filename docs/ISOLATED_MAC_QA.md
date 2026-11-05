# Isolated macOS GUI QA — never use your personal archive

This guide is for the QA harness branch. A clean build or passing network
probe does not replace actual macOS GUI testing.

## Separate data identity

The normal reader uses bundle ID **com.arashkam.reader** and poetry data
under **~/Library/Application Support/ArashKam/GanjoorData/**.

The QA bundle uses **com.arashkam.reader.qa** and poetry data under
**~/Library/Application Support/ArashKamQA/GanjoorData/**. The bundle
ID also provides a separate macOS preferences domain, including bookmarks,
font size and reading themes. The QA app displays a **QA build · Isolated
data** banner. Stop if the banner is absent.

The scripts never erase user archives, reset preferences, change Wi-Fi,
or remove the production app.

## Build on a Mac

Use a separate worktree to preserve local uncommitted changes.

    git fetch origin
    git worktree add ../ArashKam-isolated-QA origin/feat/isolated-macos-qa-harness
    cd ../ArashKam-isolated-QA
    swift test
    swift build
    swift build -c release
    bash scripts/package-macos.sh --qa

Verify the bundle identifier:

    /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' dist/ArashKam-QA.app/Contents/Info.plist

Expected: **com.arashkam.reader.qa**. If it differs, stop.

    open -n dist/ArashKam-QA.app

Verify the QA banner is visible. Never relabel the production bundle
or modify its archive root for testing.

## Fresh network-backed Hafez flow

1. Optional read-only source check:

       bash scripts/qa-ganjoor-network-probe.sh

   This fetches temporary official JSON files, checks the canonical
   metadata for Hafez's first two ghazals, and removes the temporary
   files on exit. It is NOT a GUI test.

2. Before the GUI check, establish whether QA sh1/sh2 files exist.
   If prior QA cache already exists, this is not a fresh-network test.
   Use a fresh test account, or explicitly archive prior QA-only data.
   Never erase personal data to make a test pass.

3. Open **حافظ → غزلیات → غزل شمارهٔ ۱**. Wait for loading to finish.
   Confirm heading **غزل شمارهٔ ۱** and accessibility URL
   **/hafez/ghazal/sh1**. Confirm the opening verse begins
   **اَلا یا اَیُّهَا السّاقی**. Check the second ghazal, then return
   to the first.

4. Inspect the QA cache under ArashKamQA: the sh1.json and sh2.json
   objects must agree with the selected category row on Id, FullUrl,
   and Title. A source fetch alone is insufficient to establish GUI success.

5. Repeat 1 → 2 → 1 after the QA files have been cached and verify it
   succeeds offline.

6. If a window becomes obscured, do not click screen coordinates
   blindly. Activate the QA bundle before choosing rows, and verify
   the displayed poem title and canonical URL after loading.

7. If the interaction is blocked by macOS foreground-window control or
   permissions, record BLOCKED with the reason, rather than treating
   a network probe or prior cached test as a PASS.

## Capture only the QA app window

Do not submit desktop images showing unrelated applications.

    mkdir -p "$HOME/Desktop/ArashKam-QA-evidence"
    bash scripts/qa-capture-window.sh "$HOME/Desktop/ArashKam-QA-evidence/hafez-sh1.png"

Repeat for poem 2, loading state, paper/night themes, Saved Poetry,
Offline Library and confirmation dialogs. The helper locates a
CoreGraphics window owned by the running **com.arashkam.reader.qa**
process. It checks the output is a valid PNG, but every screenshot
must be visually inspected before reporting it as evidence.

Screen Recording, Accessibility or Automation permissions may need
to be explicitly granted in macOS System Settings. If window capture
is blocked, use the built-in single-window screenshot shortcut
(Shift–Command–4, followed by Space).

## Remaining release gate

Record PASS, FAIL or BLOCKED, with screenshots/logs, for all of these:

- Fresh-network poem 1 → 2 → 1, followed by a cached repeat.
- System/Paper/Night themes, reset and persistence.
- Bookmarks: save, search, reopen, remove, restart persistence.
- Download progress, cancellation, retry, and offline restart.
- Downloaded-only filtering and storage totals.
- Confirmation/cancel and deletion on **QA-only** downloads.
- Dark/light appearance, resizing, keyboard navigation, VoiceOver.
- Accessibility identifiers; document if a CUA client omits them.

Do not present the app as certified or notarized until essential GUI
checks pass and any actual defects are corrected.

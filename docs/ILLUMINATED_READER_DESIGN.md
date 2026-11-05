# The Persian divan — reader redesign, typography, and brand

## Intent

Arash Kamangir should feel like a **modern Persian poetry collection**, not
a spreadsheet or document browser. Historical illumination informs rhythm,
color and page hierarchy; the verses remain real, selectable text. The app
does **not** ship scans of third-party manuscripts or commercial font files.

### Research anchors

- The Metropolitan Museum of Art's *Catalogue of Persian Manuscripts*
  describes Hafez works with gold/green illuminated title pages, floral
  panels at poem endings, slender cypresses, roses, and nightingales:
  https://resources.metmuseum.org/resources/metpublications/pdf/A_Catalogue_of_the_Collection_of_Persian_Manuscripts.pdf
- Encyclopaedia Iranica's account of Arash the Archer (Āraš) identifies
  the heroic bow-shot as a central legend:
  https://www.iranicaonline.org/articles/aras-avestan-erexsa/
- Apple recommends keeping Liquid Glass in the **navigation/control layer**
  rather than behind document content:
  https://developer.apple.com/design/human-interface-guidelines/materials
- Apple documents PostScript-name lookup, Font Book discovery and
  process-scoped Core Text registration for user fonts:
  https://developer.apple.com/documentation/technologyoverviews/fonts

## First implementation — design system

- Original **bow + flying arrow** emblem as SwiftUI vector and editable SVG.
  The Mac packaging script renders an actual 1024px icon via AppKit and
  iconutil. A production app icon is not yet notarized.
- Six named reader palettes:
  **System, Ivory, Midnight, Rose, Lapis, Jade**.
- Two page modes: **Quiet** (no framing) and **Illuminated** (double rule,
  original rosettes, flower divider, generous page margins).
- Live **Persian typeface** selector. It discovers installed macOS fonts that
  contain the Persian-specific letters پ ژ گ چ and exposes their exact
  PostScript names. Search, preview, and refresh are available.
- **Add font…** imports the user's own TTF/OTF/TTC files from a file picker,
  refuses unsupported files, symlinks and files over 16 MB, copies them to
  user-private Application Support, and registers only in this process. QA
  and production import directories remain separate.
- Responsive poem layout: paired hemistiches with room to breathe on wide
  screens; stacked, right-aligned lines when the detail pane is too narrow.
- Focus mode hides the poet/collection columns. A floating **Style**
  control uses Liquid Glass on macOS 26+ and native material on older systems.
  Glass is never layered behind poem text.
- **Library & Files** centralizes the supported Ganjoor selected-poet
  download and the attributed UTF-8 text export of an open poem. Existing
  bookmarks and offline manager remain accessible. Legacy .s3db / PDF /
  EPUB book import is not yet implemented; do not represent it as working.

## Non-goals in this pull request

- Reproducing supplied manuscript images inside the app: confirm each
  source object's reuse rights first.
- Shipping the user's locally added fonts or fonts with unclear licenses.
- PDF/EPUB import, scanned-page OCR, PDF/export publication workflow,
  book covers, multi-book reader and full-text indexing.
- Making Liquid Glass the poem-page background.
- Marking the product released or certified without a Mac GUI pass.

## Upcoming design milestones

1. **P1A — type & emotion (this PR):** selected fonts, page modes, six
   palettes, spacing, focus, original icon, transfer settings.
2. **P1B — editor & personal collection:** local user poem/file import,
   author attribution, book metadata, annotation and dedicated library hub;
   verify safe import and duplicate handling.
3. **P1C — beautiful exports:** PDF with embedded licensed fonts, print
   layout and optional couplet art card; respect poem copyrights.
4. **P2 — search:** local SQLite/FTS5 full-text Persian search, collection
   filters and navigation to matched lines.
5. **P3 — book experience:** optional two-page spreads, accessible
   animations, calligraphic flourishes, page navigation and user-provided
   manuscript scans only after rights verification.
6. **P4 — distribution:** accessibility + VoiceOver QA, complete download
   and offline tests, app signing and notarized macOS distribution.

## Mac quality gate for this PR

- Run swift test, swift build, swift build -c release and package the normal
  and QA apps; confirm both have a valid icon and distinct bundle IDs.
- Select installed Persian fonts, import a personally licensed font and
  reopen; verify the same PostScript selection still renders. Verify a
  missing font falls back gracefully.
- Verify Arabic and Persian shaping, ligatures, combining marks, bidi,
  ZWNJ and long wrapped hemistiches; test every palette in light and dark
  system appearance.
- Verify selected Hafez 2130→2131→2130 and source accessibility values
  are unchanged; test bookmarks, source link and text copy.
- Switch between Quiet and Illuminated; enter and leave Focus Mode.
  Confirm the border does not cover text or intercept clicks.
- Verify Library & Files download, stop, text export with correct UTF-8
  content and attribution, cancel of save panel, and read-only access
  to production data during QA.
- Run window-size and VoiceOver checks; reduce transparency in System
  Settings to verify native Liquid Glass accessibility adjustments.
- Document ALL compiler warnings, screenshot evidence and regression
  outcomes before merging.

### Existing QA / branch safety note

PR #7 was merged before the post-QA URLSession cancellation patch was
pushed. That patch is **not automatically in main**. Separate draft PR #8
contains the known repair and must be verified and merged independently.
This redesign intentionally branches from main and does not silently
absorb a commit from an already-merged PR's later head.

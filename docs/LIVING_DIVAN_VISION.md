# Arash Kamangir — The Living Divan (دیوان زنده)

## Product principle

Create a beloved, deeply Persian, intimate place for poetry rather than an
ornamented JSON browser. Each interaction should help someone **discover,
feel, keep, discuss or share an authentic poem**. Visual ambition is high;
confusing controls, illegible calligraphy, excessive animation, invented
attributions and unlicensed artwork are not acceptable trade-offs.

Research references:

- Safavid illuminated poetry manuscripts often use floral margins, gold
  accents, decoupage and stencil: [The Met, An Illuminated Manuscript of
  Poetry in Nasta'liq](https://www.metmuseum.org/art/collection/search/919132).
- Apple's [macOS design guidance](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
  recommends personalization, resizable windows, native keyboard shortcuts
  and a capable fullscreen experience.
- Apple's [SwiftUI NavigationSplitViewVisibility](https://developer.apple.com/documentation/swiftui/navigationsplitviewvisibility)
  notes macOS can insist on showing the content column: true distraction-free
  reading needs an explicitly separate full-window reader.
- [Apple Liquid Glass guidance](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
  concerns navigation and controls. Text remains on opaque, high-contrast paper.
- [Apple motion guidance](https://developer.apple.com/design/human-interface-guidelines/motion)
  says animation must serve comprehension and respect Reduce Motion.
- [Apple Foundation Models language/locale guidance](https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models)
  requires runtime language support checks. **Do not assume Persian is supported**
  by the system model.
- The existing [Divan iOS app](https://apps.apple.com/us/app/id6774013888)
  advertises daily poems, Fal-e Hafez, wallpapers and Persian fonts. Those
  features alone are not sufficient differentiation.

## P0 — Make the reader trustworthy, immersive and delightful (current PR)

- True full-window Focus Mode: the poet and category panes are **not created**
  while focused, because setting .detailOnly alone did not hide both on macOS.
- Toolbar actions continue working in Focus Mode; restoring library panes
  preserves the selected poet, category and poem. Shortcut Cmd+Shift+F.
- Native trailing **Appearance Inspector**, avoiding a giant floating popover
  over the verses. The Style button is no longer drawn on top of poetry.
- Reader page adapts to its actual width, maintains Persian shaping, and
  avoids forcing a 480px minimum text column into narrow split-view panes.
- Gentle, one-off poem reveal animation; Reduce Motion disables decorative
  displacement/animation.
- **Keepsake Studio** (Cmd+Shift+K): choose an actual poem group, preview an
  illuminated original card with the selected font and palette, copy with
  source, or export a high-resolution PNG using SwiftUI ImageRenderer.
- No AI-labelled behavior in this phase. The authentic source remains visible.

## P1 — A poem as an experience (next)

**Entry ritual**
- A short, optional opening moment: an illuminated title, an authentic
  couplet of the day from locally indexed poetry, and one large *Read* action.
- Optional seasonal visual moods (spring blossoms, rain-washed jade,
  moonlit lapis), not infinite animations or hard-coded stock art.
- Respect preferred color scheme, high contrast, Reduce Motion and mute.
- A one-click exit to a clean, distraction-free text-only view.

**Joy of owning a verse**
- Keepsake templates: miniature, gold filigree, watercolor, typographic
  minimal, night-sky. User-selectable export sizes, including square/portrait.
- Local scrapbook: *My Divan*, favorites organized as love, hope, longing,
  friendship, solitude; user tags are personal labels, not AI diagnoses.
- Rich but reversible annotation in the margin; bookmark history; revisiting
  an earlier favorite without notifications by default.
- Optional custom covers and imported art only with rights confirmation.

**Page artistry**
- A carefully typeset two-page spread only when the window is large enough.
- Script-specific Nastaliq/Naskh/modern typography presets with thorough
  joining and diacritic testing. Never bundle a third-party font without
  redistribution permission.
- A tactile but accessible page turn. No mandatory sound, continuous
  parallax, simulated paper noise over words, or decorative cursor trails.

## P2 — Poetry intelligence, without fabricated scholarship

**Source-first discovery**
- Build an offline Persian-normalized SQLite/FTS5 index of Ganjoor JSON:
  normalize Persian vs Arabic glyphs, Arabic diacritics, ZWNJ and common
  orthography. Return exact poem ID, verse order and author.
- "Echoes": click a motif such as عشق or سفر to find *verifiable original*
  matches by lexical search; visual map shows poem-to-poem links with the
  full authentic line as citation.
- “Talk to the Divan”: explore metaphor, cultural context, language and
  alternative readings of a specific verse, but distinguish commentary
  from established facts and cite the exact line/source for every claim.

**Optional AI companion**
- Default **off**; explicit opt-in in Settings. Explain whether processing
  runs on-device or through a chosen cloud provider before any text is sent.
- Try Apple Foundation Models only if the runtime model supports the
  requested Persian language/locale. On unsupported devices/languages,
  disable the on-device option rather than silently switching to English.
- Optional separately configured cloud provider can be added later with
  explicit consent, spend caps, retry behavior and deletion controls.
  Never ship a developer API key in the app or silently upload bookmarks,
  personal notes, user books or reading history.
- Retrieval returns a small set of trusted local poem/verse source IDs.
  Model output must contain structured source anchors; the client validates
  every poem ID and quote against exact cached text. Reject invented quotes,
  false attributions, and unsupported historical claims.
- Explicit views: **Original**, **Plain-language explanation**, **Historical
  context**, **Personal reflection (AI-generated)**. No mixing AI prose
  into the original poem text.
- Poetry interpretation is subjective; show alternatives and uncertainty.
  Do not frame a Fal-e Hafez result as a factual prediction or diagnosis.
- Evaluate on a human-reviewed Persian poetry set: quotation accuracy,
  citation correctness, readability, harmful hallucinations, and cultural
  fidelity. Release only when Persian language quality meets the bar.

## P3 — Social and collection workflows

- Consent-first share cards and noninteractive poem links that include
  the exact poet/poem attribution; optional private scrapbook collection.
- Read aloud: real and appropriately licensed Persian audio when available,
  clear narrator attribution and timing, no unauthorized synthesized
  artist voice. User controls playback and its privacy.
- Export *My Divan* to a portable, documented format with content rights
  and a reversible backup plan; import EPUB/PDF/TXT per issue #12,
  legacy .s3db import per issue #4.
- No public social feed until local reading and annotation are excellent.

## Quality and success criteria

**Technical release gates**:
1. Mac GUI Focus screenshot: **both** leading library columns are absent.
   Cmd+Shift+F reverses the mode and keeps the same poem + bookmark.
2. Keepsake PNG is verified visually and by dimensions (1440×1800),
   accurate source URL, no clipping, Persian joining and selected fonts.
3. Narrow 920px window; normal 1220px; wide 1600px; text at 17 and 42pt;
   long hemistiches; all six palettes. Zero horizontal text clipping.
4. Accessibility: read poet and verses in correct order, focusable controls,
   obvious keyboard shortcuts, high contrast, reduce transparency and
   reduce motion.
5. No destructive data operations on the user's production cache.
6. Complete selected-poet download, offline restart and safe delete still
   need certification; independently tracked 403 upstream blocker #10.
7. New features must be visibly verified on Mac, not declared passing from
   Linux-only source parsing or older Swift tests.

**Experience metrics (targets, not demonstrated outcomes)**:
- A user can reach a real poem from the app start in three actions or fewer.
- Opening/closing Focus takes a single action.
- Creating a PNG keepsake from an open poem takes at most four actions.
- 100% of exported and AI-quoted verses preserve original source attribution.
- Respect the user's chosen font and palette after relaunch, while presenting
  a graceful fallback if the font is later missing.

## Licensing and artistic boundaries

Historical manuscript images are references, not automatically licensed assets.
Our borders, icons and ornamentation are original vector art. The original
Persian poems remain attributed to Ganjoor; confirm rights for modern poems
and user-uploaded works. Imported fonts never enter Git or release binaries
without an explicit license review.

Current implementation status is **P0 in review**, not macOS certified.

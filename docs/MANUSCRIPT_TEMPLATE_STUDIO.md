# Manuscript Template Studio — Design-to-Native Implementation Contract

## Design problem and source of truth

The actual macOS app passed Hafez navigation and a focus-mode QA pass,
but its pale page with a tiny rosette and double-line frame did **not** match
the user's richly illuminated Safavid/Kashmiri divan references. A
graphic-design mockup alone is not a working reader. This milestone defines
an **art template system** with explicit colors, layout regions, scalable
vector ornament and editable source files.

We are not publishing a screenshot that the Mac app cannot reproduce.
The reference artwork guides the implementation; final Mac GUI screenshots
must be judged independently.

### Historical research

- Encyclopaedia Iranica on Persian calligraphic ornament:
  https://www.iranicaonline.org/articles/calligraphy/calligraphy-iii-ornamentation/
  It documents **sar-lawh** headpieces, **hashiya** border ornament,
  **toranj** medallions, **lachak** corners, golden/floral illumination
  and delicate compositions.
- Safavid floral manuscripts are often densely ornamented in lapis,
  gold, rose and green. The user-provided reference images are used for
  comparison only and are **not bundled**.
- The Met collection contains public-domain Persian poetry manuscripts
  available under its Open Access program (confirm the individual
  image's public-domain status before using it in a released app):
  https://www.metmuseum.org/art/collection/search/443198
  https://metmuseum.github.io/
- Adobe InDesign **Parent Pages** are an example of reusable book design
  templates, but an InDesign page is NOT natively converted to SwiftUI:
  https://helpx.adobe.com/indesign/desktop/create-and-organize-pages/create-and-manage-parent-pages/about-parent-pages.html
- Arabic/Persian typography needs correct right-to-left composition;
  Adobe's World-Ready composers explicitly support complex-script layout:
  https://helpx.adobe.com/indesign/desktop/language-and-proofing/arabic-and-hebrew/set-up-arabic-and-hebrew.html
- Figma MCP can give a coding agent editable design layers/variables, but
  Figma itself says it does not produce finished native code automatically:
  https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs

## The three complete art directions

**Royal Lapis / لاجورد**
- Deep cobalt sar-lawh at the top with four nested pointed arches,
  gold stars and geometric lattice.
- Original 8-point medallions, red petals, green arabesque vines,
  corner rosettes and thin double gold border.
- Match classical manuscript grandeur without reducing verse contrast.

**Shiraz Garden / باغ شیراز**
- Jade / green silk headpiece, warm aged-paper field, rose and
  pomegranate floral tones, leaf and vine margins.
- A tender, springlike page for love, longing and hope, still tasteful.

**Moonlit Divan / دیوان مهتاب**
- Night-blue arch and silvery gold filigree with muted violet blossoms.
- Works with either Ivory or Midnight reading palette. Actual reading
  surface stays opaque and high contrast, never a Liquid Glass pane.

**All templates**
- The header is separate from the real Persian text.
- The illustrated margins occupy reserved padding and never cover a verse.
- A dense header is allowed on the opening of a poem, not behind every line.
- On narrow layouts, artwork simplifies; only the poem can determine
  text width, never an overlay.
- The border grows with the poem; the headpiece never stretches vertically.
- Metadata and exact Ganjoor source links remain present and selectable.
- The same visual selection applies to the reader AND a Keepsake PNG.
- The user can switch back to Quiet / undecorated text at any time.
- Saved template ID is per app identity via AppStorage, isolated in QA.

## Implementation map

| Design object | GitHub source | Purpose |
|---|---|---|
| Template IDs and colors | Sources/ArashKam/PersianManuscriptTemplates.swift | Native, original SwiftUI design tokens |
| Four-layer vector sar-lawh | PersianIlluminatedHeadpiece | SwiftUI Canvas, stable height, no interaction |
| Continuous floral margins | PersianIlluminatedFrame | SwiftUI Canvas, original flowers/vines/rosettes |
| Reader page | Sources/ArashKam/IlluminatedReaderView.swift | Text remains live, selectable and accessible |
| Reader designer control | Sources/ArashKam/ArashKamApp.swift | Live three-style thumbnail picker |
| Keepsake compositor | Sources/ArashKam/PoetryKeepsake.swift | Same chosen ornament on exported PNG |
| Design metadata | assets/templates/template-tokens.json | Importable Figma-style palette and measurements |
| Editable art | assets/templates/*-headpiece.svg | SVG references for Figma/Illustrator/InDesign handoff |
| Static checks | scripts/check-manuscript-design.py | SVG + source wiring verification |

The SVGs are designer assets/visual references. **The native application
does not load remote SVGs or embed an HTML WebView to render the poetry.**
No third-party artwork or proprietary font files are committed.

## Recommended Figma → SwiftUI production workflow

1. Create three 900×360 **editable headpiece** components from the SVGs,
   plus a **manuscript page** component with independent named layers:
   Paper, Inner border, Flourish margins, Headpiece, Title, Live poem,
   Attribution, and Glass controls.
2. Import palette tokens from template-tokens.json as variables, retaining
   the native template IDs. Set typography rules for real **Nastaliq**
   and modern **Vazirmatn** examples, including words with diacritics.
3. Design at Mac window widths **920, 1220 and 1600** and in a cramped
   three-column detail panel; also test extreme 17/42pt typography.
4. Mark the Figma frames ready for implementation, give the agent the
   Figma frame URL via Figma MCP, and require it to implement in **SwiftUI**,
   not export React/HTML as the shipping app.
5. Run builds and screenshot QA. Keep the Figma component/PNG next to the
   actual Mac screenshot and record **specific visible deviations**,
   e.g. missing flowers, wrong relative headpiece size, clipping at edges,
   loss of poet/source, improper RTL line breaks.
6. Iterate until the app meets the visual contract and live poem remains
   usable; then merge the tested PR. Never merge an unverified visual PR
   merely because the SVG file itself looks attractive.

## macOS QA: mandatory before merge

Run:
    python3 scripts/check-manuscript-design.py
    swift test
    swift build
    swift build -c release
    bash scripts/package-macos.sh --qa

Then verify:
- Each of Royal Lapis, Shiraz Garden and Moonlit appears in the
  inspector as a **distinct illustrated thumbnail** and switches the
  actual page art and the Keepsake Studio card.
- The top 200pt headpiece has the layered pointed arch, decorative
  star/flower filigree and contrasting navy/gold (not a generic rosette).
- The borders have **visible foliage, flowers and medallions**, not
  just a single outline. Zoom and export to confirm no bitmap blurring.
- 920px/1220px/1600px windows; default, 17pt and 42pt; Nastaliq and
  Vazirmatn; both Quiet and Illuminated; Focus and normal library mode.
- An appearance inspector must not clip any poetry. Narrow frames
  simplify floral sidebars rather than forcing extra horizontal width.
- Poem sh1/sh2 identities, verses, user-imported font persistence,
  copy/select, bookmark and source URL are unchanged.
- Keepsake export shows the selected edition at 1440×1800 and preserves
  exact Persian words/diacritics. Test unusual long verses.
- Reduced Motion and Reduced Transparency, keyboard and VoiceOver reading
  order, selection, links and contrast are checked. Decorative art has
  no accessibility labels or click capture.

## Known non-goals and cautions

- Original user screenshots are **not** included in this repository;
  their reuse/licensing status is not established.
- Original three design preview PNGs created during prototyping are
  comparisons, **not** QA captures from macOS.
- Future AI artwork generation must be optional, rights-safe,
  reproducible for the user and kept out of the live text layer.
- PDF, EPUB and legacy .s3db import are separate milestones (#12/#4).
- Babataher complete-poet download blocked by upstream HTTP 403 (#10).
- Native macOS builds and screenshot QA were performed on 2026-11-05; see
  [evidence and remaining deviations](qa/manuscript/README.md). Reference-fidelity
  acceptance remains pending the original supplied reference/concept files.

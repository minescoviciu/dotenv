---
name: presentation-deck
description: Build a single-file HTML slide deck with a consulting-grade chrome (action-titled headlines, tracker strip, classification chip, source line on every slide, takeaway band, page-of-N), Reveal.js as the slide engine, and a DriveNets-inspired palette in light or dark (light default; press T to toggle). Includes opt-in drag-to-pan and scroll-to-zoom on diagrams, Lucide icons, and a library of slide recipes covering executive summary, action-titled workhorse, stat row, 2x2 matrix, horizon, scorecard, before/after, waterfall, agenda, callout, and the editorial classics (numbered list, principle cards, section list, mermaid, closing, pull quote). Use when the user asks to create, draft, scaffold, or update a presentation, slide deck, talk, demo deck, or kickoff deck and wants it to look professional.
---

# presentation-deck

Build a presentation as a single self-contained HTML file. Open it in
any modern browser &mdash; no build step, no server. Reveal.js,
Mermaid, svg-pan-zoom, Lucide, and Geist fonts load from CDN.

The skill is opinionated: Reveal.js drives navigation, our CSS layers
a consulting-grade document design on top, and a small `<script>`
block wires up the diagram pipeline and the light/dark theme toggle.
Start from `templates/deck.html`, edit content, ship.

## Rules

- **Output is always one HTML file.** No separate CSS or JS files,
  no build step. CDNs only. The file must work on a `file://` open.
- **Save decks to `~/presentations/decks/<name>.html`.** Never to
  `/tmp/` &mdash; that location gets wiped, and decks are kept
  long-term.
- **Start from `templates/deck.html`.** It encodes the design system,
  the grid-with-`!important` workaround for Reveal's inline
  `display: block`, the mermaid re-render lifecycle, theme-aware
  Mermaid variables (including auto-rewrite of `classDef` colors for
  dark mode), and the dotted-canvas pattern.
- **Slide 2 is always the executive summary.** One-sentence answer,
  three MECE pillars, decision-needed band, source line. See
  `templates/slide_snippets/10_exec_summary.html`.
- **Headlines are action-titled, not editorial.** Every body slide
  uses `<h2 class="headline">`, which states the slide's conclusion
  in one sentence. Reserve `<h2 class="title">` (with eyebrow + lede)
  for section dividers and the title slide. See "Title grammar"
  below.
- **One recipe per slide.** Pick from `templates/slide_snippets/`
  (numbered 01-18) and see `references/slide_recipes.md` for when
  each fits.
- **Every body slide has a `.source` line in the third grid row.**
  Cite the dashboards, docs, interviews, or model the slide rests on.
  No unsourced numbers.
- **Mermaid diagrams sit inside a `<div class="diagram-wrap">`** card
  with the dotted background. Use `classDef` for colored states; the
  deck auto-rewrites them for dark mode so contrast holds. Pan/zoom
  is OPT-IN &mdash; add `interactive` to the wrap only when the
  diagram is dense enough to need it.
- **Icons are Lucide only. No emoji anywhere.** Slide text, diagram
  labels, comments, captions &mdash; everywhere. See
  `references/icons.md`.
- **Theme is light by default; dark is opt-in.** Either set
  `<html lang="en" data-theme="dark">` or press <kbd>T</kbd>. Dark
  uses neutral gray surfaces; DN navy / cyan are reserved for text,
  borders, and accents &mdash; never as a card background. See
  `references/theme.md`.
- **Draft watermark via `<html data-draft="true">`** &mdash; tilts
  "DRAFT — DO NOT CIRCULATE" across every slide at 6% opacity. Strip
  before sharing externally.
- **Logo:** the DriveNets logos live in `assets/`
  (`DriveNets_Logo-RGB.svg`, `DriveNets_Logo-white.svg`,
  `DriveNets_Logo-RGB_Blue.svg`). The template references the RGB
  variant for light mode and the white variant for dark mode. Copy
  both into `~/presentations/decks/` alongside the deck so the
  `<img src>` paths resolve. Don't fetch logos from the web; only
  use the files shipped in `assets/`.
- **Inline images stay tiny.** Only inline SVGs under ~5 KB. Larger
  images sit alongside the HTML file or load from a URL the user
  provides.

## Title grammar

Every headline on a body slide must be **action-titled**: it states
the slide's conclusion in one sentence a partner could read aloud
and understand cold.

- **Form:** action verb + subject + measurable so-what.
- **Test:** read the deck's headlines back-to-back with nothing else.
  Together they must reconstruct the recommendation. If they don't,
  the headlines are still editorial.
- **Ban:** question-form titles ("How we got here"), gerunds without
  a verb-object pair ("Reducing handoffs"), and decorative captions
  ("Three concerns when shipping features").
- **The `.hl` and `.num-hl` spans** highlight the measurable or the
  verdict, not a decorative noun. Wrap the number, the date, the
  delta &mdash; the part doing argument work.

Before / after:

| Editorial (bad)                                  | Action-titled (good)                                                    |
|--------------------------------------------------|-------------------------------------------------------------------------|
| Three concerns get tangled when we ship.         | Three handoffs slow the pipeline by 4 days; each is avoidable.          |
| The new architecture.                            | One trigger collapses the pipeline from 5 steps to 3.                   |
| Where things live.                               | Each phase has a single owner and a binary exit gate.                   |
| Status update.                                   | One shipped, two to land, one decision needed.                          |

Section dividers and the title slide can carry editorial framing
(`<h2 class="title">` + eyebrow + lede), but every workhorse slide
runs on `<h2 class="headline">`.

## Workflow

### 0. Write the story spine

**Before any HTML exists**, write a five-line spine in chat:

```
Governing question: <one question the audience needs answered>
Answer:             <one sentence; this is slide 2's headline>
Pillar 1:           <MECE supporting argument>
Pillar 2:           <MECE supporting argument>
Pillar 3:           <MECE supporting argument>
Ask:                <the decision or resource you need>
```

Test MECE: each pillar must be necessary, non-overlapping, and
together sufficient to defend the answer. If a pillar can be deleted
without weakening the answer, it isn't load-bearing &mdash; replace
it.

Every body slide that follows sits under exactly one pillar and
either provides evidence (data, diagram, comparison) or addresses an
objection. If a slide can't be tagged to a pillar, cut it.

### 1. Confirm the deck purpose with the user

After the spine is on paper, get:

- **Title and lede** (one-line subtitle).
- **Audience** &mdash; engineering vs leadership shifts the depth.
- **Approximate slide count.**
- **Diagrams needed**, if any.
- **Speaker name and contact** for the title slide.
- **Light or dark default; draft watermark on or off.**

If most of the above is obvious from the brief, infer and proceed;
otherwise ask.

### 2. Copy the template

```bash
mkdir -p ~/presentations/decks
cp /home/dn/dotenv/AI/skills/presentation-deck/templates/deck.html \
   ~/presentations/decks/<name>.html
cp /home/dn/dotenv/AI/skills/presentation-deck/assets/DriveNets_Logo-*.svg \
   ~/presentations/decks/
```

The second `cp` puts the DriveNets logo files next to the deck so
the title slide's `<img src="DriveNets_Logo-RGB.svg">` resolves.

The template starts with eight example slides (title, executive
summary, action-titled list, stat row, mermaid, 2x2 matrix, section
list, closing). Replace the content; keep the chrome shape.

### 3. Set deck-wide identity

In the deck's `<style>` block (top of the file), set:

- The doc name shown in every topbar (`.doc` span).
- The classification text (default: "Confidential &mdash; Draft").
- The tracker labels &mdash; usually 3-5 phase names that map to the
  pillars in the spine.

These appear on every body slide; updating them once is faster than
hunting per-slide.

### 4. Edit slide by slide

The deck shape is:

```
Slide 1:           Title
Slide 2:           Executive summary  (answer + 3 pillars + ask)
Slide 3..N-1:      Body slides, grouped by pillar
Optional dividers: One per pillar boundary, max
Slide N:           Closing  (status + ask)
```

For each body slide:

1. Decide which pillar it sits under (and set the tracker `active`).
2. Pick a recipe from `references/slide_recipes.md`.
3. Open the matching snippet under `templates/slide_snippets/`.
4. Replace one of the example slides in the deck with the snippet
   contents, then fill in: headline, body, takeaway (optional),
   source.

For Mermaid slides, load `references/mermaid_canvas.md` once and
copy the `classDef` block when you need colored states.

### 5. Theme tweaks

If the default DN palette needs adjustment, override CSS custom
properties in the deck's `<style>` block at the top. See
`references/theme.md`. Don't fork the template.

### 6. Verify in a browser

The skill cannot verify decks itself. Tell the user:

```
open ~/presentations/decks/<name>.html
```

They should arrow through every slide and confirm: title renders,
exec summary reads cold, every body slide has a `.source` line, the
tracker strip moves with the section, mermaid diagrams render inside
the dotted card. Press <kbd>T</kbd> to preview the dark variant and
re-check contrast on the diagram. Press <kbd>G</kbd> to jump.

## Quality bar

- [ ] One HTML file, opens directly in a browser, no build step.
- [ ] Deck lives under `~/presentations/decks/`.
- [ ] Slide 2 is the executive summary: one-sentence answer, three
      MECE pillars, takeaway band naming the decision, source line.
- [ ] Every body slide uses `<h2 class="headline">` and is
      action-titled. Reading headlines in sequence reconstructs the
      recommendation.
- [ ] Every body slide has a `.source` line. No unsourced numbers.
- [ ] Topbar carries: doc name + tracker + classification chip +
      page-of-N. Tracker `active` step matches the slide's pillar.
- [ ] Palette and font match `references/theme.md` (DN navy + bright
      blue + cyan, Geist).
- [ ] Dark mode uses neutral gray surfaces &mdash; no DN navy as a
      background. Mermaid colored states stay legible (deck rewrites
      them on theme toggle).
- [ ] Every Mermaid diagram is inside a `<div class="diagram-wrap">`,
      renders as an SVG (not raw text). Pan/zoom is OFF unless the
      wrap also has `interactive`. State categories use `classDef`.
- [ ] Title slide has speaker name and contact; closing slide has a
      `.highlight` decision card.
- [ ] No emoji anywhere. Lucide only.
- [ ] No `<img>` larger than ~5 KB inlined.
- [ ] Both light and dark render without broken contrast.

## References (load on demand)

- `references/slide_engine.md` &mdash; Reveal.js configuration,
  why we override with `!important`, keyboard shortcuts, the
  Mermaid re-render lifecycle, the stagger-fire-once rule.
- `references/slide_recipes.md` &mdash; the eighteen recipes and
  when to use each, plus typical deck shapes (CEO briefing, steerco,
  working session).
- `references/mermaid_canvas.md` &mdash; the diagram-card pattern,
  dotted background, opt-in pan/zoom, classDef for colored states
  with the auto-rewrite for dark mode.
- `references/theme.md` &mdash; palette tokens (light + dark with
  neutral surfaces), typography, accent rules, overriding.
- `references/icons.md` &mdash; Lucide setup, curated icon list,
  the no-emoji rule.

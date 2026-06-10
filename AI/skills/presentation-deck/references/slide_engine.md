# The slide engine (Reveal.js)

The deck uses Reveal.js 5.x as the slide engine, loaded from
jsdelivr. The consulting-grade chrome (topbar with tracker +
classification + page-of-N, action-titled headlines, takeaway band,
source line) is layered on top via CSS overrides. Reveal handles
navigation, hash routing, fade transitions, fullscreen, and
per-slide presence (`.present` class).

## Boot configuration

```js
Reveal.initialize({
  hash: true,
  transition: 'fade',
  width: 1440,
  height: 900,
  margin: 0,
  center: false,
  controls: false,
  progress: false,
  slideNumber: false,
});
```

- **1440 &times; 900 logical**, scaled to fit the viewport by Reveal.
- `center: false` keeps slide content top-aligned (the design needs
  this; centered content breaks the topbar / grid).
- `margin: 0` lets each slide use the full slide area; the design
  controls padding via `padding: 3.4vh 5vw 3vh !important` on
  `.reveal .slides section`.
- Reveal's own progress bar, controls, and slide-number widgets are
  disabled because we paint our own.

## Slide layout — 3-row grid

Each non-title slide is a 3-row grid: chrome (topbar) at the top,
body in the middle, source line anchored at the bottom. The
`!important` overrides defeat Reveal's inline `display: block` on
`.present`:

```css
.reveal .slides section {
  display: grid !important;
  grid-template-rows: auto 1fr auto;
  height: 100% !important;
  width:  100% !important;
  padding: 3.4vh 5vw 3vh !important;
  box-sizing: border-box;
  text-align: left;
}
.reveal .slides section.title-slide {
  grid-template-rows: auto 1fr auto;
  padding: 5vh 6vw !important;
}
.reveal .slides section.section-divider { background: var(--surface); }
```

The title slide also uses a 3-row grid (upper / center / footer).
The section-divider modifier paints a tinted surface so the audience
feels the turn of the page.

## Font sizing

Reveal v5 defaults to `font-size: ~40px` on `.reveal` (based on slide
height). Our base is 26px so back-of-room legibility holds:

```css
.reveal { font-size: 26px; }
```

All slide typography is in `em` units relative to this 26px base.
Reveal scales the whole deck uniformly to fit the viewport, so
everything stays in proportion.

## Stagger animation — fires once

Reveal adds `.present` to the active section. Children of an element
with `class="stagger" data-staggered="0"` animate in with a 70-ms
stepped rise the first time the slide is presented. After the
animation runs (700ms after `slidechanged`), the script flips
`data-staggered` to `"1"`, which removes the CSS selector that fires
the animation. Result: back-arrowing to a slide does not replay the
rise.

```html
<div class="body stagger" data-staggered="0">
  ...
</div>
```

Up to 8 children animate; past that the rest appear immediately.

## Custom chrome — top progress bar, arrow buttons, theme toggle

Three pieces sit outside `.reveal` and stay fixed across slide
transitions:

- A **top** progress bar (`.progress`) at 5px height whose width is
  updated from `Reveal.on('slidechanged')`. Top placement so it's
  visible past the presenter's head.
- Two arrow buttons (`.arrow-btn`) wired to `Reveal.prev()` /
  `Reveal.next()`; their `disabled` state mirrors slide index.
- A custom `T` key handler that flips `data-theme` on `<html>` and
  re-initialises Mermaid; a custom `G` key that prompts for a slide
  number and calls `Reveal.slide(n-1)`.

Reveal's native shortcuts still work: <kbd>&rarr;</kbd> /
<kbd>Space</kbd> / <kbd>PgDn</kbd> for next, <kbd>&larr;</kbd> /
<kbd>PgUp</kbd> for previous, <kbd>F</kbd> for fullscreen,
<kbd>Esc</kbd> for the slide overview.

Print mode (`@media print`) hides arrows, progress, pan-zoom hints,
and the draft watermark so PDF exports stay clean.

## Mermaid rendering

The pipeline runs on first paint and again on every `slidechanged`:

1. **Reset `data-processed`** on every `<pre class="mermaid">` and
   restore its source from `el.dataset.source` (stashed once at
   boot).
2. **Apply dark-mode classDef rewrite** if `data-theme="dark"`.
3. **`mermaid.run({ querySelector: 'pre.mermaid' })`** to render.
4. **Strip `width`/`height`** from the resulting SVG, force
   `width:100%; height:100%; preserveAspectRatio="xMidYMid meet"`.
5. **Attach `svg-pan-zoom`** only to SVGs inside
   `.diagram-wrap.interactive`. Static wraps get no pan-zoom hookup
   and no cursor change.

On theme toggle the pipeline re-runs after Mermaid is re-initialised
so node colors AND classDef text colors pick up the new palette.

## Theme switching

`<html data-theme="dark">` to default to dark. Otherwise light is
default. <kbd>T</kbd> at runtime toggles.

## Draft watermark

`<html data-draft="true">` activates a 45° "DRAFT — DO NOT
CIRCULATE" overlay at 6% opacity across the whole slide. Useful for
work-in-progress decks shared internally. Strip the attribute before
final export. Print rules hide the watermark in PDF.

## What we deliberately don't enable

- **Vertical slide stacks.** The grid layout assumes flat slides;
  nested `<section><section>...</section></section>` would break the
  topbar.
- **Reveal's slide-number widget / progress / controls.** We render
  our own that match the editorial style. The CSS hides Reveal's
  defaults with `display: none !important`.
- **Slide transitions other than `fade`.** Anything else (`slide`,
  `convex`) shifts the document chrome and looks wrong.
- **Fragments.** The stagger animation pre-plays once per slide
  (and only once); that's the whole reveal. If you need step-by-step
  bullets, use Reveal's `.fragment` class normally, but the design
  wasn't tuned for it.

## PDF export

Open the deck with `?print-pdf` in the URL and use the browser's
print dialog. The `@media print` block strips the chrome the
audience doesn't need on paper.

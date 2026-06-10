# Theme &mdash; palette, typography, light / dark

Two themes ship in the template: **light** (default) and **dark**
(via `<html data-theme="dark">`). Both use the DN palette, but with
an important distinction:

- **Light:** DN navy is the primary text color, DN bright blue is
  the accent, DN cyan is the secondary accent. Surfaces are warm
  off-white.
- **Dark:** surfaces are **neutral dark grays** (not navy). DN
  colors (cyan, blue, navy) are used only for text, accents, and
  borders &mdash; never as background.

## Switching themes

- **Default light**: do nothing. `<html lang="en">`.
- **Default dark**: `<html lang="en" data-theme="dark">`.
- **Draft watermark**: `<html lang="en" data-draft="true">`.
- **At runtime**: press <kbd>T</kbd>. Mermaid re-initialises with the
  new palette and `classDef` colors are auto-rewritten for dark mode
  so contrast holds.

## Tokens (light)

| Token              | Value                       | Role                                  |
|--------------------|-----------------------------|---------------------------------------|
| `--bg`             | `#fafbfc`                   | Slide background (warm off-white)     |
| `--surface`        | `#f1f5fa`                   | Section-divider bg, hover surface     |
| `--surface-2`      | `#e6edf5`                   | Deeper surface (rare)                 |
| `--border`         | `#d6dee9`                   | Card and list borders                 |
| `--border-strong`  | `#b8c5d6`                   | Arrow-button border, kbd outline      |
| `--fg`             | `#001946`                   | Primary text (DN deep navy)           |
| `--fg-mid`         | `#475569`                   | Body copy, descriptions               |
| `--fg-muted`       | `#5b6776`                   | Meta, footnotes, attribution          |
| `--accent`         | `#0555ff`                   | Primary accent (DN bright blue)       |
| `--accent-bright`  | `#4bbefa`                   | Secondary accent (DN cyan)            |
| `--accent-deep`    | `#001946`                   | Inline-code text, takeaway band bg    |
| `--accent-soft`    | `#dde7ff`                   | Chip background, classDef fill        |
| `--accent-softer`  | `#eef3ff`                   | Inline-code background, mermaid bg    |
| `--warn`           | `#b88500`                   | Callout border/text on warn cards     |
| `--warn-soft`      | `#fff5d6`                   | Warn callout background               |
| `--alert`          | `#c25400`                   | Alert callout border/text, classification |
| `--alert-soft`     | `#ffe6cc`                   | Alert callout background              |
| `--ok`             | `#157a40`                   | Success states, "up" deltas           |
| `--ok-soft`        | `#dcf5e6`                   | Ok callout / delta background         |
| `--card-bg`        | `#ffffff`                   | Card / tree / diagram background      |
| `--dot-color`      | `rgba(0,25,70,0.08)`        | Mermaid card dot pattern              |

## Tokens (dark) &mdash; neutral surfaces

Set via `html[data-theme="dark"]`. Surfaces are **neutral grays**,
not DN navy.

| Token              | Value                              | Notes                              |
|--------------------|------------------------------------|------------------------------------|
| `--bg`             | `#07090c`                          | Near-black neutral                 |
| `--surface`        | `#11141a`                          | Section-divider bg                 |
| `--surface-2`      | `#1a1f27`                          | Deeper surface                     |
| `--border`         | `rgba(255,255,255,0.14)`           | Visible hairline on dark           |
| `--border-strong`  | `rgba(255,255,255,0.26)`           |                                    |
| `--fg`             | `#ffffff`                          |                                    |
| `--fg-mid`         | `#cfd4dc`                          |                                    |
| `--fg-muted`       | `#99a0ab`                          |                                    |
| `--accent`         | `#4bbefa`                          | Cyan is the primary in dark        |
| `--accent-bright`  | `#7cd6ff`                          |                                    |
| `--accent-deep`    | `#0555ff`                          | Takeaway band bg                   |
| `--accent-soft`    | `rgba(75,190,250,0.20)`            | Chips, classDef fill               |
| `--accent-softer`  | `rgba(75,190,250,0.10)`            | Inline-code bg, wash               |
| `--warn`           | `#fac80f`                          |                                    |
| `--warn-soft`      | `rgba(250,200,15,0.18)`            |                                    |
| `--alert`          | `#ff9c2e`                          |                                    |
| `--alert-soft`     | `rgba(255,156,46,0.18)`            |                                    |
| `--ok`             | `#4ad07a`                          |                                    |
| `--ok-soft`        | `rgba(74,208,122,0.18)`            |                                    |
| `--card-bg`        | `#1a1f27`                          | Neutral dark, **not navy**         |
| `--dot-color`      | `rgba(255,255,255,0.07)`           | Mermaid card dot pattern           |

### Why neutral surfaces in dark mode

Earlier versions used DN navy for the dark-mode card surfaces. The
blue-on-blue made everything feel monochromatic and pushed the
accent color into competition with the surface. Using neutral
grays for surfaces lets the DN colors do their job &mdash; they're
the things you want the eye to land on.

The dark-mode `--card-bg` (`#1a1f27`) sits ~1.7:1 above the page bg
(`#07090c`) so cards visibly lift off the canvas. If you fork this
palette, preserve that separation; squeezing it kills the
card-on-page metaphor that the whole design rests on.

## Spacing scale

| Token        | Value | Use                                                            |
|--------------|-------|----------------------------------------------------------------|
| `--space-1`  | 4px   | Tight inline gaps, chip padding                                |
| `--space-2`  | 8px   | Card internal gap                                              |
| `--space-3`  | 14px  | Default gap between body children                              |
| `--space-4`  | 22px  | Section-level gap, between body blocks                         |
| `--space-5`  | 34px  | Hero spacing                                                   |
| `--space-6`  | 52px  | Title-slide whitespace                                         |

The deck uses `em`-based spacing in most places to scale with text;
use the `--space-*` tokens for fixed gaps that should not scale.

## Radius scale

| Token         | Value | Use                                |
|---------------|-------|------------------------------------|
| `--radius-sm` | 4px   | Chips, classification, bars        |
| `--radius-md` | 6px   | Cards, buttons, callouts           |
| `--radius-lg` | 10px  | Reserved for hero containers       |

## Typography

- **Sans**: [Geist](https://vercel.com/font/sans),
  weights 300/400/500/600/700.
- **Mono**: [Geist Mono](https://vercel.com/font/mono),
  weights 400/500.
- Both loaded from Google Fonts (`display: swap`).
- Headings use 500/600 weight with negative letter-spacing
  (`-0.018em` to `-0.025em`) for a tight editorial feel.
- `font-feature-settings: 'ss01', 'cv11', 'tnum'` is active on
  `.reveal` so stylistic sets and tabular numerals render correctly.

### Base font-size and the scale

Reveal sets the `.reveal` base font-size; we override to 26px so the
slides are legible from the back row of a meeting room (the prior
22px was tuned for a writer's laptop). All slide typography uses
`em` multiples of that base:

| Element              | Size      | Computed at 26px base |
|----------------------|-----------|------------------------|
| Display title (h1)   | `2.6em`   | ~68px                  |
| Section title (h2)   | `1.55em`  | ~40px                  |
| Action headline (h2) | `1.4em`   | ~36px                  |
| Lede                 | `0.95em`  | ~25px                  |
| Body / desc          | `0.86em`  | ~22px                  |
| Source line          | `0.58em`  | ~15px                  |
| Mono labels          | `0.62em` to `0.7em` | ~16-18px     |

Reveal scales the entire deck to fit the viewport, so everything
stays in proportion at any window size.

## Accent usage rules

- **`--accent`** &mdash; structure: eyebrow line, tracker active
  step, numbered-list number chips, card pillar label, progress bar
  fill, highlighted words in titles (`<span class="hl">`).
- **`--accent-bright`** &mdash; title-slide brand-mark gradient,
  takeaway band label.
- **`--accent-deep`** &mdash; inline-code text on light, takeaway
  band background on both light and dark.
- **`--warn`** and **`--alert`** are border / text colors on light
  backgrounds. They fail contrast as text on the page bg directly
  &mdash; always pair them with their `-soft` partner as the
  background.
- One callout flavor per slide, max. If you find three different
  accents on the same slide, drop one.

## Overriding the palette

Add an override block at the top of the deck's `<style>`:

```css
:root {
  --accent:        #7c5cff;
  --accent-soft:   #ece6ff;
  --accent-softer: #f5f1ff;
}
html[data-theme="dark"] {
  --accent:        #b794ff;
  --accent-soft:   rgba(183, 148, 255, 0.20);
  --accent-softer: rgba(183, 148, 255, 0.10);
}
```

Override tokens, never rules.

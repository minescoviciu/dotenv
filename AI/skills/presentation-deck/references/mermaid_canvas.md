# Mermaid diagrams &mdash; dotted card with colored states

Diagrams sit inside a `<div class="diagram-wrap">` card with a dotted
background and a hairline border. Mermaid is configured with
`theme: 'base'` and theme variables sourced from CSS custom
properties &mdash; light and dark both work without per-diagram
tweaks. The deck **auto-rewrites `classDef` colors** in dark mode so
text contrast holds on the dark card surface.

## The slide block

```html
<section>
  <div class="topbar"> &hellip; </div>
  <div class="body" style="gap: 0.7em;">
    <h2 class="headline">Action headline naming what the diagram proves.</h2>
    <div class="diagram-wrap">
      <pre class="mermaid">
flowchart LR
    A[Start] --> B{Gate}
    B -- yes --> C[Do]
    B -- no  --> D[Skip]
    C --> E([Done])
    D --> E
      </pre>
    </div>
  </div>
  <div class="source"><span class="label">Source</span>...</div>
</section>
```

Two non-negotiables:

- `<div class="diagram-wrap">` wraps the `<pre>` &mdash; gives the
  card its dotted background, border, padding.
- `<pre class="mermaid">` is what Mermaid looks for.

The wrap flexes to fill the slide's remaining height; nothing else
needs sizing.

## Pan/zoom is opt-in

By default `.diagram-wrap` is a static card. Add `interactive` to
turn on drag-to-pan and scroll-to-zoom:

```html
<div class="diagram-wrap interactive">
  <pre class="mermaid">...</pre>
</div>
```

Only use `interactive` when the diagram is too dense to read static.
A hand-cursor over a static diagram during a talk is visual noise.

## What the deck wires up for you

| Behaviour                  | Where it comes from                                  |
|----------------------------|------------------------------------------------------|
| Dotted background          | `.diagram-wrap` `background-image` + `--dot-color`   |
| Drag to pan                | `svg-pan-zoom`, **only on `.interactive` wraps**     |
| Scroll-wheel zoom          | `svg-pan-zoom` (zoom under cursor), interactive only |
| Double-click to zoom in    | `svg-pan-zoom`, interactive only                     |
| Built-in zoom controls     | `controlIconsEnabled: true`, interactive only        |
| Fit on viewport resize     | Resize listener in the deck script                   |
| Theme-aware node colors    | `mermaid.initialize` reads `--*` custom properties   |
| classDef rewrite for dark  | `darkClassDefRewrite()` in the deck script           |
| Re-init on theme toggle    | `T` key flips `data-theme`, then runs `initMermaid`  |
| Hint overlay (top-right)   | `attachPanZoom()` adds it once per interactive wrap  |

## Colored states (classDef)

Use `classDef` inside the diagram body to call out state categories.
**Write the light-mode palette only** &mdash; the deck script
auto-rewrites the fills, strokes, and text color for dark mode so
white text reads on the tinted fill instead of dark text on a dark
card.

```
classDef accent fill:#dde7ff,stroke:#0555ff,color:#001946,stroke-width:1.5px
classDef warn   fill:#fff5d6,stroke:#b88500,color:#3d2c00,stroke-width:1.5px
classDef ok     fill:#dcf5e6,stroke:#157a40,color:#0a4f24,stroke-width:1.5px
classDef alert  fill:#ffe6cc,stroke:#c25400,color:#5a2400,stroke-width:1.5px

class A,B accent
class C,E,F warn
class H,I ok
```

### What the dark-mode rewrite does

The script in `deck.html` (`darkClassDefRewrite`) replaces the four
classDef lines above with white-text-on-tinted-fill variants when
`data-theme="dark"` is active:

```
classDef accent fill:rgba(75,190,250,0.22),stroke:#7cd6ff,color:#ffffff,stroke-width:1.5px
classDef warn   fill:rgba(250,200,15,0.22),stroke:#fac80f,color:#ffffff,stroke-width:1.5px
classDef ok     fill:rgba(74,208,122,0.22),stroke:#4ad07a,color:#ffffff,stroke-width:1.5px
classDef alert  fill:rgba(255,156,46,0.22),stroke:#ff9c2e,color:#ffffff,stroke-width:1.5px
```

The rewrite is name-based: it matches `classDef <name> ...` lines
where `<name>` is one of `accent`, `warn`, `ok`, `alert`. If you
define custom classDef names, the rewrite leaves them alone &mdash;
write light + dark versions manually with `<br/>` conditionals or
override `darkClassDefRewrite` to recognise them.

## Mermaid syntax tips that hold up

- Use `stateDiagram-v2`, not the legacy `stateDiagram`.
- Long state labels: `state "Long label" as Name`. Don't put `<br/>`
  in state labels &mdash; renders literally.
- For flowcharts and sequence diagrams, `<br/>` inside node labels
  works.
- Subgraph titles in square brackets accept spaces and colons.
- `classDef` + `class Node1 name` works in `flowchart`,
  `stateDiagram-v2`, and `sequenceDiagram` (limited).
- Notes: `note right of NodeName ... end note` (multi-line OK).
- Avoid emoji in node labels &mdash; the deck's no-emoji rule
  applies to diagrams too.

## Diagram backgrounds in dark mode

In dark mode the deck uses **neutral dark grays** for surfaces
(`#07090c` page background, `#1a1f27` card-bg). Mermaid's `mainBkg`
points at the surface-2 token, not at DN navy &mdash; so default
node fills are neutral gray with DN cyan borders and white text. The
classDef rewrite handles the colored states.

If you find dark-mode node colors that look off, check that the
relevant CSS token still routes to a surface (e.g. `--surface-2`)
and not to a brand color.

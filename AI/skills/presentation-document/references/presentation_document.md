# Presentation Document Layer

Use this reference for the HTML output layer: file location, visual style, Mermaid behavior, and verification. This is separate from the code-overview research method.

## Output Contract

- Save exactly one durable HTML file to `~/presentations/decks/<safe-slug>.html`.
- Use lowercase safe filenames. Do not use `index.html`, hidden files, nested output paths, spaces, `?`, `#`, or uppercase `.HTML`.
- The presentations server lists top-level lowercase `*.html` files from `~/presentations/decks` and serves them at root-relative URLs such as `http://<host>:8000/<safe-slug>.html`.
- Put a meaningful `<title>` near the top of the file so the server index displays a useful card.
- Keep the output static. CDN Mermaid, svg-pan-zoom, Lucide, and fonts are acceptable.

## Template

Copy `templates/document.html` to the output path and replace placeholders. The template provides:

- DriveNets-inspired light/dark theme tokens reused from the `presentation-deck` skill.
- Responsive scrollable document layout with sticky table of contents.
- Source-note styling, cards, callouts, tables, and print behavior.
- Wide comparison-table utilities: wrap dense tables in `.wide-table-wrap`, use `.wide-table.cols-N`, and tune `--wide-table-min-width` / `--wide-table-col-min-width` when columns need more room.
- Mermaid rendering with theme-aware colors.
- `T` key theme toggle.
- Interactive Mermaid diagrams with drag-to-pan, scroll-wheel zoom, double-click zoom, built-in zoom controls, and a larger non-fullscreen modal view.

## Mermaid Rules

- Wrap diagrams in `<div class="diagram-wrap interactive">`.
- Use `<pre class="mermaid">` for Mermaid source.
- Keep diagrams source-grounded and add a nearby `.source` note.
- Remove `interactive` only for very small diagrams where controls add noise.
- Prefer `flowchart LR` for component maps, `sequenceDiagram` for runtime flows, and `stateDiagram-v2` for lifecycle/state behavior.
- Use light-mode `classDef` colors in source; the template rewrites `accent`, `warn`, `ok`, and `alert` class definitions for dark mode.

## Table Width Rules

- Use plain `<table>` for compact content.
- For dense comparison matrices, use:
  `<div class="wide-table-wrap"><table class="wide-table cols-4" style="--wide-table-min-width: 1400px; --wide-table-col-min-width: 320px;">...</table></div>`.
- Pick a min width large enough that the longest expected cells can be scanned without cramped wrapping.
- Keep text size readable; prefer horizontal scrolling over reducing font size aggressively.
- Documents with `.wide-table` tables get a `Tables: Full/Normal` control. Full preserves the configured wide min-width; Normal removes the extra min-width and fits the table to the page.

## Verification

Before finishing:

- Open the HTML directly or through the server.
- Confirm light and dark modes both render Mermaid diagrams.
- Confirm the larger diagram modal opens, stays bounded inside the viewport, and supports pan/zoom.
- Confirm source notes identify where claims came from.
- Confirm the URL is root-relative, never `/decks/<file>.html`.

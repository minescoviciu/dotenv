---
name: presentation-document
description: Create static, scrollable HTML documents with DriveNets-inspired styling, Mermaid diagrams, light/dark theme support, drag/zoom diagram controls, and a bounded larger diagram modal. Use when the user asks for a human-readable HTML document, architecture document, code overview document, technical design page, or any non-deck presentation saved under ~/presentations/decks.
---

# Presentation Document

Create a single-page HTML document, not a slide deck. The output is a durable, static, scrollable document that opens directly in a browser and can be served by the existing presentations server.

Save final documents to `~/presentations/decks/<safe-slug>.html`. The server lists top-level lowercase `*.html` files from that directory and serves them at root-relative URLs such as `http://<host>:8000/<safe-slug>.html`.

## Workflow

1. Confirm the document title, audience, scope, and output filename when they are not clear.
2. Load `references/presentation_document.md`.
3. Copy `templates/document.html` to `~/presentations/decks/<safe-slug>.html`.
4. Replace placeholders with the user's content or content supplied by another skill such as `code-overview`.
5. Use Mermaid for diagrams and source notes for claims.
6. Verify the HTML is static, has a useful `<title>`, renders Mermaid in light and dark modes, and appears in the server index.

## Output Rules

- Output exactly one HTML file by default.
- Use lowercase safe filenames: `area_architecture.html`, not `index.html`, hidden files, nested paths, names with spaces, or uppercase `.HTML`.
- Keep the file static. CDN Mermaid, svg-pan-zoom, Lucide, and fonts are acceptable.
- Use the bundled template instead of creating a new design from scratch.
- Do not include secrets, credentials, tokens, or private data in the document.

## Diagram Rules

- Wrap Mermaid diagrams in `<div class="diagram-wrap interactive">`.
- Use `<pre class="mermaid">` for Mermaid source.
- Keep diagrams readable; split dense diagrams rather than shrinking text.
- The template supports drag-to-pan, scroll zoom, double-click zoom, built-in zoom controls, and a bounded larger modal view.
- Press `T` to toggle light/dark mode.

## Table Width Rules

- Use regular tables for compact two- or three-column content that fits the page.
- For dense comparison tables or long text columns, wrap the table in `<div class="wide-table-wrap">` and add `class="wide-table cols-N"` to the table.
- Increase column width with inline CSS variables when needed, for example: `<table class="wide-table cols-4" style="--wide-table-min-width: 1400px; --wide-table-col-min-width: 320px;">`.
- Prefer horizontal scrolling for dense comparison tables instead of shrinking text until it becomes hard to read.
- The template includes a `Tables: Full/Normal` button when `.wide-table` tables are present. Full uses the configured wide min-width; Normal fits the table to the page width.

## Verification

Before finishing, verify:

- The file exists at `~/presentations/decks/<safe-slug>.html`.
- The `<title>` is meaningful and near the top of the file.
- Mermaid diagrams render in both themes.
- Interactive diagrams can pan/zoom and open in the larger modal.
- The server URL is root-relative, never `/decks/<safe-slug>.html`.

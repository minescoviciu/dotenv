# Icons &mdash; Lucide via CDN

Use [Lucide](https://lucide.dev) (ISC licensed, free for commercial
use). Loaded in the template from unpkg:

```html
<script src="https://unpkg.com/lucide@latest"></script>
```

After `lucide.createIcons()` runs, every `<i data-lucide="name"></i>`
in the DOM becomes an inline SVG. The deck calls `createIcons()` on
boot and after every Mermaid re-render, so icons added inside slide
content are picked up automatically.

**Never use emoji in slides.** Use Lucide for any glyph; use plain
typography otherwise. Decks are presented in professional contexts
and emoji read as casual.

## Usage

```html
<span class="icon-accent"><i data-lucide="zap"></i></span>
<span class="icon-warn"><i data-lucide="alert-triangle"></i></span>
<span class="icon-alert"><i data-lucide="flame"></i></span>
```

The wrapper classes tint the icon via the matching theme token. A
plain `<i data-lucide="...">` inherits the current text color.

Icons size from font-size (the template sets `width: 1em; height:
1em` globally), so they scale naturally with surrounding text.

## Curated set for engineering / leadership decks

Pick from this list before browsing the full Lucide catalog &mdash;
these match the visual weight of the deck and the typical talk
vocabulary.

| Concept                   | Icon name           |
|---------------------------|---------------------|
| Bug / defect              | `bug`               |
| Pull request              | `git-pull-request`  |
| Commit / branch           | `git-branch`        |
| Speed / quick action      | `zap`               |
| Server / infra            | `server`            |
| Cloud                     | `cloud`             |
| Database                  | `database`          |
| Network / pipeline        | `share-2`           |
| Alert / warning           | `alert-triangle`    |
| Strong alert / fire       | `flame`             |
| Success / done            | `check-circle`      |
| Failure                   | `x-circle`          |
| Time / latency            | `clock`             |
| Search / investigate      | `search`            |
| Eye / monitor             | `eye`               |
| Trust / safety            | `shield-check`      |
| Sparkles / launch         | `sparkles`          |
| Right chevron (continue)  | `chevron-right`     |
| External link             | `external-link`     |
| Settings / configure      | `settings`          |
| User / team               | `users`             |
| File / document           | `file-text`         |
| Folder                    | `folder`            |

## Don'ts

- **No emoji.** Ever. Use Lucide.
- **Don't mix icon libraries.** Lucide everywhere or nothing.
- **Don't put icons on every bullet.** One icon per bullet on a
  bullet slide is the maximum; ideally only highlight 2-3 of the
  bullets.
- **Don't oversize icons.** They look best inline at `~1em`. If you
  need a bigger graphic for a hero slide, use a hand-crafted SVG
  illustration, not a giant icon.

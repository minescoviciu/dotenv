# Slide recipes

Eighteen slide recipes, each backed by a snippet under
`templates/slide_snippets/`. Pick by intent.

## Recipe table

| #  | Recipe              | Headline form                       | When to use                                                                  | Snippet                          |
|----|---------------------|-------------------------------------|------------------------------------------------------------------------------|----------------------------------|
| 01 | Title               | Display title states the answer     | Opening slide. Brand mark, meta block, display title, lede.                  | `01_title.html`                  |
| 02 | Section divider     | Editorial framing (h2.title + lede) | Marks a new part. Tracker active step shifts. One per pillar boundary max.   | `02_section.html`                |
| 03 | Numbered list       | Action headline + measurable        | 3-5 sequenced or parallel supporting facts under one conclusion.             | `03_content_bullets.html`        |
| 04 | Two-column (tree)   | Action headline                     | Engineering supplement only. "Where things live on disk." Skip for leadership.| `04_two_column.html`            |
| 05 | Mermaid diagram     | Action headline interpreting diagram| One full-width diagram card. Pan/zoom is opt-in via `.interactive`.          | `05_mermaid_canvas.html`         |
| 06 | Pull quote          | No headline; primary-source quote   | One per deck max. Customer / regulator / engineer. Attribution required.     | `06_quote.html`                  |
| 07 | Closing cards       | Action headline naming the count    | 2x2 grid: done / next / after / decision-needed. Last body slide.            | `07_closing.html`                |
| 08 | Pillar / option cards| Action headline + parallel pillars | 3-up MECE pillars, 2x2 deep cards, or 4-up compact. Name the dimension.      | `08_principle_cards.html`        |
| 09 | Section list        | Action headline + invariant         | Key/value table-style list. Anatomy of a doc, phases with owners.            | `09_section_list.html`           |
| 10 | Executive summary   | One-sentence answer                 | **Always slide 2.** Three MECE pillars + decision-needed band.               | `10_exec_summary.html`           |
| 11 | Stat row            | Action headline interpreting numbers| 3-4 KPI tiles with deltas. Use when numbers carry the slide.                 | `11_stat_row.html`               |
| 12 | 2x2 matrix          | Action headline naming the quadrant | Prioritisation, positioning, option analysis.                                | `12_matrix_2x2.html`             |
| 13 | Horizon / timeline  | Action headline naming the commitment| 3-5 columns × 3-5 swimlanes with bars; today line is mandatory.            | `13_horizon.html`                |
| 14 | Scorecard           | Action headline + recommended option| Multi-column comparison with Harvey balls. Footnotes supported.              | `14_scorecard.html`              |
| 15 | Before / after      | Action headline naming the removal  | Two-panel split with a delta chip between.                                   | `15_before_after.html`           |
| 16 | Waterfall / bridge  | Action headline naming the source   | Five bars: baseline + contributors + total. Heights set via `--h`.           | `16_waterfall.html`              |
| 17 | Agenda              | Action headline + duration          | 5-8 items. Use early (slide 2-3) in decks > 10 slides.                       | `17_agenda.html`                 |
| 18 | Callout             | n/a (embed)                         | NOT a slide. Bordered note inside any body slide. Variants: warn/alert/ok.   | `18_callout.html`                |

## Choosing rules

- **Title** (01) and **executive summary** (10) are mandatory.
  Closing (07) is mandatory on any deck with an ask.
- **Workhorse pick:** when in doubt, use the numbered list (03), the
  stat row (11), or pillar cards (08) — these absorb 60-70% of any
  deck.
- **Numbered list (03):** max 5 items. Past that, split.
- **Pillar cards (08):**
  - `cards three-up` for 3 MECE pillars (preferred for exec summary).
  - `cards` 2x2 for 4 pillars / options / risks.
  - `cards compact` for 6-8 items in a 4-up grid.
- **Two-column / tree (04):** engineering decks only. In a leadership
  deck, switch to a stat row (11) or section list (09).
- **Mermaid (05):** one diagram per slide. Pan/zoom is off by default;
  add `interactive` to `.diagram-wrap` only when the diagram is too
  dense to read static.
- **Pull quote (06):** at most one per deck, and only from a primary
  source (named person, doc, ticket). Decorative aphorisms do not
  earn this slot.
- **Section dividers (02):** one every 4-6 slides at most, and only
  at pillar boundaries.
- **2x2 matrix (12), scorecard (14):** at most one of each per deck.
- **Horizon (13):** when there's a date in the answer. Always
  include the `today-line`.
- **Waterfall (16):** when the answer is "how a number moved." Five
  bars max.

## Typical deck shapes

**10-slide leadership briefing**

```
[01 title] -> [10 exec summary] -> [03 numbered: today's friction]
-> [11 stat row: the validated savings]
-> [12 matrix: where to invest]
-> [05 mermaid: tomorrow's flow]
-> [09 section list: phase plan]
-> [13 horizon: timeline + today line]
-> [07 closing]
```

**25-slide steerco**

```
[01 title] -> [10 exec summary] -> [17 agenda]
-> [02 section: context] -> [03 numbered] -> [11 stat row] -> [05 mermaid]
-> [02 section: findings] -> [11 stat row] -> [15 before/after] -> [16 waterfall]
-> [02 section: recommendation] -> [12 matrix] -> [14 scorecard] -> [08 pillar cards] -> [05 mermaid]
-> [02 section: plan] -> [13 horizon] -> [09 section list] -> [08 risk cards]
-> [07 closing]
```

**5-slide engineering update**

```
[01 title] -> [10 exec summary] -> [03 numbered: what changed]
-> [05 mermaid: the new flow] -> [07 closing]
```

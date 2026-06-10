---
name: code-overview
description: Research and synthesize source-grounded architecture and code overviews for unfamiliar code areas. Use when the user asks to understand a new repository area, module, service, feature flow, architecture design, runtime behavior, dependencies, tests, or "how this code works"; pair with the presentation-document skill when the overview should become a durable HTML document.
---

# Code Overview

Research how a code area works and synthesize a source-grounded architecture overview. This skill owns discovery, subagent coordination, and technical content. Use `presentation-document` for the HTML rendering layer when the user wants a durable document.

## Workflow

1. Clarify the target area only if it is not discoverable from the prompt or current repo.
2. Inspect locally first: file tree, manifests, entrypoints, configs, tests, docs, owners, and high-signal symbols. Prefer `rg` and `rg --files`.
3. For broad or unfamiliar areas, spawn adaptive read-only explorer subagents with disjoint scopes. See `references/code_overview_method.md`.
4. Synthesize findings into an architecture story. Resolve conflicts with direct source checks.
5. Produce a structured overview with Mermaid diagram source and source notes.
6. If the user wants HTML, invoke/use `presentation-document` to render the overview into `~/presentations/decks/<safe-slug>.html`.

## Research Rules

- Load `references/code_overview_method.md` before researching.
- Use source references throughout: file paths, commands, tests, docs, or explicit confidence notes.
- Do not mutate product code while researching unless the user separately asks for code changes.
- Do not include secrets, credentials, tokens, or private data in the output. Stop and alert the user if discovered.
- Keep Mermaid diagrams as source blocks that a renderer can place inside a document.

## Document Shape

The document must include:

- Executive summary.
- Component/system map.
- Main runtime or request flows.
- Key interfaces, schemas, APIs, or protocols.
- Configuration and deployment notes when present.
- Test/debug map.
- Open questions and confidence notes.

## Diagrams As Content

Use Mermaid for architecture and flow diagrams. Prefer simple diagrams that explain ownership, sequence, data movement, and failure handling. Keep diagrams source-grounded; every diagram needs a nearby source note.

Use these common diagram types:

- `flowchart LR` for component maps and pipelines.
- `sequenceDiagram` for request or event lifecycles.
- `stateDiagram-v2` for lifecycle/state behavior.
- `classDiagram` only when types/classes are the actual teaching object.

## Verification

Before finishing, verify:

- The overview answers what the area does, how it works at runtime, what contracts it exposes, how it is configured, and how it is tested.
- Source notes identify where claims came from.
- Major diagrams have source notes and are simple enough to read.
- Open questions and confidence notes are explicit.

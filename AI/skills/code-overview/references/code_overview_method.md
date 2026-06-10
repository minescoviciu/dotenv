# Code Overview Method

Use this reference for code research, synthesis, and document content. This is separate from the HTML presentation layer.

## Research Workflow

Run a targeted local pass before delegating:

- `rg --files` to understand repo shape and likely ownership.
- `rg -n` for feature names, route names, type names, config keys, log strings, tests, and docs.
- Inspect manifests and entrypoints: package files, build files, service definitions, CLIs, main modules, migrations, and test configs.
- Read high-signal files fully; skim generated or repetitive files.

Use read-only explorer subagents when the area is broad, unfamiliar, cross-cutting, or likely to benefit from parallel search. Skip subagents for tiny single-file questions.

Spawn two to four explorers with disjoint scopes:

- Entrypoints and control flow: where requests/events/commands enter and what calls what.
- Data model and contracts: types, schemas, messages, API boundaries, validation.
- Runtime and configuration: deployment, startup, flags, environment, logs, metrics.
- Tests and failure modes: test coverage, fixtures, mocks, common errors, debug paths.

Example prompt:

```text
Read-only exploration only. Inspect <repo/path> for <area>. Focus on <scope>.
Report: key files, responsibilities, flow summary, source-grounded facts, open questions.
Do not modify files.
```

## Synthesis Rules

- Trust subagents for scoped discovery, but verify surprising or central claims with direct source inspection.
- Merge duplicate findings into one architecture story.
- Prefer runtime behavior over package inventory.
- If subagents disagree, inspect the source path that decides the behavior.
- Track confidence: high for direct code/tests, medium for inferred call chains, low for stale docs or naming-only matches.

## Required Document Sections

1. Executive summary
   - One paragraph explaining what the area does and why it exists.
   - Three to five bullets covering the most important concepts.
   - A confidence note if discovery was partial.

2. Orientation
   - Scope boundary: what is included and excluded.
   - Primary files, packages, services, or binaries.
   - Important external dependencies or adjacent systems.

3. Component map
   - Mermaid `flowchart LR` showing the main components and relationships.
   - Brief explanation of each component's responsibility.
   - Source note listing files or docs used to build the map.

4. Main flows
   - One section per important lifecycle, request path, event path, or control path.
   - Prefer `sequenceDiagram` for cross-component interactions.
   - Explain triggers, validation, state transitions, error paths, and outputs.

5. Interfaces and data contracts
   - Public APIs, CLIs, config keys, schemas, database tables, message formats, or protocol objects.
   - Include type names and paths, but avoid large code dumps.

6. Runtime and operations
   - How the area is started, configured, deployed, monitored, or debugged.
   - Include logs, metrics, feature flags, env vars, and failure modes when present.

7. Test and debug map
   - Unit, integration, and system tests that cover the area.
   - Useful commands, fixtures, mocks, and representative failing/debug paths.

8. Open questions
   - Unknowns that remain after source inspection.
   - Risky assumptions.
   - Suggested next files or runtime checks.

## Writing Rules

- Write for an engineer entering the area tomorrow.
- Favor concrete names over abstract summaries.
- Use short sections and explanatory paragraphs, not slide fragments.
- Keep diagrams readable. Split dense diagrams rather than shrinking text.
- Every major claim needs a source note: file path, test, command, doc, or subagent finding.
- Distinguish facts from inference. Say "Inferred from ..." when behavior is not directly documented.
- Do not include secrets or sensitive data.

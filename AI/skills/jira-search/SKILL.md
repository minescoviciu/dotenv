---
name: jira-search
description: Search Jira issues for Team-MW-Services using saved filters for bugs, CI bugs, closed bugs, closed CI bugs, Polaris bugs, and team epics. Use when users ask to find, triage, compare, or link Jira bugs/epics, especially when terms like bug, CI bug, closed bug, closed CI bug, polaris, or epic are used and must map to team-specific defaults.
---

# Jira Search

Use this skill to search Jira consistently for Team-MW-Services.

## Mandatory Rules

- Use Jira MCP tools only.
- If Jira MCP is unavailable, state that clearly and stop the Jira search.
- Do not use Jira `text` query mode.
- Do not use `summary` or `description` clauses in JQL (for example `summary ~ ...` or `description ~ ...`).
- Always search in this order after loading candidate issues: title/summary first, description second, comments third.
- For comments, prioritize newer comments before older comments.
- When the user asks for a list of tickets, always include a clickable Jira link for the result set (saved filter URL when applicable; otherwise `https://drivenets.atlassian.net/issues/?jql=<url-encoded-jql>`).
- Do not output raw JQL in the final response unless the user explicitly asks for it.
- When the user asks to create an Epic, load and follow `references/epic-creation.md` before calling Jira `create_issue`.

## Team Context

- Username: `aminescu`
- Team ID: `28`
- Team Name: `Team-MW-Services`
- Team members:
  - Cristi: `712020:e38beffe-14ad-4276-819a-493643e5f9c8`
  - Bogdan: `628de11f891ea9006a9e5cd2`
  - Mihu: `5e69fbe3bf022f0d8132bf75`
  - Stancu: `5e24606163cc180e63b3dba7`
  - Marian: `712020:ec26913c-d856-498b-bd90-20cf3cb6e9fa`
  - Stefan: `62c28de3a152cf973643d620`
  - Gabi: `5e89e9052c0eff0b8f9fc660`

## Default Filter Mapping

- `bug` or `bugs`: https://drivenets.atlassian.net/issues/?filter=34159
- `CI bug` or `CI bugs`: https://drivenets.atlassian.net/issues/?filter=34158
- `closed bug`, `closed bugs`, `closed bugs last 3 months`, or `bugs closed in the last 3 months`: https://drivenets.atlassian.net/issues/?filter=54527
- `closed CI bug`, `closed CI bugs`, or `closed bugs CI last 3 months`: https://drivenets.atlassian.net/issues/?filter=54526
- `polaris`: https://drivenets.atlassian.net/issues/?filter=45684
- Team assigned epics (search this first for epic requests): https://drivenets.atlassian.net/issues/?filter=43384

Unless the user specifies otherwise, treat these mappings as the default base scope.

## Search Workflow

1. Resolve intent and base scope.
   - Map user wording to the default filter above.
   - If the user asks for an epic, query filter `43384` first.
   - When the user refers to `closed bugs`, use filter `54527` unless they explicitly say CI.
   - When the user refers to `closed CI bugs`, use filter `54526`.

2. Load candidate issues from Jira.
   - Use Jira MCP issue search from the selected filter scope.
   - Build JQL only with allowed constraints (for example filter, project, assignee, component, status, date, labels, comments).
   - Do not put summary/description matching logic inside JQL; do that in post-processing.

3. Rank by title/summary match (post-query).
   - Prioritize exact and near-exact summary matches.
   - Rank prefix matches above partial matches.

4. Refine with description match (post-query).
   - Check description only after summary scoring.
   - Raise candidates with strong description overlap.

5. Refine with comment evidence.
   - Read comments newest-first.
   - Use comments for final disambiguation and similarity checks.

6. Report concise evidence.
   - Return issue key, summary, status, assignee, and why it matches.
   - Quote only short, relevant snippets from description/comments.
   - For list outputs, include the Jira link used for the list (saved filter URL or `issues/?jql=<url-encoded-jql>` URL).
   - If no strong match exists, state that and explain what was broadened.

## CI-Specific Reference

For CI-focused heuristics and matching patterns, read `references/ci-hira-bug-search.md`.

## Epic Creation Reference

For Epic creation workflow, required field format, Team ID payload, and Prod_Target_Version selection rules, read `references/epic-creation.md`.

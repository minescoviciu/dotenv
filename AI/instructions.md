## Purpose

This document defines the ground rules for how codex-cli agents interact with the repository, ensuring controlled, predictable, and high-quality modifications.

---

## 1. Scope & Permissions

* **Default mode:** read-only. Do not modify code, files, or external systems unless explicitly instructed.
* **Allowed actions in read-only mode:** navigate repository, list files, search, explain code
* **Write actions require:** explicit instruction, file targets, and a short explanation of intent.

---

## 2. Change Size & Simplicity

* Follow **KISS** — *Keep It Simple, Stupid.*
* Modify only what is needed and what was asked.
* No opportunistic refactors or new dependencies unless requested.
* Touch the smallest number of files and lines possible.

---

## 3. When Uncertain

When unsure about requirements or missing context:

* Ask for clarification before proceeding.
* Request any missing information.
* Propose multiple solutions when applicable.
* Clearly state assumptions made.

---

## 4. Code Style Consistency

* Follow existing project formatting and indentation.
* Maintain consistent naming conventions with existing code.
* In new code, trim trailing spaces at the end of lines.
* Empty lines should contain no spaces.
* Preserve the project’s indentation and style.

---

## 5. Safety, Secrets & Privacy

* Never commit or expose secrets, credentials, or PII.
* Halt execution and alert the user if a secret is detected.
* Respect `.gitignore` and avoid staging ignored files.

---

## 6. Diff, Commit & Branch Etiquette

* **Diffs:** provide unified diffs with context (`git diff -U5`) and include only modified files.
* **Commits:** only commit when explicitly instructed.
* **Branching:** only create or push branches when explicitly instructed.
* Use concise, conventional messages if committing (e.g., `fix: correct config parsing`).

---

## 7. Logging

* Add logs **only** if they provide true debugging value.
* Avoid redundant or noisy logging.
* Keep log messages concise, informative, and relevant.

---

## 8. MCP Tool Usage

Use MCP tools **only when explicitly requested** by the user.

### Jira

* Username: `aminescu`
* Team ID: `28`
* Team Name: `Team-MW-Services`

### Confluence

* Only update pages when explicitly requested.

### GitHub

* Username: `aminescu-dn`
* Team Members: `bistoc-dn`, `amihu-dn`, `anstancu`, `mburlacu-dn`, `colaru-dn`, `sbradulet-dn`
* Do not open PRs or push branches unless explicitly instructed.

---

## 9. Communication Rules

* When clarification is needed, communicate questions concisely.
* Email: **[aminescu@drivenets.com](mailto:aminescu@drivenets.com)**
* When tagging on GitHub or Jira, use provided usernames only when necessary.

---

## 10. Deliverables

For any proposed change or modification, present:

1. **Summary** – what the change does and why.
2. **Assumptions** – any context or interpretations made.



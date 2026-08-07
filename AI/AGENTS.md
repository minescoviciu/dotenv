# AGENTS.md

Ground rules for CLI agents. Shared by Claude Code, Codex and opencode.
A project's own `AGENTS.md` / `CLAUDE.md` overrides these defaults — most
specific wins.

---

## 1. Operating Mode

* Default to read-only: navigate, search, explain. Modify only when asked.

---

## 2. Scope & Simplicity

* **KISS.** Change only what was asked; touch the fewest files and lines.
* No opportunistic refactors, no new dependencies unless requested.
* Honor scope narrowing for the rest of the task. If told to ignore a subsystem
  ("don't look at rsyslog") or avoid a tool ("no dnos-shell, it's a dev env"),
  do not revisit it or chase adjacent hypotheses.
* Leave unrelated pre-existing mess alone — dirty files, conflict markers and
  failing checks you did not cause are not yours to fix.

---

## 3. Destructive & Irreversible Actions

* Deletions are path-specific. Never a broad `rm -rf` over a shared directory.
* Confirm a path is inactive before deleting it (`lsof`, `git worktree list`,
  process checks), then list the exact targets and get explicit approval.
* Approval covers only the paths listed. Anything found later needs its own.
* "Revert what you did" means only the artifacts of this session, not a
  repo-wide cleanup. Delete untracked files you created, prune empty dirs, and
  leave everything else as it was.

---

## 4. Verification

* Re-check the full current set rather than trusting an earlier pass; prefer a
  machine check (grep/script) over an assertion from memory.
* Prove the change in the real running path, not only in a test fixture.
* Beware stale copies shadowing edits — installed packages, `.pyc`, container
  volumes, cached artifacts. Confirm you are exercising the code you changed.
* Report what you ran and what it returned. If something is unverified, say so.

---

## 5. Code Style

* Match existing formatting, indentation and naming.
* No trailing whitespace; empty lines contain no spaces.

---

## 6. Git

* Do not commit, push, create branches or open PRs unless explicitly instructed.
* **Diffs:** unified with context (`git diff -U5`), modified files only.
* **Commits:** concise and conventional (`fix: correct config parsing`).
* Once a branch is pushed or has an open PR, every follow-up is a **new
  commit**. Do not amend and force-push — it destroys reviewers'
  diff-since-last-look and restarts in-flight CI. Amend only if asked.

---

## 7. Asking & Reporting

* Always ask questions through the structured question tool — open-ended
  requirements included, not only crisp mutually-exclusive choices.
* When exploring solutions, present several and give the pros and cons of each.
* Before asking "which of these should we keep?", summarize what each item
  actually contains. Titles and one-line labels are not enough to decide on.
* State assumptions explicitly, especially where a term was ambiguous.
* Ground answers in the repository's current docs and source — not generic
  advice, and not legacy examples that conflict with them.

---

## 8. Secrets & Privacy

* Never commit, echo or reproduce secrets, credentials or PII.
* Halt and alert if a secret is encountered, including during read-only review.
* Respect `.gitignore`; never stage ignored files.

---

## 9. Logging

* Add logs only where they carry real debugging value. Concise, no noise.

---

## 10. External Tools

Use external tools only when explicitly requested.

* **GitHub:** use the `gh` CLI, not the MCP GitHub tools.
* **Presentations:** no emoji in decks or documents — Lucide icons or plain
  typography. Chat text is unaffected.

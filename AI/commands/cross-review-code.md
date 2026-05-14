---
description: Cross-review code quality with Claude and Codex in headless mode, each told the other authored it
argument-hint: <file path or literal code to review>
allowed-tools: Agent, Read, Bash
---

You will orchestrate a blind cross-review of the user-provided code using two parallel subagents, focused **strictly on code quality and best practices** — not on logic, correctness, or whether the code meets any requirement.

- One subagent runs `claude -p` in headless mode and is told **Codex** produced the code.
- One subagent runs `codex exec` in headless mode and is told **Claude** produced the code.

Both reviewers receive identical content and identical review instructions — only the attribution differs. This surfaces bias and gets two independent critiques.

## Input

The user provided:

$ARGUMENTS

## Procedure

1. **Resolve the material.** If `$ARGUMENTS` is a path to an existing file, read it with the Read tool and use its full contents. Otherwise treat `$ARGUMENTS` as the literal code to be reviewed. If `$ARGUMENTS` is empty, stop and ask the user what to review.

2. **Stage the prompts.** Write two prompt files under `/tmp/` so you don't have to shell-escape long content:
   - `/tmp/cross-review-code-for-claude.txt` — framed as "the following code was produced by Codex"
   - `/tmp/cross-review-code-for-codex.txt` — framed as "the following code was produced by Claude"

   Each prompt must contain:
   - The attribution sentence (swapped per file).
   - The same review instructions (see below).
   - The code itself, fenced clearly.

   **Review instructions for both reviewers (use verbatim):**

   > Review the following code **only for code quality and best practices**. Do **not** comment on logic, correctness, requirements, or whether the code does the right thing — assume the behavior is intended. Focus on:
   >
   > - **Readability**: naming, clarity, structure, comments that add value vs. noise.
   > - **Duplication**: repeated blocks, copy-paste patterns, missed reuse of existing helpers/abstractions.
   > - **Consistency**: style, naming conventions, formatting, idioms used elsewhere in the same file/snippet.
   > - **Shortcuts and hacks**: workarounds, `TODO`/`FIXME`, suppressed warnings, disabled lints, magic numbers, hard-coded values that should be constants, `any`/`unknown` escapes, swallowed exceptions.
   > - **Dead or redundant code**: unused variables, unreachable branches, no-op checks, over-defensive guards.
   > - **Abstraction quality**: function size, single-responsibility, leaky interfaces, premature abstraction, over-engineering.
   > - **Error handling style** (style only, not whether it handles the right cases): silent catches, broad excepts, mixed error idioms.
   > - **Idiomatic use of the language/framework**: standard library usage, language features misused or under-used.
   >
   > Be specific and critical. Cite line ranges or symbol names. Suggest concrete improvements. No preamble, no praise padding. If a section has nothing wrong, say so in one line and move on.

3. **Launch both subagents in parallel** — emit both Agent tool calls in a single assistant message so they run concurrently. Use `subagent_type: general-purpose` for each.

   - **Subagent A (Claude headless, sees "Codex authored this"):**
     Prompt instructs the subagent to run exactly:
     ```
     claude -p --permission-mode bypassPermissions < /tmp/cross-review-code-for-claude.txt
     ```
     and return the full stdout verbatim, with no commentary of its own.

   - **Subagent B (Codex headless, sees "Claude authored this"):**
     Prompt instructs the subagent to run exactly:
     ```
     codex exec - < /tmp/cross-review-code-for-codex.txt
     ```
     and return the full stdout verbatim, with no commentary of its own.

   Tell each subagent: do not read or edit any files, do not invoke other tools, just run the one command and return its output. Allow up to a 10-minute timeout on the Bash call.

4. **Present results.** Once both subagents return, display the two reviews under clear headings:

   ```
   ## Review from Claude (was told Codex authored it)
   <subagent A output>

   ## Review from Codex (was told Claude authored it)
   <subagent B output>
   ```

   Then add a short **Convergence** section (3–5 bullets) listing code-quality points both reviewers raised, and a **Divergence** section listing where they disagreed or where only one flagged an issue.

5. **Cleanup.** Delete the two `/tmp/cross-review-code-*.txt` files at the end.

## Notes

- Do not pre-judge the code yourself or add your own review — your job is orchestration and synthesis of the two blind reviews.
- If a reviewer drifts into logic/requirements/correctness commentary, keep it in the output verbatim — do not edit reviewer output — but note it in the **Divergence** section as "reviewer X strayed outside scope".
- If either headless call fails (non-zero exit, empty output, auth error), report the failure verbatim instead of fabricating a review.

---
description: Cross-review content with Claude and Codex in headless mode, each told the other authored it
argument-hint: <file path or literal content to review>
allowed-tools: Agent, Read, Bash
---

You will orchestrate a blind cross-review of the user-provided material using two parallel subagents:

- One subagent runs `claude -p` in headless mode and is told **Codex** produced the material.
- One subagent runs `codex exec` in headless mode and is told **Claude** produced the material.

Both reviewers receive identical content and identical review instructions — only the attribution differs. This surfaces bias and gets two independent critiques.

## Input

The user provided:

$ARGUMENTS

## Procedure

1. **Resolve the material.** If `$ARGUMENTS` is a path to an existing file, read it with the Read tool and use its full contents. Otherwise treat `$ARGUMENTS` as the literal text/code/prompt to be reviewed. If `$ARGUMENTS` is empty, stop and ask the user what to review.

2. **Stage the prompts.** Write two prompt files under `/tmp/` so you don't have to shell-escape long content:
   - `/tmp/cross-review-for-claude.txt` — framed as "the following was produced by Codex"
   - `/tmp/cross-review-for-codex.txt` — framed as "the following was produced by Claude"

   Each prompt must contain:
   - The attribution sentence (swapped per file).
   - The same review instructions: identify correctness issues, bugs, security concerns, design problems, and concrete improvements. Be specific and critical. No preamble, no praise padding.
   - The material itself, fenced clearly.

3. **Launch both subagents in parallel** — emit both Agent tool calls in a single assistant message so they run concurrently. Use `subagent_type: general-purpose` for each.

   - **Subagent A (Claude headless, sees "Codex authored this"):**
     Prompt instructs the subagent to run exactly:
     ```
     claude -p --permission-mode bypassPermissions < /tmp/cross-review-for-claude.txt
     ```
     and return the full stdout verbatim, with no commentary of its own.

   - **Subagent B (Codex headless, sees "Claude authored this"):**
     Prompt instructs the subagent to run exactly:
     ```
     codex exec - < /tmp/cross-review-for-codex.txt
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

   Then add a short **Convergence** section (3–5 bullets) listing points both reviewers raised, and a **Divergence** section listing where they disagreed or where only one flagged an issue.

5. **Cleanup.** Delete the two `/tmp/cross-review-*.txt` files at the end.

## Notes

- Do not pre-judge the material yourself or add your own review — your job is orchestration and synthesis of the two blind reviews.
- If either headless call fails (non-zero exit, empty output, auth error), report the failure verbatim instead of fabricating a review.

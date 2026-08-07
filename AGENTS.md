# AGENTS.md — dotenv

Repository rules for CLI agents. These are the most specific rules for this
repo and override `AI/AGENTS.md`, which is the global default set.

`CLAUDE.md` in this directory is a symlink to this file.

---

## 1. Commit Granularity

* **Every small change gets its own commit.** Do not batch unrelated edits.
  A config tweak, a skill addition and a script fix are three commits.
* Subject lines stay concise and conventional (`fix: correct config parsing`).
* This overrides nothing in the global rule that says not to commit unless
  asked — you still commit only when the user asks. The rule here governs how
  the work is split once you have been asked.

---

## 2. WORK Commits

A **WORK commit** is a commit whose subject line starts with the literal word
`WORK`:

```
WORK add rebase skill
```

Constraints:

* Anything work-related MUST be committed as a WORK commit.
* WORK commits MUST NEVER be pushed. They live only on the local `work`
  branch.
* **If you are not sure whether a change is work-related, ask the user.**
  Do not guess and do not default either way.

Work-related means tied to the user's employer — internal tooling, internal
hostnames, ticket workflows, proprietary service names, company-specific
skills or MCP configuration. Personal dotfiles, editor config and public
tooling are not work-related.

---

## 3. Single WORK Commit, Always At The Tip

Keep exactly **one** WORK commit, and keep it as the **last** commit on the
branch:

```
master
  ├── normal commit          <- pushable
  ├── normal commit          <- pushable
  └── WORK                   <- tip, never pushed
```

* After making a new work-related commit, squash it into the existing WORK
  commit so only one remains.
* This is safe precisely because WORK commits are never pushed — the global
  rule against amending applies to pushed history, which this is not.

**New normal commits go BELOW the WORK tip, never above it.** The hook in
section 4 rejects a push that *contains* a WORK commit, not just a push *of*
one. A normal commit stacked above WORK is therefore unpushable forever, which
defeats the point of marking it normal. Inserting below the tip means rebasing,
or building the commits with `git commit-tree` against a temporary
`GIT_INDEX_FILE` when the working tree is dirty and must not be disturbed.

### Squash in existing order only — never reorder

Reordering to make WORK commits adjacent is **not** safe, and it does not fail
loudly. A cleanup commit that only deletes files, moved ahead of the commit
that created them, applies **empty**; `git rebase --skip` then drops it and the
rebase reports success while the tree silently regains the deleted files.

Squash only commits that are already adjacent, in the order they already have.
If WORK commits are separated by a non-WORK commit, either absorb that commit
into the squash or leave the history alone — ask the user which.

---

## 4. Push Protection

`.githooks/pre-push` rejects any push containing a commit whose subject starts
with `WORK`. It is wired up with:

```bash
git config core.hooksPath .githooks
```

The hook is tracked in this repo, but `core.hooksPath` is local config and is
not. On a fresh clone, run the command above or the hook will not fire.

Do not bypass it with `--no-verify`.

### How to push

`work` tracks `origin/master` and its tip is the WORK commit, so a bare
`git push` always hits the hook. Push the commits below the tip instead:

```bash
git push origin work~1:master
```

Adjust `~1` to however many WORK commits sit on top — normally exactly one.

### Known gap: worktrees

`core.hooksPath` is set to the relative path `.githooks`, so it resolves inside
whichever worktree runs the push. A worktree checked out at a commit from
before `.githooks/` existed has no hook and pushes without protection. Verify
with `ls .githooks` before pushing from a worktree.

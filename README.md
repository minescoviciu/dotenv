# dotenv

Personal dotfiles and dev-machine setup. This document is the runbook for
bootstrapping a **new, clean machine** (verified on Ubuntu 24.04 amd64) —
what to install, how, and the specific preferences behind each choice.

---

## 1. Tools to install

The rule of thumb applied throughout: **if a tool publishes prebuilt binaries
on GitHub releases, use those instead of apt** — Ubuntu's repo versions are
usually stale. Apt is only used where no better release artifact exists.

| Tool | Method | Why / notes |
|---|---|---|
| `nvim` | GitHub release binary → `~/.local/bin` | Apt has 0.9.5, GitHub has the current release. Asset: `nvim-linux-x86_64.tar.gz`, extracted to `~/.local/share/nvim-linux-x86_64`, `bin/nvim` symlinked into `~/.local/bin`. |
| `tmux` | **Compile from source** | GitHub releases only attach a source tarball (no Linux binaries) — must build. Apt's 3.4 was replaced deliberately for floating panes / scrollbars / themes added in 3.6–3.7. Deps: `build-essential libevent-dev libncurses-dev bison pkg-config`. `./configure && make && sudo make install` installs to `/usr/local/bin/tmux`, which already precedes `/usr/bin` on `$PATH`, so no need to remove the apt package. |
| `fzf` | GitHub release binary → `~/.local/bin` | Apt has 0.44.1 (stale). Asset: `fzf-*-linux_amd64.tar.gz`. |
| `git-delta` | **`.deb` from GitHub release**, `sudo dpkg -i` | Apt has 0.16.5 (stale). The release conveniently ships a ready-made `.deb` (`git-delta_<ver>_amd64.deb`) — no compiling. **Watch out:** the release also ships `git-delta-musl_<ver>_amd64.deb`; a naive `grep amd64\.deb` matches both and breaks a `$(...)` capture (multi-line var → "Malformed input to a URL function" from curl). Anchor the pattern on `git-delta_` specifically. |
| `lazygit` | GitHub release binary → `~/.local/bin` | Not in apt at all. Asset: `lazygit_<ver>_linux_x86_64.tar.gz`. |
| `gh` (GitHub CLI) | **GitHub's own apt repo**, not Ubuntu's | Apt has 2.45.0 (stale). Adding `cli.github.com`'s repo + keyring means `apt upgrade` keeps it current going forward, vs. a one-off `.deb` you'd have to manually refresh. |
| `aws` CLI v2 | AWS's official installer script | Not distributed via apt or GitHub releases at all — AWS ships its own bundle. `curl -fsSL https://awscli.amazonaws.com/v2/install.sh \| bash` installs user-locally to `~/.local/share/aws-cli` with a symlink in `~/.local/bin`, no sudo needed (only `unzip` as a prerequisite does). |
| Node.js / npm | **nvm**, not apt, not NodeSource | Only needed to run `codex`/`opencode` if installed via npm. Apt's node is 18.19 (old, no prebuilt GitHub release binaries either — Node distributes via nodejs.org/dist). nvm keeps it user-managed and easily upgradable: `nvm install --lts`. |
| `codex` (OpenAI Codex CLI) | GitHub release binary → `~/.local/bin` | Release ships `codex-x86_64-unknown-linux-musl.tar.gz`; extract and rename the binary to `codex`. |
| `starship` | **Not installed** — removed from `init.sh` entirely | Preference: skip it. Both the `starship.toml` symlink line and the `curl \| sh` install line were deleted from `init.sh`. |
| `opencode` | **Not installed** (by request) | The `~/.config/opencode/opencode.jsonc` symlink in `init.sh` is left in place for possible future use, but the binary itself is intentionally skipped. (The companion `agent` symlink was dropped — `AI/opencode/agent/` no longer exists.) |
| `jq`, `docker`, `python3`, `rg` (ripgrep), `git` | Already fine via apt | Current enough out of the box, no action needed. |

Not applicable on Linux — skip entirely: `aerospace.toml` (macOS window manager),
`sketchybar` (macOS status bar), WezTerm GUI terminal, Cursor/VS Code/Zed
editor settings (no local GUI on a headless dev box).

### GitHub API note
When scripting "grab the latest release asset" via
`curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest`, always
check the **full list** of `browser_download_url` values before grepping —
several of these repos ship more than one asset that could loosely match a
naive pattern (e.g. delta's musl vs. glibc `.deb`, multiple architectures).
Getting two lines back is silent poison: `$(...)` collapses newlines into the
variable and the next command chokes on a multi-line argument.

---

## 2. Run `init.sh`

No manual preparation needed:

```bash
cd ~/dotenv
bash init.sh
```

`init.sh` is **stateless** — every step converges on the same result, so
re-run it as often as you like. It creates parent directories, replaces
existing symlinks rather than failing on them, and rewrites its own block in
the rc file instead of appending to it. A pre-existing real `~/.gitconfig` is
replaced by the symlink; a real *directory* sitting where a link belongs is
reported and left alone rather than being linked into.

macOS-only targets (aerospace, sketchybar, Cursor settings) are skipped on
Linux instead of failing noisily.

### Adding a script

`~/.config/scripts` is globbed at shell startup, and **the executable bit
decides what happens to each file**:

| Mode | Meaning | Effect |
|---|---|---|
| not executable | shell setup — functions, completions, prompt | sourced into every new shell |
| executable | a command invoked on demand by a tmux or fzf binding | never sourced |

So `chmod +x` anything you invoke by path, and leave anything meant to be
sourced non-executable. Because the rc block is a glob and not a list, adding,
renaming or deleting a script needs **no re-run of `init.sh`** — the next
shell picks it up.

This distinction matters: the on-demand scripts do their work at the top
level, so sourcing `tmux-toggle-popup.sh` opens a popup and
`tmux-toggle-nvim-opencode.sh` jumps to another window — on every new shell.

---

## 3. tmux plugins (tpm)

The plugin manager repo is **`tmux-plugins/tpm`** — not `tmux/tpm` (that
org/repo doesn't exist; trying it produces a 401/"Repository not found" over
both HTTPS and SSH, which looks like a network block but is really just a
nonexistent-repo response).

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

To install the plugins listed in `tmux.conf` (`tmux-fzf`, `catppuccin/tmux`,
`tmux-resurrect`, `tmux-continuum`) without needing an interactive tmux
session (e.g. scripting a fresh box):

```bash
tmux new-session -d -s setup   # loads tmux.conf, which runs tpm's init line
sleep 1
~/.tmux/plugins/tpm/bin/install_plugins
```

`bin/install_plugins` needs a **live tmux server** to query
`TMUX_PLUGIN_MANAGER_PATH` and the `@plugin` list — running it with no tmux
server up at all fails with `FATAL: Tmux Plugin Manager not configured in
tmux.conf`, even though the config is correct.

If you already have a tmux session that was started *before* the plugins
finished installing, reload it to pick up the theme/plugins:
`tmux source-file ~/.tmux.conf` (or detach/reattach).

---

## 4. Preference summary (why over alternatives)

- **tmux**: compile latest from source, not apt — worth it for floating
  panes / scrollbars / themes (3.6–3.7), even though it means maintaining a
  from-source build across future updates.
- **git-delta**: GitHub release `.deb`, not apt — cleanest path, no compiling.
- **gh**: GitHub's official apt repo, not a one-off release `.deb` — stays
  current via normal `apt upgrade`.
- **Node.js**: nvm, not apt, not a system-wide NodeSource repo — user-managed,
  no sudo, easy to bump versions.
- **aws-cli**: AWS's own installer script — it's simply the only real option;
  neither apt nor GitHub releases carry it.
- **starship**: removed from `init.sh` entirely, not installed.
- **opencode**: not installed; its config symlinks in `init.sh` were left
  alone in case it's wanted later.
- **codex**: installed from its GitHub release binary rather than npm or its
  own curl script, to keep it consistent with the "prefer GitHub releases"
  rule.

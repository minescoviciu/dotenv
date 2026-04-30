# Subskill: Jira CI Ticket Rerun

Use this workflow when user provides a Jira CI ticket key (for example `SW-228950`).

## Inputs

- Jira issue key
- Optional remote host from user: `use kvm: <host>`

## Jira Resolution

1. Read Jira issue.
   - Get summary, description, comments, and affected version.
   - Use Jira MCP issue read (`dn-mcp_atlassian_jira_get_issue`).

2. Extract Jenkins link from Jira content.
   - Prefer Jenkins job link in description/comments.
   - Use that link as source of failed test and dtest command.
   - If Jenkins link is missing/unavailable or stage extraction from link fails, notify user and fallback to Jira title parsing.

2b. Extract stage hint from Jira comment text when available.
   - Look for pattern: `during tests_...` (example: `during tests_emu_sa_ssh_(1/1)`).
   - Use this as `--stage-hint` for faster targeted dtest extraction from noisy Jenkins logs.
   - If targeted extraction is too slow/unavailable, fallback to Jira-title command and notify user.

3. Derive dev branch from affected version.
   - Rule: `v26.1` -> `dev_v26_1`
   - General mapping: `v<major>.<minor>` -> `dev_v<major>_<minor>`
   - If affected version is missing, derive from Jenkins URL token matching `dev_vX_Y`.

## Steps

1. Show failed stage from Jenkins link.
   - `scripts/extract_stage_dtest.py --jenkins-url <jenkins-link> --list-failed-stages`
   - If stage cannot be parsed from UI text, extraction still falls back to first `dtest` in logs.

1b. Fallback when Jenkins link is unavailable.
   - Build command from Jira title:
     - pattern: `test_<env>.test_<name>`
     - output: `dtest <env> --test-name <name> --images latest --break`
   - Example:
     - title: `Test test_emu_sa_inband.test_login_user_sshkey_terminal has failed.`
     - command: `dtest emu_sa_inband --test-name test_login_user_sshkey_terminal --images latest --break`
   - Notify user explicitly that Jenkins link was not available and title fallback is used.

2. Select stage.
   - Jira CI tickets are expected to have one failed test.
   - If more than one is found, ask user to choose one index.

3. Ensure remote host.
   - If user did not provide `use kvm: <host>` and `REMOTE_KVM` is empty, ask for it.

4. Preview rerun package.
   - Recommended (auto fallback if Jenkins link is unavailable):
     - `scripts/replicate_selected_stage_remote.py --jenkins-url <jenkins-link> --jira-title "<jira-title>" --stage-hint <tests_...> --affected-version <vX.Y> --selection <n> --print-only --kvm "use kvm: <host>"`
   - With affected version:
     - `scripts/replicate_selected_stage_remote.py --jenkins-url <jenkins-link> --affected-version <vX.Y> --selection <n> --print-only --kvm "use kvm: <host>"`
   - With explicit branch:
    - `scripts/replicate_selected_stage_remote.py --jenkins-url <jenkins-link> --branch <dev_vX_Y> --selection <n> --print-only --kvm "use kvm: <host>"`
   - Without Jenkins link (title fallback):
     - `scripts/replicate_selected_stage_remote.py --jira-title "<jira-title>" --affected-version <vX.Y> --print-only --kvm "use kvm: <host>"`

5. Execute on remote host.
   - Recommended (auto fallback if Jenkins link is unavailable):
     - `scripts/replicate_selected_stage_remote.py --jenkins-url <jenkins-link> --jira-title "<jira-title>" --stage-hint <tests_...> --affected-version <vX.Y> --selection <n> --execute --kvm "use kvm: <host>"`
    - `scripts/replicate_selected_stage_remote.py --jenkins-url <jenkins-link> --affected-version <vX.Y> --selection <n> --execute --kvm "use kvm: <host>"`
    - Title fallback mode:
      - `scripts/replicate_selected_stage_remote.py --jira-title "<jira-title>" --affected-version <vX.Y> --execute --kvm "use kvm: <host>"`

## Required Behaviors

- If Jenkins link is valid, run the exact stage dtest command as found in Jenkins stage metadata.
- If Jenkins link is valid, export both env vars before dtest:
  - `RUNNER_NUMBER`
  - `MY_RUNNER_NUMBER`
  - `TOTAL_RUNNERS`
- For valid Jenkins-link reruns, set `--images-url` to latest Jenkins-Israel-3 branch build URL.
- Fallback exception: when Jenkins link is unavailable or stage extraction fails, run title-based command with `--images latest`.
- Add `--break` if missing.
- Start tmux with a normal bash shell, then run the rerun command inside that shell.
- Print attach command.
- Print script summary output after execute.
- Include `remote_tmux_attach <host>` in summary.
- Do not auto-print pane output unless user asks for it.
- Use fixed tmux session name `test-rerunner`.
- Use SSH with disabled host key checks.
- Do not start if another dtest is already running on that KVM.

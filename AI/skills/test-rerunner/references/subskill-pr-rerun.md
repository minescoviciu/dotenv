# Subskill: PR Rerun

Use this workflow when user provides a PR URL/number.

## Inputs

- PR URL or PR number
- Optional remote host from user: `use kvm: <host>`

## Steps

1. Show failed stages.
   - `scripts/extract_stage_dtest.py --pr <pr> --list-failed-stages`
   - Include table columns: `#`, `Pipeline`, `Stage`, `Failure`, `Env`, `File`, `Test`, `Details`

2. Select one stage.
   - If one failed stage: auto-select and say so.
   - If multiple failed stages: ask user which index to replicate.

3. Ensure remote host.
   - If user did not provide `use kvm: <host>` and `REMOTE_KVM` is empty, ask for it.

4. Preview rerun package.
   - `scripts/replicate_selected_stage_remote.py --pr <pr> --selection <n> --print-only --kvm "use kvm: <host>"`

5. Execute on remote host.
   - `scripts/replicate_selected_stage_remote.py --pr <pr> --selection <n> --execute --kvm "use kvm: <host>"`

## Required Behaviors

- Use image URL from Jenkins-Israel-3 PR check.
- Add `--break` if missing.
- Start tmux with a normal bash shell, then run the rerun command inside that shell.
- Print attach command.
- Print script summary output after execute.
- Include `remote_tmux_attach <host>` in summary.
- Do not auto-print pane output unless user asks for it.
- Use fixed tmux session name `test-rerunner`.
- Use SSH with disabled host key checks.
- Do not start if another dtest is already running on that KVM.

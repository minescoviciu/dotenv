---
name: test-rerunner
description: Rerun failed CI tests for drivenets/cheetah on a remote KVM by extracting dtest commands from Jenkins and executing them with branch-correct images. Use when user provides either a PR or a Jira CI ticket key (for example SW-228950) and wants to reproduce one failed test remotely.
---

# Test Rerunner

## Overview

Use this skill to run failed tests on remote KVMs from either:
- PR context (GitHub checks + Jenkins)
- Jira CI ticket context (Jira link to Jenkins + affected version)

The PR workflow is implemented as a referenced subskill document.
The Jira CI ticket workflow is implemented as a separate referenced subskill document.

## Rules

- Assume repo is always `drivenets/cheetah`.
- Use `use kvm: <host>` as canonical user input to set remote host.
- If remote host is missing, ask for `use kvm: <host>` before execute step.
- Run one test per KVM at a time. Do not run multiple dtests concurrently on same KVM.
- Always add `--break` to rerun command when missing.
- Use tmux on remote host so user can attach to breakpoints.
- Always use SSH with host key checks disabled (`StrictHostKeyChecking=no`, `UserKnownHostsFile=/dev/null`).
- Always use the same tmux session name: `test-rerunner`.
- Always run `git clean -fdx` with `sudo` on remote host before rerun.
- Always show script summary output when rerunning.
- Do not auto-print tmux pane output unless user explicitly asks for it.

## Subskill References

- PR subskill: read `references/subskill-pr-rerun.md`
- Jira CI ticket subskill: read `references/subskill-jira-ci-rerun.md`

## Script Inventory

- `scripts/extract_stage_dtest.py`
  - Extract failed stage and dtest from:
    - PR (`--pr`)
    - direct Jenkins URL (`--jenkins-url`)
  - Prints stage table with failure classification and test split fields.

- `scripts/replicate_selected_stage_remote.py`
  - Executes remote rerun in tmux from:
    - PR mode (`--pr`)
    - Jenkins/Jira mode (`--jenkins-url` + `--affected-version` or `--branch`)
    - Jira-title fallback mode (`--jira-title` + `--affected-version` or `--branch`)
  - Supports `--stage-hint` from Jira text (`during tests_...`) for faster targeted command extraction.
  - For Jenkins-link reruns, rewrites image source using `--images-url` to Jenkins-Israel-3 branch-appropriate URL.
  - Appends `--break`.
  - Runs fetch/checkout/clean + dtest remotely.

## Shared Module

- Shared Jenkins/wfapi logic is centralized in:
  - `AI/skills/jenkins_ci_shared.py`
- Scripts in this skill should reuse the shared module for run URL normalization, wfapi stage discovery, stage matching, and Jenkins reason-coded errors.

## Routing

- If input is PR URL/number: use PR subskill.
- If input looks like Jira key (for example `SW-228950`): use Jira subskill.
  - If Jira has no usable Jenkins link, use Jira-title fallback flow.

## Output Requirements

- Always show failed stage summary before running.
- If multiple failures: ask which one to replicate.
- If single failure: auto-select and state it.
- Always print attach command for tmux session.
- Always include `remote_tmux_attach <kvm>` line in summary.
- In Jira mode, if Jenkins link is missing/unavailable, notify user and use title-based command with `--images latest`.
- In Jira mode, if Jenkins link is valid, use exact stage dtest from Jenkins metadata and export `RUNNER_NUMBER` + `TOTAL_RUNNERS`.

Use `references/subskill-pr-rerun.md` and `references/subskill-jira-ci-rerun.md` as the canonical workflows.

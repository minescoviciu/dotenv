#!/usr/bin/env python3

"""Replicate one failed test on a remote KVM machine.

Flow:
1) Read failed stage metadata from extract_stage_dtest.py
2) Read exact dtest command for selected stage
3) Force dtest image source:
   - PR mode: Jenkins-Israel-3 PR build URL
   - Jenkins/Jira mode: latest Jenkins-Israel-3 image URL for dev branch
4) Ensure --break flag is present
5) SSH to REMOTE_KVM, checkout branch, git clean -fdx, run dtest in tmux

Usage:
  replicate_selected_stage_remote.py --pr 89044 --selection 1 --print-only
  replicate_selected_stage_remote.py --jenkins-url https://jenkins-aws6.../display/redirect --affected-version v26.1 --print-only
  replicate_selected_stage_remote.py --jenkins-url https://jenkins3... --stage-hint tests_emu_sa_ssh_(1/1) --affected-version v26.1 --print-only
  replicate_selected_stage_remote.py --jira-title "Test test_emu_sa_inband.test_login_user_sshkey_terminal has failed." --affected-version v26.1 --print-only
  replicate_selected_stage_remote.py --pr 89044 --selection 1 --execute
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


SKILLS_ROOT = Path(__file__).resolve().parents[2]
if str(SKILLS_ROOT) not in sys.path:
    sys.path.insert(0, str(SKILLS_ROOT))

from jenkins_ci_shared import (
    JenkinsCIError,
    get_run_wfapi,
    get_stage_wfapi,
    normalize_run_url,
    select_stage,
)


REPO = "drivenets/cheetah"
JENKINS_ISRAEL3_ROOT = "https://jenkins3.dev.drivenets.net/job/drivenets/job/cheetah/job"
FIXED_TMUX_SESSION = "test-rerunner"
SSH_OPTIONS = [
    "-o",
    "StrictHostKeyChecking=no",
    "-o",
    "UserKnownHostsFile=/dev/null",
]


def run_cmd(cmd: List[str], check: bool = True, timeout: Optional[int] = None) -> str:
    try:
        proc = subprocess.run(
            cmd,
            check=check,
            text=True,
            capture_output=True,
            timeout=timeout,
        )
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\n{exc.stderr.strip()}"
        ) from exc
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"Command timed out: {' '.join(cmd)}") from exc
    return proc.stdout


def ssh_command(host: str, remote_command: str) -> List[str]:
    return ["ssh", *SSH_OPTIONS, host, "bash", "-lc", remote_command]


def ssh_attach_command(host: str, session_name: str) -> str:
    return (
        "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
        f"-t {shlex.quote(host)} tmux attach -t {shlex.quote(session_name)}"
    )


def run_json(cmd: List[str]) -> Any:
    out = run_cmd(cmd)
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON from command: {' '.join(cmd)}") from exc


def normalize_kvm_input(raw_value: str) -> str:
    """Accept either `host` or `use kvm: host` user input."""
    value = raw_value.strip()
    if not value:
        return ""
    match = re.match(r"^use\s+kvm\s*:\s*(.+)$", value, flags=re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return value


def parse_test_from_jira_title(title: str) -> tuple[str, str]:
    """Parse env and test name from Jira title.

    Example:
      Test test_emu_sa_inband.test_login_user_sshkey_terminal has failed.
    ->
      (emu_sa_inband, test_login_user_sshkey_terminal)
    """
    text = title.strip()
    if not text:
        raise RuntimeError("Jira title is empty")

    match = re.search(
        r"\btest_([a-z0-9_]+)\.(?:[a-zA-Z0-9_]+\.)*(test_[a-zA-Z0-9_]+(?:\[[^\]]+\])?)",
        text,
    )
    if not match:
        raise RuntimeError(
            "Could not parse test from Jira title. Expected pattern like test_emu_sa_inband.test_xxx"
        )

    env = match.group(1)
    test_name = match.group(2)
    return env, test_name


def dtest_from_jira_title(title: str) -> str:
    env, test_name = parse_test_from_jira_title(title)
    return f"dtest {env} --test-name {test_name} --images latest --break"


def resolve_remote_kvm(cli_kvm: Optional[str]) -> str:
    if cli_kvm and cli_kvm.strip():
        host = normalize_kvm_input(cli_kvm)
        if not host:
            raise RuntimeError("Invalid --kvm value")
        os.environ["REMOTE_KVM"] = host
        return host

    env_kvm = normalize_kvm_input(os.environ.get("REMOTE_KVM", ""))
    if env_kvm:
        os.environ["REMOTE_KVM"] = env_kvm
        return env_kvm

    raise RuntimeError(
        "Remote host is missing. Ask user: 'use kvm: <host>' (or set REMOTE_KVM)."
    )


def load_failed_stage(selection: int, pr: str, extract_script: str) -> Dict[str, Any]:
    rows = run_json([
        extract_script,
        "--pr",
        pr,
        "--list-failed-stages",
        "--json",
    ])
    if not isinstance(rows, list):
        raise RuntimeError("Invalid failed stage payload")
    for row in rows:
        if not isinstance(row, dict):
            continue
        if row.get("index") == selection:
            return row
    raise RuntimeError(f"Selection {selection} not found in failed stage list")


def load_failed_stages(pr: str, extract_script: str) -> List[Dict[str, Any]]:
    rows = run_json([
        extract_script,
        "--pr",
        pr,
        "--list-failed-stages",
        "--json",
    ])
    if not isinstance(rows, list):
        raise RuntimeError("Invalid failed stage payload")

    out: List[Dict[str, Any]] = []
    for row in rows:
        if isinstance(row, dict):
            out.append(row)
    return out


def load_selected_dtest(selection: int, pr: str, extract_script: str) -> str:
    out = run_cmd([
        extract_script,
        "--pr",
        pr,
        "--selection",
        str(selection),
        "--raw",
    ])
    cmd = out.strip().splitlines()
    if not cmd:
        raise RuntimeError("No dtest command returned for selected stage")
    return cmd[0].strip()


def to_base_build_url(target_url: str) -> str:
    return normalize_run_url(target_url)


def parse_dtest_from_parameter_description(text: str) -> Optional[str]:
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("dtest "):
            return line
    return None


def parse_runner_env_from_parameter_description(text: str) -> Dict[str, str]:
    def _clean(value: str) -> str:
        return value.strip().strip('"').strip("'")

    runner = None
    total = None

    m_runner = re.search(r"\bRUNNER_NUMBER=([^\s]+)", text)
    if m_runner:
        runner = _clean(m_runner.group(1))
    else:
        m_my_runner = re.search(r"\bMY_RUNNER_NUMBER=([^\s]+)", text)
        if m_my_runner:
            runner = _clean(m_my_runner.group(1))

    m_total = re.search(r"\bTOTAL_RUNNERS=([^\s]+)", text)
    if m_total:
        total = _clean(m_total.group(1))

    return {
        "RUNNER_NUMBER": runner or "1",
        "MY_RUNNER_NUMBER": runner or "1",
        "TOTAL_RUNNERS": total or "1",
    }


def extract_dtest_and_env_from_jenkins_stage(
    target_url: str,
    stage_hint: Optional[str],
) -> Optional[tuple[str, Dict[str, str], str]]:
    try:
        run_info = get_run_wfapi(target_url, timeout=30, retries=1)
    except JenkinsCIError:
        return None

    chosen_stage = select_stage(run_info, stage_hint=stage_hint, prefer_failed=True)
    if not chosen_stage:
        return None

    try:
        stage_data = get_stage_wfapi(target_url, chosen_stage.id, timeout=30, retries=1)
    except JenkinsCIError:
        return None

    for node in stage_data.nodes:
        desc = node.parameter_description
        if "dtest " not in desc:
            continue
        dtest_cmd = parse_dtest_from_parameter_description(desc)
        if dtest_cmd:
            env_vars = parse_runner_env_from_parameter_description(desc)
            return dtest_cmd, env_vars, chosen_stage.name

    return None


def branch_from_affected_version(affected_version: str) -> str:
    value = affected_version.strip()
    match = re.match(r"^v?(\d+)[._](\d+)$", value, flags=re.IGNORECASE)
    if not match:
        raise RuntimeError(
            f"Unsupported affected version '{affected_version}'. Expected format like v26.1"
        )
    major, minor = match.group(1), match.group(2)
    return f"dev_v{major}_{minor}"


def branch_from_jenkins_url(jenkins_url: str) -> Optional[str]:
    tokens = re.findall(r"/job/([^/]+)", jenkins_url)
    if not tokens:
        return None

    for token in reversed(tokens):
        if re.match(r"^dev_v\d+_\d+$", token):
            return token
    return None


def latest_branch_image_url(branch: str) -> str:
    safe_branch = branch.strip()
    if not safe_branch:
        raise RuntimeError("Branch is empty")
    return f"{JENKINS_ISRAEL3_ROOT}/{safe_branch}/lastSuccessfulBuild/"


def get_pr_info(pr: str) -> Dict[str, Any]:
    return run_json(
        [
            "gh",
            "pr",
            "view",
            pr,
            "--repo",
            REPO,
            "--json",
            "number,title,headRefName,statusCheckRollup",
        ]
    )


def get_jenkins_israel3_image_url(status_checks: List[Dict[str, Any]]) -> str:
    for item in status_checks:
        context = item.get("context", "")
        target_url = item.get("targetUrl")
        if context.startswith("Jenkins-Israel-3") and target_url:
            return to_base_build_url(target_url)
    raise RuntimeError("Jenkins-Israel-3 check not found for this PR")


def rewrite_dtest_for_remote(
    dtest_cmd: str,
    forced_images: Optional[str],
    image_flag: str = "--images",
) -> str:
    tokens = shlex.split(dtest_cmd)
    if not tokens:
        raise RuntimeError("Empty dtest command")

    out: List[str] = []
    i = 0
    replaced_image = False
    while i < len(tokens):
        token = tokens[i]

        # Drop Jenkins-specific or CI-only arguments for remote rerun.
        if token in ("--render-argument", "--collect-to"):
            i += 2
            continue
        if token.startswith("--render-argument=") or token.startswith("--collect-to="):
            i += 1
            continue
        if token == "--exit-on-first-fail":
            i += 1
            continue

        if token in ("--images", "--image", "--images-url"):
            if forced_images is not None:
                out.append(f"{image_flag}={forced_images}")
                replaced_image = True
            else:
                out.append(token)
                if i + 1 < len(tokens):
                    out.append(tokens[i + 1])
            i += 2
            continue

        if (
            token.startswith("--images=")
            or token.startswith("--image=")
            or token.startswith("--images-url=")
        ):
            if forced_images is not None:
                out.append(f"{image_flag}={forced_images}")
                replaced_image = True
            else:
                out.append(token)
            i += 1
            continue

        out.append(token)
        i += 1

    if forced_images is not None and not replaced_image:
        out.append(f"{image_flag}={forced_images}")

    if "--break" not in out:
        out.append("--break")

    return shlex.join(out)


def build_remote_script(
    repo_dir: str,
    branch: str,
    dtest_cmd: str,
    env_exports: Optional[Dict[str, str]] = None,
) -> str:
    if repo_dir == "~":
        safe_repo_dir = '"$HOME"'
    elif repo_dir.startswith("~/"):
        suffix = repo_dir[2:].replace('"', '\\"')
        safe_repo_dir = f'"$HOME/{suffix}"'
    elif repo_dir.startswith("$HOME/"):
        suffix = repo_dir[len("$HOME/") :].replace('"', '\\"')
        safe_repo_dir = f'"$HOME/{suffix}"'
    else:
        safe_repo_dir = shlex.quote(repo_dir)
    safe_branch = shlex.quote(branch)
    export_block = ""
    if env_exports:
        parts = [f"export {k}={shlex.quote(v)}" for k, v in env_exports.items() if v]
        if parts:
            export_block = "; ".join(parts) + "; "
    return (
        "set -euo pipefail; "
        f"cd {safe_repo_dir}; "
        f"git fetch origin {safe_branch}; "
        f"git checkout -B {safe_branch} FETCH_HEAD; "
        "sudo -n git clean -fdx || { echo '[test-rerunner] sudo git clean failed' >&2; exit 1; }; "
        f"{export_block}"
        f"{dtest_cmd}"
    )


def build_tmux_launcher(remote_script: str, session_name: str) -> str:
    quoted_session = shlex.quote(session_name)
    run_and_report = (
        f"{remote_script}; "
        "rc=$?; "
        "echo __TEST_RERUNNER_EXIT_CODE=${rc}__"
    )
    typed_command = f"bash -lc {shlex.quote(run_and_report)}"
    quoted_typed_command = shlex.quote(typed_command)
    return (
        "set -euo pipefail; "
        "command -v tmux >/dev/null 2>&1 || { echo 'tmux is required on remote host' >&2; exit 1; }; "
        "if pgrep -x dtest >/dev/null; then "
        "  echo 'Another dtest process is already running on this KVM. Only one test is allowed at a time.' >&2; "
        "  exit 2; "
        "fi; "
        f"session={quoted_session}; "
        "tmux has-session -t \"$session\" 2>/dev/null && tmux kill-session -t \"$session\" || true; "
        "tmux new-session -d -s \"$session\"; "
        f"tmux send-keys -t \"$session\" {quoted_typed_command} C-m; "
        "tmux has-session -t \"$session\""
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pr", help="PR number or URL")
    parser.add_argument("--jenkins-url", help="Direct Jenkins build URL")
    parser.add_argument(
        "--jira-title",
        help="Jira title used when Jenkins link is missing/unavailable",
    )
    parser.add_argument("--selection", type=int, help="Failed stage index")
    parser.add_argument(
        "--stage-hint",
        help="Stage hint from Jira text, e.g. tests_emu_sa_ssh_(1/1)",
    )
    parser.add_argument("--branch", help="Branch to checkout (e.g. dev_v26_1)")
    parser.add_argument(
        "--affected-version",
        help="Affected version from Jira (e.g. v26.1). Used to derive branch when --branch is not set.",
    )
    parser.add_argument(
        "--repo-dir",
        default="$HOME/cheetah",
        help="Remote repository directory (default: $HOME/cheetah)",
    )
    parser.add_argument(
        "--kvm",
        help="Remote host value. Accepts 'host' or 'use kvm: host'.",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Execute on remote machine over ssh (starts tmux session)",
    )
    parser.add_argument(
        "--print-only",
        action="store_true",
        help="Print computed command/script only",
    )
    args = parser.parse_args()

    if not args.pr and not args.jenkins_url and not args.jira_title:
        parser.error("Provide one source: --pr, --jenkins-url, or --jira-title")
    if args.pr and (args.jenkins_url or args.jira_title):
        parser.error("--pr cannot be combined with --jenkins-url or --jira-title")

    if not args.execute and not args.print_only:
        parser.error("Provide one of --print-only or --execute")

    remote_kvm: Optional[str] = None
    if args.execute:
        remote_kvm = resolve_remote_kvm(args.kvm)

    extract_script = str(Path(__file__).with_name("extract_stage_dtest.py"))
    if not Path(extract_script).exists():
        raise RuntimeError(f"Missing helper script: {extract_script}")

    jenkins_unavailable_fallback = False

    if args.pr:
        failed_rows = load_failed_stages(args.pr, extract_script)
    elif args.jenkins_url:
        if args.stage_hint:
            failed_rows = [
                {
                    "index": 1,
                    "pipeline": "Jenkins-Stage-Hint",
                    "stage": args.stage_hint,
                    "failure_type": "unknown",
                }
            ]
        else:
            try:
                rows = run_json(
                    [
                        extract_script,
                        "--jenkins-url",
                        args.jenkins_url,
                        "--list-failed-stages",
                        "--json",
                    ]
                )
                if not isinstance(rows, list):
                    raise RuntimeError("Invalid failed stage payload")
                failed_rows = [row for row in rows if isinstance(row, dict)]
                if not failed_rows and args.jira_title:
                    jenkins_unavailable_fallback = True
                    failed_rows = [
                        {
                            "index": 1,
                            "pipeline": "Jira-Title-Fallback",
                            "stage": "unknown",
                            "failure_type": "test_failed",
                        }
                    ]
            except RuntimeError:
                if args.jira_title:
                    jenkins_unavailable_fallback = True
                    failed_rows = [
                        {
                            "index": 1,
                            "pipeline": "Jira-Title-Fallback",
                            "stage": "unknown",
                            "failure_type": "test_failed",
                        }
                    ]
                else:
                    raise
    else:
        # Jira title mode (no Jenkins link provided)
        jenkins_unavailable_fallback = True
        failed_rows = [
            {
                "index": 1,
                "pipeline": "Jira-Title-Fallback",
                "stage": "unknown",
                "failure_type": "test_failed",
            }
        ]

    if not failed_rows and args.jenkins_url and args.stage_hint:
        failed_rows = [
            {
                "index": 1,
                "pipeline": "Jenkins-Stage-Hint",
                "stage": args.stage_hint,
                "failure_type": "unknown",
                "failed_case": "-",
            }
        ]

    if not failed_rows:
        raise RuntimeError("No failed stages available for this source")

    if args.selection is None and args.stage_hint:
        args.selection = 1

    if args.selection is None:
        if len(failed_rows) == 1:
            chosen = failed_rows[0]
            if not isinstance(chosen.get("index"), int):
                raise RuntimeError("Invalid stage index returned by failed-stage helper")
            args.selection = int(chosen["index"])
            print(f"Auto-selected only failed stage: {args.selection}")
        else:
            print("Multiple failed stages detected. Ask user which one to replicate:", file=sys.stderr)
            for row in failed_rows:
                idx = row.get("index", "?")
                pipeline = row.get("pipeline", "-")
                stage = row.get("stage", "-")
                failure = row.get("failure_type", "-")
                print(f"  {idx}) {pipeline} | {stage} | {failure}", file=sys.stderr)
            raise RuntimeError("Selection is required when more than one stage failed. Use --selection <n>")

    source_label = ""
    title = "-"
    env_exports: Dict[str, str] = {}
    fallback_reason = ""
    image_flag = "--images"
    if args.pr:
        pr_info = get_pr_info(args.pr)
        branch = pr_info.get("headRefName")
        if not branch:
            raise RuntimeError("Could not read PR headRefName")
        image_url = get_jenkins_israel3_image_url(pr_info.get("statusCheckRollup", []))
        forced_images = image_url
        stage_row = load_failed_stage(args.selection, args.pr, extract_script)
        original_dtest = load_selected_dtest(args.selection, args.pr, extract_script)
        source_label = f"PR: {REPO}#{pr_info.get('number')}"
        title = pr_info.get("title", "-")
    else:
        if args.branch:
            branch = args.branch.strip()
        elif args.affected_version:
            branch = branch_from_affected_version(args.affected_version)
        elif args.jenkins_url:
            inferred_branch = branch_from_jenkins_url(args.jenkins_url)
            if inferred_branch:
                branch = inferred_branch
            else:
                raise RuntimeError(
                    "Jenkins-link mode requires --branch or --affected-version (or a Jenkins URL containing dev_vX_Y)."
                )
        else:
            raise RuntimeError("Jira-title mode requires --affected-version or --branch")

        selected_rows = [r for r in failed_rows if r.get("index") == args.selection]
        if not selected_rows:
            raise RuntimeError(f"Selection {args.selection} not found in failed stage list")
        stage_row = selected_rows[0]

        if jenkins_unavailable_fallback:
            title_value = args.jira_title or ""
            original_dtest = dtest_from_jira_title(title_value)
            image_url = "latest"
            forced_images = None
            env_exports = {
                "RUNNER_NUMBER": "1",
                "MY_RUNNER_NUMBER": "1",
                "TOTAL_RUNNERS": "1",
            }
            source_label = f"Jira title fallback (Jenkins link unavailable): {title_value}"
            fallback_reason = "jenkins_unavailable"
        else:
            try:
                preferred_stage = args.stage_hint or str(stage_row.get("stage", ""))
                extracted = extract_dtest_and_env_from_jenkins_stage(
                    args.jenkins_url,
                    preferred_stage,
                )
                if not extracted:
                    raise RuntimeError("Could not extract dtest from Jenkins stage metadata")

                original_dtest, env_exports, resolved_stage = extracted
                stage_row = {
                    "stage": resolved_stage,
                    "failure_type": stage_row.get("failure_type", "unknown"),
                    "failed_case": stage_row.get("failed_case", "-"),
                }
                image_url = latest_branch_image_url(branch)
                forced_images = image_url
                image_flag = "--images-url"
                source_label = f"Jenkins link: {args.jenkins_url}"
            except RuntimeError:
                if not args.jira_title:
                    raise
                jenkins_unavailable_fallback = True
                title_value = args.jira_title
                original_dtest = dtest_from_jira_title(title_value)
                image_url = "latest"
                forced_images = None
                env_exports = {
                    "RUNNER_NUMBER": "1",
                    "MY_RUNNER_NUMBER": "1",
                    "TOTAL_RUNNERS": "1",
                }
                source_label = f"Jira title fallback (Jenkins link unavailable): {title_value}"
                fallback_reason = "stage_extraction_failed"

    rewritten_dtest = rewrite_dtest_for_remote(
        original_dtest,
        forced_images,
        image_flag=image_flag,
    )
    remote_script = build_remote_script(args.repo_dir, branch, rewritten_dtest, env_exports)

    tmux_session = FIXED_TMUX_SESSION

    print(source_label)
    print(f"Title: {title}")
    if jenkins_unavailable_fallback:
        reason = fallback_reason or "unknown"
        print(f"Notice: Jenkins path fallback activated (reason={reason}).")
        print("Using Jira title based rerun command.")
    print(f"Selected stage: {stage_row.get('stage', '-')}")
    print(f"Failure: {stage_row.get('failure_type', '-')} | Test: {stage_row.get('failed_case', '-')}")
    print(f"Branch: {branch}")
    print(f"Image URL (Jenkins-Israel-3): {image_url}")
    if env_exports:
        print(
            "Runner env: "
            f"RUNNER_NUMBER={env_exports.get('RUNNER_NUMBER', '-')} "
            f"MY_RUNNER_NUMBER={env_exports.get('MY_RUNNER_NUMBER', '-')} "
            f"TOTAL_RUNNERS={env_exports.get('TOTAL_RUNNERS', '-')}"
        )
    print("Original dtest:")
    print(original_dtest)
    print("Rewritten dtest:")
    print(rewritten_dtest)
    print(f"tmux session: {tmux_session}")

    if args.print_only:
        print("Remote command:")
        print(remote_script)
        try:
            remote_host = resolve_remote_kvm(args.kvm)
            attach_cmd = ssh_attach_command(remote_host, tmux_session)
            print(f"Remote host: {remote_host}")
            print(f"Attach command: {attach_cmd}")
            print(f"remote_tmux_attach {remote_host}")
            print("Direct connect now:")
            print(attach_cmd)
            print("Copy/paste in your prompt:")
            print(f"$ {attach_cmd}")
        except RuntimeError:
            pass
        return 0

    if not remote_kvm:
        raise RuntimeError("Remote host is missing")
    launcher = build_tmux_launcher(remote_script, tmux_session)

    print(f"Starting tmux session on {remote_kvm} ...")
    run_cmd(ssh_command(remote_kvm, launcher), check=True)
    attach_cmd = ssh_attach_command(remote_kvm, tmux_session)
    print("Remote replication started in tmux.")
    print("Attach with:")
    print(attach_cmd)
    print(f"remote_tmux_attach {remote_kvm}")
    print("Direct connect now:")
    print(attach_cmd)
    print("Copy/paste in your prompt:")
    print(f"$ {attach_cmd}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)

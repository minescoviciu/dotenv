#!/usr/bin/env python3

"""Find failed Jenkins stages and extract exact dtest for one stage.

Usage examples:
  # 1) Show failed stages (numbered)
  extract_stage_dtest.py --pr 89044 --list-failed-stages

  # 1b) Show failed stages from a direct Jenkins URL
  extract_stage_dtest.py --jenkins-url https://jenkins-aws6.../display/redirect --list-failed-stages

  # 2) Extract command for selected failed stage index
  extract_stage_dtest.py --pr 89044 --selection 1 --raw

  # 3) Manual fallback: extract by stage hint
  extract_stage_dtest.py --pr 89044 --stage emu-sa_dhcp_inband --raw
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional
SKILLS_ROOT = Path(__file__).resolve().parents[2]
if str(SKILLS_ROOT) not in sys.path:
    sys.path.insert(0, str(SKILLS_ROOT))

from jenkins_ci_shared import (
    JenkinsCIError,
    extract_dtest_from_stage_flow,
    fetch_text,
    list_failed_stages,
    normalize_token,
    to_console_url,
    to_stage_url,
)


REPO = "drivenets/cheetah"


@dataclass
class Check:
    context: str
    state: str
    target_url: str


@dataclass
class FailedStage:
    index: int
    context: str
    state: str
    target_url: str
    stage: str
    failure_type: str
    failed_test: str
    failed_env: str
    failed_file: str
    failed_case: str
    failure_details: str


def run_gh_json(cmd: List[str]) -> dict:
    try:
        out = subprocess.check_output(cmd, text=True)
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}") from exc
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Failed to parse gh JSON output") from exc


def failed_stage_names_from_wfapi(target_url: str) -> List[str]:
    try:
        return [stage.name for stage in list_failed_stages(target_url)]
    except JenkinsCIError:
        return []


def extract_dtest_from_stage_logs(target_url: str, stage_hint: str) -> Optional[str]:
    try:
        return extract_dtest_from_stage_flow(target_url, stage_hint=stage_hint)
    except JenkinsCIError:
        return None


def extract_stage_name(stage_page_text: str) -> Optional[str]:
    patterns = [
        re.compile(
            r"([A-Za-z0-9_.\-]+\s*\(\d+/\d+\))\s+is the stage that failed",
            re.IGNORECASE,
        ),
        re.compile(
            r"during\s+(tests_[A-Za-z0-9_.\-]+(?:_\(\d+/\d+\)|\s*\(\d+/\d+\))?)",
            re.IGNORECASE,
        ),
    ]

    for pattern in patterns:
        match = pattern.search(stage_page_text)
        if match:
            return match.group(1).strip()
    return None


def analyze_failure(console_text: str) -> tuple[str, str, str]:
    lines = console_text.splitlines()

    # Prefer explicit pytest failure marker.
    test_fail_re = re.compile(r"\bFAILED\s+([^\s]+)(?:\s+-\s+(.+))?")
    for line in lines:
        match = test_fail_re.search(line)
        if match:
            failed_test = match.group(1).strip()
            reason = (match.group(2) or "").strip()
            details = reason or "pytest failure"
            return ("test_failed", failed_test, details)

    # Fallback: detect environment/infrastructure failures.
    env_patterns = [
        r"ERROR: Execution failed",
        r"script returned exit code",
        r"Cannot connect",
        r"Connection timed out",
        r"No space left on device",
        r"docker: Error response from daemon",
        r"failed to pull",
        r"environment setup failed",
    ]
    env_re = re.compile("|".join(env_patterns), re.IGNORECASE)
    for line in lines:
        if env_re.search(line):
            return ("env_failed", "-", line.strip())

    return ("unknown", "-", "No explicit test/env failure marker found")


def split_failed_test(failed_test: str) -> tuple[str, str, str]:
    """Split pytest id into env, file stem, and test case.

    Example:
      emu_sa_inband/tests/.../test_dhcp_cli.py::TestDhcpCli::test_show_dhcp_interface[param]
    ->
      (emu_sa_inband, test_dhcp_cli, test_show_dhcp_interface[param])
    """
    if not failed_test or failed_test == "-":
        return ("-", "-", "-")

    parts = failed_test.split("::")
    path_part = parts[0]
    case_part = parts[-1] if len(parts) >= 2 else "-"

    path_tokens = path_part.split("/")
    env = path_tokens[0] if path_tokens else "-"

    filename = path_tokens[-1] if path_tokens else "-"
    if filename.endswith(".py"):
        filename = filename[:-3]

    return (env or "-", filename or "-", case_part or "-")


def extract_dtest_after_stage(console_text: str, stage_hint: str) -> List[str]:
    stage_norm = normalize_token(stage_hint)
    in_stage = False
    commands: List[str] = []

    for raw_line in console_text.splitlines():
        norm_line = normalize_token(raw_line)
        if stage_norm and stage_norm in norm_line:
            in_stage = True

        if not in_stage:
            continue

        if "+ dtest " in raw_line:
            cmd = raw_line.split("+ ", 1)[1].strip()
            commands.append(cmd)

    return commands


def first_dtest_after_stage(console_text: str, stage_hint: str) -> Optional[str]:
    commands = extract_dtest_after_stage(console_text, stage_hint)
    if not commands:
        return None
    return commands[0]


def first_dtest_anywhere(console_text: str) -> Optional[str]:
    for raw_line in console_text.splitlines():
        if "+ dtest " in raw_line:
            return raw_line.split("+ ", 1)[1].strip()

    loose = re.compile(r"\bdtest\s+[A-Za-z0-9_./-]+.*")
    for raw_line in console_text.splitlines():
        match = loose.search(raw_line)
        if match:
            return match.group(0).strip()
    return None


def get_checks_from_pr(pr: str) -> List[Check]:
    data = run_gh_json(
        [
            "gh",
            "pr",
            "view",
            pr,
            "--repo",
            REPO,
            "--json",
            "statusCheckRollup",
        ]
    )
    checks: List[Check] = []
    for item in data.get("statusCheckRollup", []):
        context = item.get("context")
        state = item.get("state")
        target_url = item.get("targetUrl")
        if not context or not state or not target_url:
            continue
        if not context.startswith("Jenkins"):
            continue
        checks.append(Check(context=context, state=state, target_url=target_url))
    return checks


def get_checks_from_jenkins_url(jenkins_url: str) -> List[Check]:
    url = jenkins_url.strip()
    if not url:
        return []
    return [Check(context="Jenkins-From-Link", state="ERROR", target_url=url)]


def get_failed_stages(checks: List[Check]) -> List[FailedStage]:
    failed_checks = [c for c in checks if c.state != "SUCCESS"]
    stages: List[FailedStage] = []
    idx = 1
    for check in failed_checks:
        wfapi_failed = failed_stage_names_from_wfapi(check.target_url)
        if wfapi_failed:
            for stage_name in wfapi_failed:
                stages.append(
                    FailedStage(
                        index=idx,
                        context=check.context,
                        state=check.state,
                        target_url=check.target_url,
                        stage=stage_name,
                        failure_type="unknown",
                        failed_test="-",
                        failed_env="-",
                        failed_file="-",
                        failed_case="-",
                        failure_details="Failed stage from Jenkins wfapi",
                    )
                )
                idx += 1
            continue

        stage_name = "unknown"
        failure_type = "unknown"
        failed_test = "-"
        failure_details = "No explicit test/env failure marker found"

        try:
            stage_page = fetch_text(to_stage_url(check.target_url))
        except RuntimeError:
            stage_page = ""

        parsed_stage = extract_stage_name(stage_page)
        if parsed_stage:
            stage_name = parsed_stage

        try:
            console_text = fetch_text(to_console_url(check.target_url))
            failure_type, failed_test, failure_details = analyze_failure(console_text)
        except RuntimeError:
            failure_type = "unknown"
            failed_test = "-"
            failure_details = "Could not access consoleText"

        failed_env, failed_file, failed_case = split_failed_test(failed_test)

        stages.append(
            FailedStage(
                index=idx,
                context=check.context,
                state=check.state,
                target_url=check.target_url,
                stage=stage_name,
                failure_type=failure_type,
                failed_test=failed_test,
                failed_env=failed_env,
                failed_file=failed_file,
                failed_case=failed_case,
                failure_details=failure_details,
            )
        )
        idx += 1
    return stages


def _truncate(value: str, width: int) -> str:
    if len(value) <= width:
        return value
    if width <= 3:
        return value[:width]
    return value[: width - 3] + "..."


def print_failed_stages_table(stages: List[FailedStage]) -> None:
    headers = [
        "#",
        "Pipeline",
        "Stage",
        "Failure",
        "Env",
        "File",
        "Test",
        "Details",
    ]
    rows = []
    for item in stages:
        rows.append(
            [
                str(item.index),
                item.context,
                item.stage,
                item.failure_type,
                item.failed_env,
                item.failed_file,
                item.failed_case,
                item.failure_details,
            ]
        )

    # Fixed max widths keep table readable in terminal.
    max_widths = [3, 24, 30, 12, 20, 20, 42, 80]
    widths = []
    for i, header in enumerate(headers):
        col_values = [header] + [row[i] for row in rows]
        widths.append(min(max(len(v) for v in col_values), max_widths[i]))

    def fmt_row(values: List[str]) -> str:
        rendered = []
        for i, value in enumerate(values):
            rendered.append(_truncate(value, widths[i]).ljust(widths[i]))
        return " | ".join(rendered)

    print(fmt_row(headers))
    print("-+-".join("-" * w for w in widths))
    for row in rows:
        print(fmt_row(row))


def print_failed_stages(source_label: str, stages: List[FailedStage]) -> None:
    print(f"{source_label} failed stages in {REPO}:")
    if not stages:
        print("No failed stages detected from accessible Jenkins pages.")
        return
    print_failed_stages_table(stages)
    print()
    for item in stages:
        print(f"{item.index}) {item.target_url}")
        if item.failed_test != "-":
            print(f"   env: {item.failed_env}")
            print(f"   file: {item.failed_file}")
            print(f"   test: {item.failed_case}")
        print(f"   details: {item.failure_details}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source_group = parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument("--pr", help="PR number or URL")
    source_group.add_argument("--jenkins-url", help="Direct Jenkins build URL")
    parser.add_argument("--stage", help="Manual stage hint, e.g. emu-sa_dhcp_inband")
    parser.add_argument(
        "--list-failed-stages",
        action="store_true",
        help="List failed Jenkins stages and exit",
    )
    parser.add_argument(
        "--selection",
        type=int,
        help="Number from --list-failed-stages output",
    )
    parser.add_argument(
        "--raw",
        action="store_true",
        help="Print only extracted dtest command lines",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print failed stage list as JSON (with --list-failed-stages)",
    )
    args = parser.parse_args()

    try:
        if args.pr:
            checks = get_checks_from_pr(args.pr)
            source_label = f"PR {args.pr}"
        else:
            checks = get_checks_from_jenkins_url(args.jenkins_url)
            source_label = f"Jenkins link {args.jenkins_url}"
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if not checks:
        if args.pr:
            print("No Jenkins checks found for PR", file=sys.stderr)
        else:
            print("No Jenkins data found for provided link", file=sys.stderr)
        return 1

    failed_stages = get_failed_stages(checks)

    if args.list_failed_stages:
        if args.json:
            payload = [
                {
                    "index": s.index,
                    "pipeline": s.context,
                    "state": s.state,
                    "stage": s.stage,
                    "failure_type": s.failure_type,
                    "failed_test": s.failed_test,
                    "failed_env": s.failed_env,
                    "failed_file": s.failed_file,
                    "failed_case": s.failed_case,
                    "failure_details": s.failure_details,
                    "target_url": s.target_url,
                }
                for s in failed_stages
            ]
            print(json.dumps(payload, indent=2))
            return 0
        print_failed_stages(source_label, failed_stages)
        return 0

    # Selection mode: choose stage discovered from failed checks.
    if args.selection is not None:
        selected = next((s for s in failed_stages if s.index == args.selection), None)
        if not selected:
            print(
                f"Invalid selection {args.selection}. Run with --list-failed-stages first.",
                file=sys.stderr,
            )
            return 1
        console_text: Optional[str] = None
        cmd = extract_dtest_from_stage_logs(selected.target_url, selected.stage)
        if not cmd:
            try:
                console_text = fetch_text(to_console_url(selected.target_url))
            except RuntimeError as exc:
                print(str(exc), file=sys.stderr)
                return 2
            cmd = first_dtest_after_stage(console_text, selected.stage)
        if not cmd and selected.stage == "unknown" and console_text is not None:
            cmd = first_dtest_anywhere(console_text)
        if not cmd:
            print(
                f"No dtest command found for selected stage '{selected.stage}'",
                file=sys.stderr,
            )
            return 1

        if args.raw:
            print(cmd)
            return 0

        print(f"[{selected.context}] stage={selected.stage} state={selected.state}")
        print(cmd)
        return 0

    # Manual stage mode fallback.
    if not args.stage:
        print(
            "Provide one of: --list-failed-stages, --selection, or --stage",
            file=sys.stderr,
        )
        return 1

    # Search non-success checks first, then all checks.
    phases = [
        [c for c in checks if c.state != "SUCCESS"],
        checks,
    ]

    results = []
    seen = set()
    for phase_checks in phases:
        for check in phase_checks:
            cmd_from_stage = extract_dtest_from_stage_logs(check.target_url, args.stage)
            if cmd_from_stage:
                key = (check.context, cmd_from_stage)
                if key not in seen:
                    seen.add(key)
                    results.append((check, cmd_from_stage))
                continue

            try:
                console_text = fetch_text(to_console_url(check.target_url))
            except RuntimeError:
                continue
            cmds = extract_dtest_after_stage(console_text, args.stage)
            for cmd in cmds:
                key = (check.context, cmd)
                if key in seen:
                    continue
                seen.add(key)
                results.append((check, cmd))
        if results:
            break

    if not results:
        print(f"No dtest command found for stage hint '{args.stage}'", file=sys.stderr)
        return 1

    if args.raw:
        for _, cmd in results:
            print(cmd)
        return 0

    for check, cmd in results:
        print(f"[{check.context}] state={check.state}")
        print(cmd)
    return 0


if __name__ == "__main__":
    sys.exit(main())

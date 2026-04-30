#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass
import json
import re
import time
from typing import Any, Dict, List, Optional, Sequence
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


@dataclass(frozen=True)
class StageInfo:
    id: str
    name: str
    status: str


@dataclass(frozen=True)
class RunInfo:
    run_url: str
    stages: List[StageInfo]
    raw: Dict[str, Any]


@dataclass(frozen=True)
class StageNode:
    id: str
    name: str
    log_href: Optional[str]
    parameter_description: str


@dataclass(frozen=True)
class StageDetails:
    stage_id: str
    nodes: List[StageNode]
    raw: Dict[str, Any]


class JenkinsCIError(RuntimeError):
    def __init__(self, reason: str, details: Optional[str] = None) -> None:
        self.reason = reason
        self.details = details
        message = f"reason={reason}"
        if details:
            message = f"{message}: {details}"
        super().__init__(message)


def normalize_token(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def normalize_stage(value: str) -> str:
    return normalize_token(value)


def normalize_run_url(target_url: str) -> str:
    url = target_url.strip()
    if not url:
        raise JenkinsCIError("invalid_jenkins_url", "empty URL")
    if url.endswith("/display/redirect"):
        return url[: -len("/display/redirect")].rstrip("/") + "/"
    if url.endswith("/consoleText"):
        return url[: -len("/consoleText")].rstrip("/") + "/"
    if "/execution/node/" in url:
        return url.split("/execution/node/", 1)[0].rstrip("/") + "/"
    return url.rstrip("/") + "/"


def to_console_url(target_url: str) -> str:
    if target_url.endswith("/consoleText"):
        return target_url
    if target_url.endswith("/display/redirect"):
        return f"{target_url[:-len('/display/redirect')]}/consoleText"
    return f"{target_url.rstrip('/')}/consoleText"


def to_stage_url(target_url: str) -> str:
    if target_url.endswith("/consoleText"):
        return f"{target_url[:-len('/consoleText')]}/display/redirect"
    return target_url


def fetch_text(
    url: str,
    timeout: int = 30,
    retries: int = 2,
    backoff_sec: float = 1.0,
    user_agent: str = "skills-jenkins-ci",
) -> str:
    if not url.strip():
        raise JenkinsCIError("invalid_jenkins_url", "empty URL")

    last_exc: Optional[Exception] = None
    for attempt in range(retries + 1):
        req = Request(url, headers={"User-Agent": user_agent})
        try:
            with urlopen(req, timeout=timeout) as resp:
                return resp.read().decode("utf-8", errors="replace")
        except HTTPError as exc:
            code_reason = {
                401: "jenkins_http_401",
                403: "jenkins_http_403",
                404: "jenkins_http_404",
            }
            if exc.code in code_reason:
                raise JenkinsCIError(code_reason[exc.code], f"{url}") from exc
            last_exc = exc
        except (URLError, TimeoutError) as exc:
            last_exc = exc

        if attempt < retries:
            time.sleep(backoff_sec * (attempt + 1))

    details = f"{url} ({last_exc})" if last_exc else url
    raise JenkinsCIError("jenkins_fetch_failed", details)


def fetch_json(
    url: str,
    timeout: int = 30,
    retries: int = 2,
    backoff_sec: float = 1.0,
) -> Dict[str, Any]:
    text = fetch_text(url, timeout=timeout, retries=retries, backoff_sec=backoff_sec)
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise JenkinsCIError("jenkins_invalid_json", url) from exc


def _parse_stage(stage: Any) -> Optional[StageInfo]:
    if not isinstance(stage, dict):
        return None
    sid = str(stage.get("id", "")).strip()
    name = str(stage.get("name", "")).strip()
    if not sid or not name:
        return None
    status = str(stage.get("status", "")).strip().upper()
    return StageInfo(id=sid, name=name, status=status)


def get_run_wfapi(
    target_url: str,
    timeout: int = 30,
    retries: int = 1,
) -> RunInfo:
    run_url = normalize_run_url(target_url)
    data = fetch_json(f"{run_url}wfapi/describe", timeout=timeout, retries=retries)
    stages: List[StageInfo] = []
    for stage in data.get("stages", []):
        parsed = _parse_stage(stage)
        if parsed:
            stages.append(parsed)
    return RunInfo(run_url=run_url, stages=stages, raw=data)


def list_failed_stages(target_url: str) -> List[StageInfo]:
    run_info = get_run_wfapi(target_url, timeout=30, retries=1)
    return [stage for stage in run_info.stages if stage.status == "FAILED"]


def find_stage_by_hint(stages: Sequence[StageInfo], stage_hint: str) -> Optional[StageInfo]:
    hint = normalize_stage(stage_hint)
    if not hint:
        return None
    for stage in stages:
        name_norm = normalize_stage(stage.name)
        if hint and (hint in name_norm or name_norm in hint):
            return stage
    return None


def select_stage(
    run_info: RunInfo,
    stage_hint: Optional[str] = None,
    prefer_failed: bool = True,
) -> Optional[StageInfo]:
    if stage_hint:
        matched = find_stage_by_hint(run_info.stages, stage_hint)
        if matched:
            return matched
    if prefer_failed:
        for stage in run_info.stages:
            if stage.status == "FAILED":
                return stage
    if len(run_info.stages) == 1:
        return run_info.stages[0]
    return None


def get_stage_wfapi(
    target_url: str,
    stage_id: str,
    timeout: int = 30,
    retries: int = 1,
) -> StageDetails:
    sid = stage_id.strip()
    if not sid:
        raise JenkinsCIError("stage_wfapi_missing", "stage id is empty")
    run_url = normalize_run_url(target_url)
    data = fetch_json(
        f"{run_url}execution/node/{sid}/wfapi/describe",
        timeout=timeout,
        retries=retries,
    )
    nodes: List[StageNode] = []
    for node in data.get("stageFlowNodes", []):
        if not isinstance(node, dict):
            continue
        links = node.get("_links", {})
        log_href = None
        if isinstance(links, dict):
            log_data = links.get("log", {})
            if isinstance(log_data, dict):
                value = str(log_data.get("href", "")).strip()
                log_href = value or None
        nodes.append(
            StageNode(
                id=str(node.get("id", "")).strip(),
                name=str(node.get("name", "")).strip(),
                log_href=log_href,
                parameter_description=str(node.get("parameterDescription", "")),
            )
        )
    return StageDetails(stage_id=sid, nodes=nodes, raw=data)


def _strip_html(text: str) -> str:
    return re.sub(r"<[^>]+>", "", text)


def extract_dtest_from_stage_flow(
    target_url: str,
    stage_hint: Optional[str] = None,
    stage_id: Optional[str] = None,
    node_limit: int = 40,
) -> Optional[str]:
    run_info = get_run_wfapi(target_url, timeout=60, retries=1)
    stage: Optional[StageInfo] = None
    if stage_id:
        for candidate in run_info.stages:
            if candidate.id == stage_id:
                stage = candidate
                break
    elif stage_hint:
        stage = find_stage_by_hint(run_info.stages, stage_hint)
    else:
        stage = select_stage(run_info, stage_hint=stage_hint, prefer_failed=True)

    if not stage:
        return None

    stage_data = get_stage_wfapi(target_url, stage.id, timeout=60, retries=1)
    candidate_nodes: List[StageNode] = []
    for node in stage_data.nodes:
        name = node.name.lower()
        if any(token in name for token in ("dtest", "pytest", "test", "run")):
            candidate_nodes.append(node)
    if not candidate_nodes:
        candidate_nodes = list(stage_data.nodes)

    dtest_loose = re.compile(r"\bdtest\s+[A-Za-z0-9_./-]+.*")
    for node in candidate_nodes[: max(1, node_limit)]:
        if not node.log_href:
            continue
        log_url = urljoin(run_info.run_url, node.log_href)
        try:
            payload = fetch_json(log_url, timeout=8, retries=0)
        except JenkinsCIError:
            continue
        raw_text = str(payload.get("text", ""))
        text = _strip_html(raw_text)
        for line in text.splitlines():
            if "+ dtest " in line:
                return line.split("+ ", 1)[1].strip()
            match = dtest_loose.search(line)
            if match:
                return match.group(0).strip()
    return None


def wfapi_failed_stages(target_url: str) -> List[Dict[str, str]]:
    return [{"id": stage.id, "name": stage.name} for stage in list_failed_stages(target_url)]


def match_failed_stage(target_url: str, stage_hint: str) -> Optional[Dict[str, str]]:
    matched = find_stage_by_hint(list_failed_stages(target_url), stage_hint)
    if not matched:
        return None
    return {"id": matched.id, "name": matched.name}


def stage_name_to_artifact_slug(stage_name: str) -> str:
    s = stage_name.strip()
    s = re.sub(r"\((\d+)\s*/\s*(\d+)\)", r"_\1-\2", s)
    s = re.sub(r"[^A-Za-z0-9_-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s


def artifact_zip_url_for_stage(target_url: str, stage_name: str) -> str:
    run_url = normalize_run_url(target_url)
    slug = stage_name_to_artifact_slug(stage_name)
    return f"{run_url}artifact/{slug}/*zip*/{slug}.zip"


def extract_jenkins_urls(text: str) -> List[str]:
    urls = re.findall(r"https?://[^\s)\]>]+jenkins[^\s)\]>]*", text, flags=re.IGNORECASE)
    dedup: List[str] = []
    seen = set()
    for url in urls:
        u = url.strip().rstrip(".,")
        if u in seen:
            continue
        seen.add(u)
        dedup.append(u)
    return dedup


def extract_stage_hint_from_text(text: str) -> Optional[str]:
    patterns = [
        r"during\s+(tests_[A-Za-z0-9_.\-]+(?:_\(\d+/\d+\)|\s*\(\d+/\d+\))?)",
        r"(tests_[A-Za-z0-9_.\-]+\s*\(\d+/\d+\))\s+is the stage that failed",
    ]
    for pattern in patterns:
        m = re.search(pattern, text, flags=re.IGNORECASE)
        if m:
            return m.group(1).strip()
    return None

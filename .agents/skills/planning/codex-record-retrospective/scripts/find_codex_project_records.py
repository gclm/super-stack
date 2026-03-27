#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class Match:
    source: str
    file: str
    session_id: str | None
    strength: str
    reason: str
    snippet: str


@dataclass(frozen=True)
class PathTarget:
    label: str
    path: str


def short(text: str, limit: int = 220) -> str:
    text = " ".join(text.split())
    if len(text) <= limit:
        return text
    return text[: limit - 3] + "..."


def iter_strings(value: object) -> Iterable[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from iter_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_strings(child)


def load_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows


GENERIC_TOKENS = {
    "agent",
    "agents",
    "app",
    "apps",
    "api",
    "bin",
    "client",
    "code",
    "codes",
    "core",
    "demo",
    "docs",
    "plugin",
    "plugins",
    "project",
    "projects",
    "repo",
    "sdk",
    "server",
    "service",
    "services",
    "stack",
    "test",
    "tests",
    "tool",
    "tools",
    "user",
    "users",
    "web",
    "workspace",
}


def project_terms(project_path: Path) -> list[str]:
    project_name = project_path.name.lower()
    terms = {project_name}

    compact_name = re.sub(r"[^a-z0-9]+", "", project_name)
    if compact_name and compact_name != project_name and len(compact_name) >= 6:
        terms.add(compact_name)

    parent_name = project_path.parent.name.lower()
    if parent_name and parent_name not in GENERIC_TOKENS and len(parent_name) >= 4:
        terms.add(f"{parent_name}/{project_name}")
        terms.add(f"{parent_name}-{project_name}")

    return sorted(terms)


def contains_term(strings: Iterable[str], terms: list[str]) -> str | None:
    lowered_strings = [s.lower() for s in strings]
    for term in terms:
        for text in lowered_strings:
            if term == text:
                return term
            if any(separator in term for separator in "/-_"):
                if term in text:
                    return term
                continue
            if re.search(rf"(?<![a-z0-9]){re.escape(term)}(?![a-z0-9])", text):
                return term
    return None


def find_exact_path_match(strings: Iterable[str], targets: list[PathTarget]) -> PathTarget | None:
    for text in strings:
        for target in targets:
            if target.path in text:
                return target
    return None


def scan_session_like_file(path: Path, targets: list[PathTarget], terms: list[str], source: str) -> list[Match]:
    matches: list[Match] = []
    rows = load_jsonl(path)
    session_id: str | None = None
    for row in rows:
        if row.get("type") == "session_meta":
            payload = row.get("payload", {})
            session_id = payload.get("id") or session_id
            cwd = str(payload.get("cwd", ""))
            cwd_target = next((target for target in targets if cwd == target.path), None)
            if cwd_target:
                reason = "session_meta.cwd exact match"
                if cwd_target.label != "primary":
                    reason = f"{cwd_target.label} path session_meta.cwd exact match"
                matches.append(
                    Match(
                        source=source,
                        file=str(path),
                        session_id=session_id,
                        strength="strong",
                        reason=reason,
                        snippet=short(json.dumps(payload, ensure_ascii=False)),
                    )
                )
                continue
        strings = list(iter_strings(row))
        exact_target = find_exact_path_match(strings, targets)
        if exact_target:
            reason = "exact project path mention"
            if exact_target.label != "primary":
                reason = f"exact {exact_target.label} path mention"
            matches.append(
                Match(
                    source=source,
                    file=str(path),
                    session_id=session_id,
                    strength="strong",
                    reason=reason,
                    snippet=short(next(s for s in strings if exact_target.path in s)),
                )
            )
            continue
        term = contains_term(strings, terms)
        if term:
            matches.append(
                Match(
                    source=source,
                    file=str(path),
                    session_id=session_id,
                    strength="weak",
                    reason=f"related term match: {term}",
                    snippet=short(next(s for s in strings if term in s.lower())),
                )
            )
    return matches


def scan_history(path: Path, targets: list[PathTarget], terms: list[str]) -> list[Match]:
    matches: list[Match] = []
    rows = load_jsonl(path)
    for row in rows:
        text = str(row.get("text", ""))
        session_id = row.get("session_id")
        exact_target = next((target for target in targets if target.path in text), None)
        if exact_target:
            reason = "exact project path mention"
            if exact_target.label != "primary":
                reason = f"exact {exact_target.label} path mention"
            matches.append(
                Match(
                    source="history",
                    file=str(path),
                    session_id=session_id,
                    strength="strong",
                    reason=reason,
                    snippet=short(text),
                )
            )
            continue
        lowered = text.lower()
        term = next((term for term in terms if term in lowered), None)
        if term:
            matches.append(
                Match(
                    source="history",
                    file=str(path),
                    session_id=session_id,
                    strength="weak",
                    reason=f"related term match: {term}",
                    snippet=short(text),
                )
            )
    return matches


def scan_session_index(path: Path, targets: list[PathTarget], terms: list[str]) -> list[Match]:
    matches: list[Match] = []
    rows = load_jsonl(path)
    for row in rows:
        strings = list(iter_strings(row))
        exact_target = find_exact_path_match(strings, targets)
        if exact_target:
            reason = "exact project path mention"
            if exact_target.label != "primary":
                reason = f"exact {exact_target.label} path mention"
            matches.append(
                Match(
                    source="session_index",
                    file=str(path),
                    session_id=row.get("id"),
                    strength="medium",
                    reason=reason,
                    snippet=short(json.dumps(row, ensure_ascii=False)),
                )
            )
            continue
        term = contains_term(strings, terms)
        if term:
            matches.append(
                Match(
                    source="session_index",
                    file=str(path),
                    session_id=row.get("id"),
                    strength="weak",
                    reason=f"related term match: {term}",
                    snippet=short(json.dumps(row, ensure_ascii=False)),
                )
            )
    return matches


def build_targets(project_path: Path, alias_paths: list[Path]) -> list[PathTarget]:
    seen: set[str] = set()
    targets: list[PathTarget] = []

    primary = str(project_path)
    targets.append(PathTarget(label="primary", path=primary))
    seen.add(primary)

    for index, alias_path in enumerate(alias_paths, start=1):
        alias = str(alias_path)
        if alias in seen:
            continue
        targets.append(PathTarget(label=f"alias{index}", path=alias))
        seen.add(alias)

    return targets


def build_report(project_path: Path, alias_paths: list[Path], codex_home: Path, max_samples: int) -> dict[str, object]:
    targets = build_targets(project_path, alias_paths)
    terms = sorted({term for path in [project_path, *alias_paths] for term in project_terms(path)})
    matches: list[Match] = []
    checked_sources: list[str] = []

    session_index = codex_home / "session_index.jsonl"
    if session_index.exists():
        checked_sources.append(str(session_index))
        matches.extend(scan_session_index(session_index, targets, terms))

    sessions_dir = codex_home / "sessions"
    if sessions_dir.exists():
        checked_sources.append(str(sessions_dir))
        for path in sorted(sessions_dir.rglob("*.jsonl")):
            matches.extend(scan_session_like_file(path, targets, terms, "sessions"))

    archived_dir = codex_home / "archived_sessions"
    if archived_dir.exists():
        checked_sources.append(str(archived_dir))
        for path in sorted(archived_dir.glob("*.jsonl")):
            matches.extend(scan_session_like_file(path, targets, terms, "archived_sessions"))

    history = codex_home / "history.jsonl"
    if history.exists():
        checked_sources.append(str(history))
        matches.extend(scan_history(history, targets, terms))

    by_source = Counter(match.source for match in matches)
    by_strength = Counter(match.strength for match in matches)
    sessions = defaultdict(list)
    for match in matches:
        if match.session_id:
            sessions[match.session_id].append(match)

    evidence_gaps: list[str] = []
    if not matches:
        evidence_gaps.append("未在已索引记录中找到该项目路径的直接命中。可能是会话尚未入库，或项目在记录中只以弱上下文出现。")
    elif not by_strength.get("strong"):
        evidence_gaps.append("只找到弱相关命中，没有找到 `cwd` 或项目绝对路径的强证据。")
    if not any(
        match.source in {"sessions", "archived_sessions"} and "session_meta.cwd exact match" in match.reason
        for match in matches
    ):
        evidence_gaps.append("未找到 `session_meta.cwd` 的精确匹配，当前还不能完全确认是哪一条 session 对应目标项目。")

    sample_matches = []
    for match in matches[:max_samples]:
        sample_matches.append(
            {
                "source": match.source,
                "file": match.file,
                "session_id": match.session_id,
                "strength": match.strength,
                "reason": match.reason,
                "snippet": match.snippet,
            }
        )

    session_summaries = []
    ranked_sessions = sorted(
        sessions.items(),
        key=lambda item: (
            -sum(1 for match in item[1] if match.strength == "strong"),
            -len(item[1]),
            item[0],
        ),
    )

    for session_id, items in ranked_sessions[:max_samples]:
        session_summaries.append(
            {
                "session_id": session_id,
                "match_count": len(items),
                "strong_matches": sum(1 for item in items if item.strength == "strong"),
                "sources": sorted({item.source for item in items}),
            }
        )

    return {
        "project_path": str(project_path),
        "project_aliases": [target.path for target in targets if target.label != "primary"],
        "codex_home": str(codex_home),
        "checked_sources": checked_sources,
        "project_terms": terms,
        "match_counts": {
            "total": len(matches),
            "by_source": dict(by_source),
            "by_strength": dict(by_strength),
            "sessions": len(sessions),
        },
        "evidence_gaps": evidence_gaps,
        "candidate_sessions": session_summaries,
        "sample_matches": sample_matches,
    }


def render_markdown(report: dict[str, object]) -> str:
    lines = ["# Codex Project Record Scan", ""]
    lines.append(f"- 项目路径: `{report['project_path']}`")
    aliases = report.get("project_aliases") or []
    if aliases:
        lines.append(f"- 路径别名: {', '.join(f'`{item}`' for item in aliases)}")
    lines.append(f"- Codex 目录: `{report['codex_home']}`")
    lines.append(f"- 扫描源数量: {len(report['checked_sources'])}")
    lines.append("")
    counts = report["match_counts"]
    lines.append("## 命中统计")
    lines.append(f"- 总命中: {counts['total']}")
    lines.append(f"- 候选 sessions: {counts['sessions']}")
    lines.append(f"- 按来源: {counts['by_source']}")
    lines.append(f"- 按强度: {counts['by_strength']}")
    lines.append("")
    lines.append("## 证据缺口")
    if report["evidence_gaps"]:
        for item in report["evidence_gaps"]:
            lines.append(f"- {item}")
    else:
        lines.append("- 当前未发现明显证据缺口。")
    lines.append("")
    lines.append("## 候选 Sessions")
    if report["candidate_sessions"]:
        for item in report["candidate_sessions"]:
            lines.append(
                f"- `{item['session_id']}`: 命中 {item['match_count']} 条，强命中 {item['strong_matches']} 条，来源 {', '.join(item['sources'])}"
            )
    else:
        lines.append("- 暂无候选 session。")
    lines.append("")
    lines.append("## 样本命中")
    if report["sample_matches"]:
        for item in report["sample_matches"]:
            lines.append(
                f"- [{item['strength']}] {item['source']} / `{item['session_id'] or 'n/a'}` / {item['reason']}: {item['snippet']}"
            )
    else:
        lines.append("- 暂无样本命中。")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Locate Codex local records related to a specific project path.")
    parser.add_argument("--project-path", required=True)
    parser.add_argument(
        "--project-path-alias",
        action="append",
        default=[],
        help="Additional historical or migrated project path to scan alongside the primary project path. Repeatable.",
    )
    parser.add_argument("--codex-home", default=str(Path.home() / ".codex"))
    parser.add_argument("--max-samples", type=int, default=12)
    parser.add_argument("--format", choices=["json", "markdown"], default="markdown")
    args = parser.parse_args()

    report = build_report(
        project_path=Path(args.project_path).expanduser().resolve(),
        alias_paths=[Path(item).expanduser().resolve() for item in args.project_path_alias],
        codex_home=Path(args.codex_home).expanduser().resolve(),
        max_samples=max(args.max_samples, 1),
    )
    if args.format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(render_markdown(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

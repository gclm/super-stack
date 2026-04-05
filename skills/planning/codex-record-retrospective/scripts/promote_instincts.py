#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any


def load_instincts_from_projects(projects_root: Path) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    if not projects_root.exists():
        return grouped

    for project_dir in sorted(projects_root.iterdir()):
        active_dir = project_dir / "instincts" / "active"
        if not active_dir.is_dir():
            continue
        for file_path in sorted(active_dir.glob("*.json")):
            try:
                payload = json.loads(file_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
            instinct_id = payload.get("id")
            if instinct_id:
                grouped[str(instinct_id)].append(payload)
    return grouped


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def ensure_ledger_file(ledger_path: Path | None) -> None:
    if ledger_path is None:
        return
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    ledger_path.touch(exist_ok=True)


def append_ledger_entry(ledger_path: Path | None, payload: dict[str, Any]) -> None:
    if ledger_path is None:
        return
    ensure_ledger_file(ledger_path)
    with ledger_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False) + "\n")


def build_global_instinct(instinct_id: str, entries: list[dict[str, Any]]) -> dict[str, Any]:
    best = max(entries, key=lambda item: float(item.get("confidence", 0.0)))
    source_projects = sorted({str(item.get("project_id")) for item in entries if item.get("project_id")})
    return {
        "id": instinct_id,
        "scope": "global",
        "trigger": best.get("trigger"),
        "action": best.get("action"),
        "confidence": max(float(item.get("confidence", 0.0)) for item in entries),
        "domain": best.get("domain"),
        "source": "promoted-from-project-instincts",
        "occurrence_count": sum(int(item.get("occurrence_count", 0)) for item in entries),
        "last_seen": max(str(item.get("last_seen") or "") for item in entries),
        "status": "active",
        "source_projects": source_projects,
        "evidence_refs": [ref for item in entries for ref in item.get("evidence_refs", [])],
    }


def build_recommendation(instinct: dict[str, Any]) -> dict[str, Any]:
    target_files = ["protocols/verify.md"] if instinct.get("domain") == "verify" else ["skills/planning/codex-record-retrospective/references/instinct-schema.md"]
    return {
        "schema_version": "v1",
        "project_id": instinct.get("project_id"),
        "project_name": instinct.get("project_name"),
        "source_instinct_id": instinct.get("id"),
        "summary": instinct.get("action"),
        "problem_type": instinct.get("domain"),
        "target_files": target_files,
        "change_kind": "reference-update",
        "approval_level": "patch-proposed",
        "evidence_refs": instinct.get("evidence_refs", []),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Promote project instincts and generate recommendation artifacts.")
    parser.add_argument("--projects-root", required=True)
    parser.add_argument("--global-dir", required=True)
    parser.add_argument("--recommendations-dir", required=True)
    parser.add_argument("--ledger")
    args = parser.parse_args()

    projects_root = Path(args.projects_root).expanduser().resolve()
    global_dir = Path(args.global_dir).expanduser().resolve()
    recommendations_dir = Path(args.recommendations_dir).expanduser().resolve()
    ledger_path = Path(args.ledger).expanduser().resolve() if args.ledger else None

    grouped = load_instincts_from_projects(projects_root)
    ensure_ledger_file(ledger_path)
    promoted = 0
    recommended = 0

    for instinct_id, entries in grouped.items():
        project_ids = {str(item.get("project_id")) for item in entries if item.get("project_id")}
        if len(project_ids) >= 2:
            write_json(global_dir / f"{instinct_id}.json", build_global_instinct(instinct_id, entries))
            append_ledger_entry(
                ledger_path,
                {
                    "lesson_id": instinct_id,
                    "recommendation_status": "accepted",
                    "scope": "global",
                    "source_projects": sorted(project_ids),
                },
            )
            promoted += 1
            continue

        best = max(entries, key=lambda item: float(item.get("confidence", 0.0)))
        if float(best.get("confidence", 0.0)) >= 0.7:
            recommendation_path = recommendations_dir / f"{instinct_id}.json"
            if recommendation_path.exists():
                continue
            write_json(recommendation_path, build_recommendation(best))
            append_ledger_entry(
                ledger_path,
                {
                    "lesson_id": instinct_id,
                    "recommendation_status": "patch-proposed",
                    "scope": "project",
                    "project_id": best.get("project_id"),
                },
            )
            recommended += 1

    print(json.dumps({"promoted": promoted, "recommended": recommended}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

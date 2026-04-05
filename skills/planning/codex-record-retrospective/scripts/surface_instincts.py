#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

STAGE_DOMAIN_HINTS = {
    "verify": {"verify"},
    "build": {"workflow", "project-convention"},
    "review": {"verify", "project-convention"},
    "retrospective": {"workflow", "verify", "routing", "project-convention"},
}


def load_instinct_files(instinct_dir: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not instinct_dir.is_dir():
        return rows
    for path in sorted(instinct_dir.glob("*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        if isinstance(payload, dict):
            rows.append(payload)
    return rows


def load_project_instincts(projects_root: Path, project_id: str, include_pending: bool) -> list[dict[str, Any]]:
    project_root = projects_root / project_id / "instincts"
    instincts = load_instinct_files(project_root / "active")
    if include_pending:
        instincts.extend(load_instinct_files(project_root / "pending"))
    return instincts


def score_instinct(instinct: dict[str, Any], stage: str | None, signals: list[str]) -> float:
    score = float(instinct.get("confidence", 0.0))
    domain = str(instinct.get("domain") or "")
    action = str(instinct.get("action") or "").lower()
    trigger = str(instinct.get("trigger") or "").lower()
    metadata = instinct.get("metadata") or {}
    negative_feedback_count = int(instinct.get("negative_feedback_count", 0) or 0)

    if stage and domain in STAGE_DOMAIN_HINTS.get(stage, set()):
        score += 0.25
    elif stage and domain == stage:
        score += 0.35

    for signal in signals:
        lowered = signal.lower()
        if lowered and (lowered in action or lowered in trigger):
            score += 0.15

    occurrence_count = int(instinct.get("occurrence_count", 0) or 0)
    score += min(0.15, occurrence_count * 0.02)
    score -= negative_feedback_count * 0.12

    if instinct.get("status") == "pending":
        score -= 0.1
    if isinstance(metadata, dict) and metadata.get("demotion_reason"):
        score -= 0.05

    return round(score, 4)


def surface_instincts(instincts: list[dict[str, Any]], stage: str | None, signals: list[str], top_k: int) -> list[dict[str, Any]]:
    ranked: list[dict[str, Any]] = []
    for instinct in instincts:
        surfaced = dict(instinct)
        surfaced["surface_score"] = score_instinct(instinct, stage, signals)
        ranked.append(surfaced)
    ranked.sort(key=lambda item: (float(item.get("surface_score", 0.0)), float(item.get("confidence", 0.0))), reverse=True)
    return ranked[:top_k]


def write_output(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Surface relevant instincts for a new Codex session or workflow stage.")
    parser.add_argument("--projects-root", required=True)
    parser.add_argument("--project-id", required=True)
    parser.add_argument("--stage")
    parser.add_argument("--signal", action="append", default=[])
    parser.add_argument("--top-k", type=int, default=5)
    parser.add_argument("--include-pending", action="store_true")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    projects_root = Path(args.projects_root).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()
    instincts = load_project_instincts(projects_root, args.project_id, args.include_pending)
    surfaced = surface_instincts(instincts, args.stage, args.signal, args.top_k)

    payload = {
        "project_id": args.project_id,
        "stage": args.stage,
        "signals": args.signal,
        "surfaced": surfaced,
    }
    write_output(output_path, payload)
    print(json.dumps({"surfaced_count": len(surfaced), "output": str(output_path)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

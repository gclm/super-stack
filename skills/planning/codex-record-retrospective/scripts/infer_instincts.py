#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                rows.append(row)
    return rows


def confidence_for_count(count: int) -> float:
    if count <= 0:
        return 0.0
    if count <= 2:
        return 0.3
    if count <= 5:
        return 0.5
    if count <= 10:
        return 0.7
    return 0.85


def instinct_key(observation: dict[str, Any]) -> tuple[str, str, str, str]:
    event_type = str(observation.get("event_type") or "message")
    tool = str(observation.get("tool") or "message")
    summary = str(observation.get("summary") or "")
    project_id = str(observation.get("project_id") or "global")
    return (project_id, event_type, tool, summary)


def feedback_key(project_id: str, event_type: str, tool: str) -> tuple[str, str, str]:
    return (project_id, event_type, tool or "message")


def infer_domain(event_type: str) -> str:
    if event_type in {"verify_success", "verify_gap"}:
        return "verify"
    if event_type == "user_correction":
        return "routing"
    if event_type.startswith("tool_"):
        return "workflow"
    return "project-convention"


def infer_trigger(event_type: str, tool: str, summary: str) -> str:
    if event_type.startswith("tool_") and tool != "message":
        return f"when using tool {tool}"
    if event_type == "verify_success":
        return "when a verify path repeatedly succeeds"
    if event_type == "verify_gap":
        return "when verify repeatedly reveals the same gap"
    if event_type == "user_correction":
        return "when the user repeatedly corrects the same workflow choice"
    return f"when observing repeated pattern: {summary}"


def infer_action(event_type: str, tool: str, summary: str) -> str:
    if event_type.startswith("tool_") and tool != "message":
        return f"Prefer using {tool} when this workflow pattern appears."
    if event_type == "verify_success":
        return f"Reuse this verification path: {summary}"
    if event_type == "verify_gap":
        return f"Address this recurring verification gap: {summary}"
    if event_type == "user_correction":
        return f"Avoid repeating this user-corrected pattern: {summary}"
    return summary


def weighted_confidence(event_type: str, count: int, negative_feedback_count: int = 0) -> float:
    confidence = confidence_for_count(count)
    if event_type == "verify_success":
        confidence += 0.05
    if event_type == "user_correction":
        confidence -= 0.2
    confidence -= 0.15 * negative_feedback_count
    return max(0.0, min(0.95, round(confidence, 2)))


def slugify(value: str) -> str:
    return value.strip().lower().replace("_", "-").replace(" ", "-")


def collect_negative_feedback(observations: list[dict[str, Any]]) -> dict[tuple[str, str, str], int]:
    counts: dict[tuple[str, str, str], int] = defaultdict(int)
    for observation in observations:
        if observation.get("event_type") != "user_correction":
            continue
        metadata = observation.get("metadata") or {}
        if not isinstance(metadata, dict):
            continue
        corrected_event_type = metadata.get("corrects_event_type")
        corrected_tool = metadata.get("corrects_tool") or "message"
        if not corrected_event_type:
            continue
        project_id = str(observation.get("project_id") or "global")
        counts[feedback_key(project_id, str(corrected_event_type), str(corrected_tool))] += 1
    return counts


def infer_instincts(observations: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str, str, str], list[dict[str, Any]]] = defaultdict(list)
    for observation in observations:
        grouped[instinct_key(observation)].append(observation)

    negative_feedback = collect_negative_feedback(observations)
    instincts: list[dict[str, Any]] = []
    for (project_id, event_type, tool, summary), items in grouped.items():
        occurrence_count = len(items)
        first = items[0]
        negative_feedback_count = negative_feedback.get(feedback_key(project_id, event_type, tool), 0)
        confidence = weighted_confidence(event_type, occurrence_count, negative_feedback_count)
        status = "active" if occurrence_count >= 3 and event_type != "user_correction" and negative_feedback_count == 0 else "pending"
        domain = infer_domain(event_type)
        instinct_id = f"{slugify(event_type)}-{slugify(tool)}"
        if tool == "message":
            instinct_id = f"{slugify(event_type)}-message"

        metadata: dict[str, Any] = {}
        if negative_feedback_count > 0:
            metadata["demotion_reason"] = f"Demoted by {negative_feedback_count} user correction signal(s)."

        instincts.append(
            {
                "id": instinct_id,
                "scope": "project",
                "project_id": project_id,
                "project_name": first.get("project_name") or project_id,
                "trigger": infer_trigger(event_type, tool, summary),
                "action": infer_action(event_type, tool, summary),
                "confidence": confidence,
                "domain": domain,
                "source": "codex-observation",
                "occurrence_count": occurrence_count,
                "negative_feedback_count": negative_feedback_count,
                "last_seen": items[-1].get("timestamp"),
                "status": status,
                "evidence_refs": [ref for item in items for ref in item.get("evidence_refs", [])],
                "metadata": metadata,
            }
        )
    return instincts


def write_instincts(output_dir: Path, instincts: list[dict[str, Any]]) -> None:
    active_dir = output_dir / "active"
    pending_dir = output_dir / "pending"
    archived_dir = output_dir / "archived"
    for directory in (active_dir, pending_dir, archived_dir):
        directory.mkdir(parents=True, exist_ok=True)

    for instinct in instincts:
        target_dir = active_dir if instinct["status"] == "active" else pending_dir
        output_path = target_dir / f"{instinct['id']}.json"
        output_path.write_text(json.dumps(instinct, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Infer project-scoped instincts from observation artifacts.")
    parser.add_argument("--observations", required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    observations = load_jsonl(Path(args.observations).expanduser().resolve())
    instincts = infer_instincts(observations)
    write_instincts(Path(args.output_dir).expanduser().resolve(), instincts)
    print(json.dumps({"instinct_count": len(instincts), "output_dir": str(Path(args.output_dir).expanduser().resolve())}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

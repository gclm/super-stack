#!/usr/bin/env python3
"""Render a retrospective JSON into a readable Markdown report."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def render_list_items(items: list[Any]) -> list[str]:
    lines: list[str] = []
    for item in items:
        if isinstance(item, dict):
            summary = item.get("summary") or item.get("lesson_id") or item.get("session_id") or json.dumps(item, ensure_ascii=False)
            lesson_id = item.get("lesson_id")
            if lesson_id and lesson_id != summary:
                summary = f"[{lesson_id}] {summary}"
            lines.append(f"- {summary}")
            evidence_refs = item.get("evidence_refs")
            if evidence_refs:
                lines.append(f"  - evidence refs: {', '.join(str(x) for x in as_list(evidence_refs))}")
        else:
            lines.append(f"- {item}")
    return lines


def render_markdown(payload: dict[str, Any]) -> str:
    lines = ["# Retrospective Report", ""]
    if payload.get("project_path"):
        lines.append(f"- project path: `{payload['project_path']}`")
    if payload.get("generated_at"):
        lines.append(f"- generated at: `{payload['generated_at']}`")
    if payload.get("evidence_strength"):
        lines.append(f"- evidence strength: `{payload['evidence_strength']}`")
    if payload.get("execution_shape"):
        lines.append(f"- execution shape: `{payload['execution_shape']}`")
    if payload.get("confidence") is not None:
        lines.append(f"- confidence: `{payload['confidence']}`")
    lines.append("")

    sections = [
        ("## Workflow Summary", [payload.get("workflow_summary")] if payload.get("workflow_summary") else []),
        ("## Records Reviewed", as_list(payload.get("records_reviewed"))),
        ("## Checked Sources", as_list(payload.get("checked_sources"))),
        ("## Patterns", as_list(payload.get("patterns"))),
        ("## Classifications", as_list(payload.get("classifications"))),
        ("## Generalized Lessons", as_list(payload.get("generalized_lessons"))),
        ("## Recommended Targets", as_list(payload.get("recommended_targets"))),
        ("## Evidence Gaps", as_list(payload.get("evidence_gaps"))),
        ("## Completion Gap Signals", as_list(payload.get("completion_gap_signals"))),
    ]

    for heading, items in sections:
        if not items:
            continue
        lines.append(heading)
        lines.append("")
        lines.extend(render_list_items(items))
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--retrospective-json", required=True, help="Path to retrospective JSON input")
    parser.add_argument("--output-md", required=True, help="Path to retrospective Markdown output")
    args = parser.parse_args()

    input_path = Path(args.retrospective_json).resolve()
    output_path = Path(args.output_md)
    if not output_path.is_absolute():
        output_path = Path.cwd() / output_path

    payload = load_json(input_path)
    if not isinstance(payload, dict):
        raise SystemExit("retrospective JSON must be an object")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"rendered retrospective markdown to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

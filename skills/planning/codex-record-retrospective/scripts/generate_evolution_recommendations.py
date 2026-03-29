#!/usr/bin/env python3
"""Generate table-driven evolution recommendations from a retrospective JSON."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

DEFAULT_MAP_PATH = Path(__file__).resolve().parent.parent / "references" / "lesson-target-map.json"
KEYWORD_TO_LESSON = {
    "module scope": "module_scope_ambiguity",
    "scope ambiguity": "module_scope_ambiguity",
    "多模块": "module_scope_ambiguity",
    "verify overclaim": "verify_overclaim",
    "过度乐观": "verify_overclaim",
    "route not explicit": "route_not_explicit",
    "路由不明确": "route_not_explicit",
    "path migration": "record_path_migration_gap",
    "历史路径": "record_path_migration_gap",
    "host limitation": "host_limitation_not_explained",
    "宿主限制": "host_limitation_not_explained",
    "skill entry bloat": "skill_entry_bloat",
    "技能入口膨胀": "skill_entry_bloat",
    "evidence gap": "evidence_gap_not_called_out",
    "证据缺口": "evidence_gap_not_called_out",
}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_lesson_id(text: str) -> str | None:
    lowered = text.lower()
    for keyword, lesson_id in KEYWORD_TO_LESSON.items():
        if keyword in lowered:
            return lesson_id

    slug = re.sub(r"[^a-z0-9]+", "_", lowered).strip("_")
    if slug in {"", "pattern", "issue", "lesson"}:
        return None
    return slug


def iter_candidate_items(data: Any) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    prioritized_fields = []
    if isinstance(data, dict) and data.get("generalized_lessons"):
        prioritized_fields.append("generalized_lessons")
    else:
        prioritized_fields.extend(["patterns", "classifications"])

    for field in prioritized_fields:
        value = data.get(field, []) if isinstance(data, dict) else []
        if isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    candidates.append(item)
                elif isinstance(item, str):
                    candidates.append({"summary": item, "source_field": field})
        elif isinstance(value, str):
            candidates.append({"summary": value, "source_field": field})
    return candidates


def build_recommendations(retrospective: dict[str, Any], mapping: dict[str, Any]) -> dict[str, Any]:
    recommendations = []
    seen: set[str] = set()

    for item in iter_candidate_items(retrospective):
        lesson_id = item.get("lesson_id")
        if not lesson_id:
            summary = item.get("summary") or item.get("pattern") or item.get("name") or ""
            lesson_id = normalize_lesson_id(str(summary))
        if not lesson_id or lesson_id in seen:
            continue
        seen.add(lesson_id)

        mapped = mapping.get(lesson_id)
        recommendation = {
            "lesson_id": lesson_id,
            "summary": item.get("summary") or item.get("pattern") or item.get("name") or lesson_id,
            "evidence_refs": item.get("evidence_refs", []),
            "source_field": item.get("source_field"),
            "matched_mapping": bool(mapped),
        }
        if mapped:
            recommendation.update(mapped)
        else:
            recommendation.update(
                {
                    "problem_type": item.get("problem_type", "unclassified"),
                    "target_files": [],
                    "change_kind": "manual-triage",
                    "default_confidence": 0.45,
                    "approval_level": "record-only",
                    "validation_hint": "先人工确认是否值得纳入共享规则",
                }
            )
        recommendations.append(recommendation)

    return {
        "project_path": retrospective.get("project_path"),
        "project_aliases": retrospective.get("project_aliases", []),
        "source_retrospective": retrospective.get("artifact_path") or retrospective.get("source_file"),
        "recommendations": recommendations,
        "unmapped_lessons": [r["lesson_id"] for r in recommendations if not r["matched_mapping"]],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = ["# Evolution Recommendations", ""]
    project_path = payload.get("project_path")
    if project_path:
        lines.append(f"- project path: `{project_path}`")
    source_retrospective = payload.get("source_retrospective")
    if source_retrospective:
        lines.append(f"- source retrospective: `{source_retrospective}`")
    lines.append("")

    for rec in payload.get("recommendations", []):
        lines.append(f"## {rec['lesson_id']}")
        lines.append("")
        lines.append(f"- summary: {rec['summary']}")
        lines.append(f"- matched mapping: {'yes' if rec['matched_mapping'] else 'no'}")
        lines.append(f"- problem type: {rec['problem_type']}")
        lines.append(f"- change kind: {rec['change_kind']}")
        lines.append(f"- approval level: {rec['approval_level']}")
        lines.append(f"- default confidence: {rec['default_confidence']}")
        target_files = rec.get("target_files", [])
        lines.append("- target files: " + (", ".join(f"`{p}`" for p in target_files) if target_files else "(manual triage)"))
        lines.append(f"- validation hint: {rec['validation_hint']}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--retrospective-json", required=True, help="Path to retrospective JSON input")
    parser.add_argument("--mapping-json", default=str(DEFAULT_MAP_PATH), help="Path to lesson-target mapping JSON")
    parser.add_argument("--output-json", help="Optional path to write recommendation JSON")
    parser.add_argument("--output-md", help="Optional path to write recommendation Markdown")
    args = parser.parse_args()

    retrospective_path = Path(args.retrospective_json).resolve()
    mapping_path = Path(args.mapping_json).resolve()

    retrospective = load_json(retrospective_path)
    if not isinstance(retrospective, dict):
        raise SystemExit("retrospective JSON must be an object")
    retrospective.setdefault("source_file", str(retrospective_path))

    mapping = load_json(mapping_path)
    if not isinstance(mapping, dict):
        raise SystemExit("mapping JSON must be an object")

    payload = build_recommendations(retrospective, mapping)

    text = json.dumps(payload, ensure_ascii=False, indent=2)
    if args.output_json:
        output_json = Path(args.output_json)
        output_json.parent.mkdir(parents=True, exist_ok=True)
        output_json.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)

    if args.output_md:
        output_md = Path(args.output_md)
        output_md.parent.mkdir(parents=True, exist_ok=True)
        output_md.write_text(render_markdown(payload), encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

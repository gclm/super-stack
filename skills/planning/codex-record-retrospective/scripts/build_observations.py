#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sqlite3
from pathlib import Path
from typing import Any

from slice_codex_session import build_slices, parse_items

SCHEMA_VERSION = "v1"
STAGE_NAMES = {"discuss", "brainstorm", "map-codebase", "plan", "build", "review", "verify", "qa", "ship", "debug", "tdd-execution", "browse"}
LINKABLE_EVENT_TYPES = {"tool_start", "tool_complete", "stage_transition", "backtrack", "verify_success", "verify_gap"}


def short(text: str, limit: int = 240) -> str:
    text = " ".join(str(text or "").split())
    if len(text) <= limit:
        return text
    return text[: limit - 3] + "..."


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


def extract_message_text(content: Any) -> str:
    if isinstance(content, str):
        return short(content)
    if not isinstance(content, list):
        return short(str(content or ""))
    parts: list[str] = []
    for item in content:
        if not isinstance(item, dict):
            continue
        if item.get("type") in {"input_text", "output_text", "summary_text"}:
            text = item.get("text")
            if text:
                parts.append(str(text))
    return short(" ".join(parts))


def build_slice_map(rows: list[dict[str, Any]]) -> dict[tuple[str, str], str]:
    parsed_items = parse_items(rows)
    slices = build_slices(parsed_items, gap_seconds=20 * 60)
    mapping: dict[tuple[str, str], str] = {}
    for session_slice in slices:
        for item in session_slice.items:
            mapping[(item.timestamp, item.summary)] = session_slice.slice_id
    return mapping


def infer_stage(text: str) -> str | None:
    lowered = text.lower()
    for stage in STAGE_NAMES:
        if re.search(rf"\b{re.escape(stage)}\b", lowered):
            return stage
    return None


def classify_message(role: str, summary: str) -> tuple[str, str | None, dict[str, Any]]:
    lowered = summary.lower()
    metadata: dict[str, Any] = {"role": role}

    if role == "user":
        correction_markers = ["不要", "别", "不要先", "不要再", "不要假设", "别先", "不用先", "不是这样", "我说的是"]
        if any(marker in summary for marker in correction_markers):
            return "user_correction", None, metadata

    verify_success_markers = ["已验证", "验证通过", "confirmed", "verified", "页面显示", "network 200", "dom 证据", "console 证据"]
    verify_gap_markers = ["未验证", "缺少证据", "没有证据", "still unverified", "无法验证"]

    if any(marker in summary for marker in verify_gap_markers):
        return "verify_gap", "verify", metadata
    if any(marker in lowered for marker in [marker.lower() for marker in verify_success_markers]):
        return "verify_success", "verify", metadata

    backtrack_match = re.search(r"(?:从|from)\s+([a-z-]+)\s+(?:回到|back to)\s+([a-z-]+)", lowered)
    if backtrack_match:
        from_stage = backtrack_match.group(1)
        to_stage = backtrack_match.group(2)
        metadata["from_stage"] = from_stage
        metadata["to_stage"] = to_stage
        return "backtrack", to_stage if to_stage in STAGE_NAMES else None, metadata

    stage = infer_stage(summary)
    if stage:
        metadata["to_stage"] = stage
        return "stage_transition", stage, metadata

    return "message", None, metadata


def link_user_corrections(observations: list[dict[str, Any]]) -> None:
    recent_by_slice: dict[str, list[dict[str, Any]]] = {}
    for observation in observations:
        slice_id = str(observation.get("slice_id") or "slice-001")
        recent = recent_by_slice.setdefault(slice_id, [])

        if observation.get("event_type") == "user_correction":
            for candidate in reversed(recent):
                candidate_event_type = str(candidate.get("event_type") or "")
                if candidate_event_type not in LINKABLE_EVENT_TYPES:
                    continue
                metadata = observation.setdefault("metadata", {})
                if not isinstance(metadata, dict):
                    continue
                metadata["corrects_event_type"] = candidate_event_type
                if candidate.get("tool"):
                    metadata["corrects_tool"] = candidate["tool"]
                candidate_stage = candidate.get("stage")
                if candidate_stage:
                    metadata["corrects_stage"] = candidate_stage
                break
            continue

        if observation.get("event_type") in LINKABLE_EVENT_TYPES:
            recent.append(observation)


def parse_events(rows: list[dict[str, Any]], project_path: Path) -> list[dict[str, Any]]:
    session_id = "unknown-session"
    observations: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str, str]] = set()
    slice_map = build_slice_map(rows)

    for row in rows:
        row_type = row.get("type")
        timestamp = str(row.get("timestamp", ""))
        payload = row.get("payload", {})
        if not isinstance(payload, dict):
            continue

        if row_type == "session_meta":
            session_id = str(payload.get("id") or session_id)
            continue

        event_type: str | None = None
        tool: str | None = None
        stage: str | None = None
        summary = ""
        metadata: dict[str, Any] = {"project_path": str(project_path)}

        if row_type == "response_item":
            payload_type = payload.get("type")
            if payload_type == "message":
                summary = extract_message_text(payload.get("content"))
                if summary:
                    role = str(payload.get("role") or "unknown")
                    event_type, stage, message_metadata = classify_message(role, summary)
                    metadata.update(message_metadata)
            elif payload_type == "function_call":
                tool = str(payload.get("name") or "unknown_tool")
                summary = short(f"{tool}: {payload.get('arguments', '')}")
                event_type = "tool_start"
            elif payload_type == "function_call_output":
                summary = short(str(payload.get("output") or payload.get("call_id") or "tool output"))
                event_type = "tool_complete"
        elif row_type == "event_msg":
            text = str(payload.get("text") or payload.get("type") or "")
            if text and text != "token_count":
                summary = short(text)
                event_type = "task_outcome"

        if not event_type or not summary:
            continue

        dedupe_key = (timestamp, event_type, tool or "", summary)
        if dedupe_key in seen:
            continue
        seen.add(dedupe_key)

        slice_id = slice_map.get((timestamp, summary), "slice-001")
        observations.append(
            {
                "schema_version": SCHEMA_VERSION,
                "timestamp": timestamp,
                "project_id": project_path.name,
                "project_name": project_path.name,
                "session_id": session_id,
                "slice_id": slice_id,
                "event_type": event_type,
                "stage": stage,
                "tool": tool,
                "summary": summary,
                "evidence_refs": [f"session:{session_id}", f"timestamp:{timestamp}"],
                "metadata": metadata,
            }
        )

    link_user_corrections(observations)
    return observations


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")


def refresh_index(index_db: Path, rows: list[dict[str, Any]]) -> None:
    index_db.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(index_db)
    try:
        conn.execute(
            """
            create table if not exists observations (
                observation_key text primary key,
                project_id text not null,
                session_id text not null,
                slice_id text not null,
                event_type text not null,
                timestamp text not null,
                summary text not null
            )
            """
        )
        for row in rows:
            observation_key = "|".join(
                [row["project_id"], row["session_id"], row["slice_id"], row["event_type"], row["timestamp"], row["summary"]]
            )
            conn.execute(
                """
                insert or ignore into observations (
                    observation_key, project_id, session_id, slice_id, event_type, timestamp, summary
                ) values (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    observation_key,
                    row["project_id"],
                    row["session_id"],
                    row["slice_id"],
                    row["event_type"],
                    row["timestamp"],
                    row["summary"],
                ),
            )
        conn.commit()
    finally:
        conn.close()


def main() -> int:
    parser = argparse.ArgumentParser(description="Build learning observations from Codex session records.")
    parser.add_argument("--session-file", required=True)
    parser.add_argument("--project-path", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--index-db")
    args = parser.parse_args()

    session_file = Path(args.session_file).expanduser().resolve()
    project_path = Path(args.project_path).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    rows = load_jsonl(session_file)
    observations = parse_events(rows, project_path)
    write_jsonl(output_path, observations)

    if args.index_db:
        refresh_index(Path(args.index_db).expanduser().resolve(), observations)

    print(json.dumps({"observation_count": len(observations), "output": str(output_path)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

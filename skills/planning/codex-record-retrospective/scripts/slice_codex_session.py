#!/usr/bin/env python3
"""Split a Codex session JSONL into task-like conversation slices."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BOUNDARY_HINTS = [
    "另外",
    "还有",
    "接下来",
    "现在",
    "然后",
    "顺便",
    "再看",
    "再帮我",
    "再处理",
    "另一个",
    "next",
    "also",
    "another",
    "then",
    "separately",
]
DEFAULT_GAP_SECONDS = 20 * 60


@dataclass
class SliceItem:
    timestamp: str
    role: str | None
    kind: str
    summary: str


@dataclass
class Slice:
    slice_id: str
    started_at: str
    ended_at: str
    dominant_cwd: str | None
    trigger: str
    summaries: list[str]
    items: list[SliceItem]


def parse_ts(value: str) -> datetime | None:
    if not value:
        return None
    try:
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None


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


def parse_items(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    parsed: list[dict[str, Any]] = []
    current_cwd: str | None = None
    for row in rows:
        row_type = row.get("type")
        timestamp = str(row.get("timestamp", ""))
        payload = row.get("payload", {})
        if not isinstance(payload, dict):
            continue

        if row_type == "turn_context":
            cwd = payload.get("cwd")
            if isinstance(cwd, str) and cwd.strip():
                current_cwd = cwd
            continue

        if row_type == "session_meta":
            cwd = payload.get("cwd")
            if isinstance(cwd, str) and cwd.strip() and current_cwd is None:
                current_cwd = cwd
            continue

        if row_type == "response_item":
            payload_type = payload.get("type")
            role = payload.get("role")
            if payload_type == "message":
                summary = extract_message_text(payload.get("content"))
                if summary:
                    parsed.append(
                        {
                            "timestamp": timestamp,
                            "kind": "message",
                            "role": role,
                            "summary": summary,
                            "cwd": current_cwd,
                        }
                    )
            elif payload_type in {"function_call", "custom_tool_call"}:
                name = payload.get("name") or "unknown_tool"
                parsed.append(
                    {
                        "timestamp": timestamp,
                        "kind": "tool_call",
                        "role": role,
                        "summary": short(f"{name} invoked"),
                        "cwd": current_cwd,
                    }
                )
            elif payload_type == "function_call_output":
                parsed.append(
                    {
                        "timestamp": timestamp,
                        "kind": "tool_output",
                        "role": role,
                        "summary": short(str(payload.get("call_id") or "tool output")),
                        "cwd": current_cwd,
                    }
                )
            continue

        if row_type == "event_msg":
            event_type = str(payload.get("type", "event"))
            if event_type != "token_count":
                parsed.append(
                    {
                        "timestamp": timestamp,
                        "kind": "event",
                        "role": None,
                        "summary": short(event_type),
                        "cwd": current_cwd,
                    }
                )
    return parsed


def starts_new_slice(prev: dict[str, Any] | None, current: dict[str, Any], gap_seconds: int) -> str | None:
    if current.get("role") != "user":
        return None
    if prev is None:
        return "first-user-message"

    prev_ts = parse_ts(str(prev.get("timestamp", "")))
    cur_ts = parse_ts(str(current.get("timestamp", "")))
    if prev_ts and cur_ts and (cur_ts - prev_ts).total_seconds() >= gap_seconds:
        return f"time-gap>={gap_seconds}s"

    prev_cwd = prev.get("cwd")
    cur_cwd = current.get("cwd")
    if prev_cwd and cur_cwd and prev_cwd != cur_cwd:
        return "cwd-changed"

    summary = str(current.get("summary", "")).lower()
    if any(hint.lower() in summary for hint in BOUNDARY_HINTS):
        return "user-boundary-hint"

    if prev.get("role") == "assistant" and len(summary) > 16:
        return "new-user-request-after-assistant"

    return None


def dominant_cwd(items: list[dict[str, Any]]) -> str | None:
    counts: dict[str, int] = {}
    for item in items:
        cwd = item.get("cwd")
        if isinstance(cwd, str) and cwd.strip():
            counts[cwd] = counts.get(cwd, 0) + 1
    if not counts:
        return None
    return sorted(counts.items(), key=lambda pair: (-pair[1], pair[0]))[0][0]


def build_slices(items: list[dict[str, Any]], gap_seconds: int) -> list[Slice]:
    slices: list[Slice] = []
    current: list[dict[str, Any]] = []
    trigger = ""
    prev: dict[str, Any] | None = None

    for item in items:
        boundary = starts_new_slice(prev, item, gap_seconds)
        if boundary and current:
            slice_index = len(slices) + 1
            slices.append(
                Slice(
                    slice_id=f"slice-{slice_index:03d}",
                    started_at=str(current[0].get("timestamp", "")),
                    ended_at=str(current[-1].get("timestamp", "")),
                    dominant_cwd=dominant_cwd(current),
                    trigger=trigger or "continued",
                    summaries=[short(str(entry.get("summary", "")), 120) for entry in current if entry.get("role") == "user"][:3],
                    items=[SliceItem(timestamp=str(entry.get("timestamp", "")), role=entry.get("role"), kind=str(entry.get("kind", "")), summary=str(entry.get("summary", ""))) for entry in current],
                )
            )
            current = []
        if boundary and not current:
            trigger = boundary
        current.append(item)
        prev = item

    if current:
        slice_index = len(slices) + 1
        slices.append(
            Slice(
                slice_id=f"slice-{slice_index:03d}",
                started_at=str(current[0].get("timestamp", "")),
                ended_at=str(current[-1].get("timestamp", "")),
                dominant_cwd=dominant_cwd(current),
                trigger=trigger or "continued",
                summaries=[short(str(entry.get("summary", "")), 120) for entry in current if entry.get("role") == "user"][:3],
                items=[SliceItem(timestamp=str(entry.get("timestamp", "")), role=entry.get("role"), kind=str(entry.get("kind", "")), summary=str(entry.get("summary", ""))) for entry in current],
            )
        )
    return slices


def find_session_file(codex_home: Path, session_id: str) -> Path | None:
    for base in (codex_home / "sessions", codex_home / "archived_sessions"):
        if not base.exists():
            continue
        for path in base.rglob("*.jsonl"):
            if session_id in path.name:
                return path
    return None


def render_markdown(session_file: Path, slices: list[Slice]) -> str:
    lines = ["# Codex Session Slices", "", f"- session file: `{session_file}`", f"- slice count: `{len(slices)}`", ""]
    for chunk in slices:
        lines.append(f"## {chunk.slice_id}")
        lines.append("")
        lines.append(f"- trigger: `{chunk.trigger}`")
        lines.append(f"- started at: `{chunk.started_at}`")
        lines.append(f"- ended at: `{chunk.ended_at}`")
        if chunk.dominant_cwd:
            lines.append(f"- dominant cwd: `{chunk.dominant_cwd}`")
        if chunk.summaries:
            lines.append("- user summaries:")
            for summary in chunk.summaries:
                lines.append(f"  - {summary}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session-file")
    parser.add_argument("--session-id")
    parser.add_argument("--codex-home", default=str(Path.home() / ".codex"))
    parser.add_argument("--gap-seconds", type=int, default=DEFAULT_GAP_SECONDS)
    parser.add_argument("--format", choices=["json", "markdown"], default="json")
    args = parser.parse_args()

    session_file: Path | None = None
    if args.session_file:
        session_file = Path(args.session_file).expanduser().resolve()
    elif args.session_id:
        session_file = find_session_file(Path(args.codex_home).expanduser().resolve(), args.session_id)

    if not session_file or not session_file.exists():
        raise SystemExit("session file not found")

    rows = load_jsonl(session_file)
    items = parse_items(rows)
    slices = build_slices(items, gap_seconds=max(args.gap_seconds, 60))

    if args.format == "markdown":
        print(render_markdown(session_file, slices))
    else:
        print(json.dumps({"session_file": str(session_file), "slice_count": len(slices), "slices": [asdict(chunk) for chunk in slices]}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

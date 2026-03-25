#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class TimelineItem:
    timestamp: str
    kind: str
    role: str | None
    summary: str
    raw_type: str


def short(text: str, limit: int = 280) -> str:
    text = " ".join(text.split())
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
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows


def extract_message_text(content: Any) -> str:
    if not isinstance(content, list):
        return short(str(content or ""))

    parts: list[str] = []
    for item in content:
        if not isinstance(item, dict):
            continue
        item_type = item.get("type")
        if item_type in {"input_text", "output_text", "summary_text"}:
            text = item.get("text", "")
            if text:
                parts.append(text)
    return short(" ".join(parts))


def summarize_tool_call(payload: dict[str, Any]) -> str:
    name = payload.get("name") or "unknown_tool"
    if payload.get("type") == "custom_tool_call":
        input_text = str(payload.get("input", ""))
        return short(f"{name}: {input_text}")
    arguments = str(payload.get("arguments", ""))
    return short(f"{name}: {arguments}")


def summarize_tool_output(payload: dict[str, Any]) -> str:
    call_id = payload.get("call_id", "unknown_call")
    output = str(payload.get("output", ""))
    return short(f"{call_id}: {output}")


def summarize_event(payload: dict[str, Any]) -> str | None:
    event_type = payload.get("type")
    if event_type in {"task_started", "task_complete"}:
        return short(str(payload.get("last_agent_message") or event_type))
    if event_type == "token_count":
        return None
    text = str(payload.get("text", ""))
    if text.strip():
        return short(text)
    return short(event_type or "event")


def parse_rows(rows: list[dict[str, Any]], include_system: bool) -> tuple[dict[str, Any] | None, list[TimelineItem]]:
    session_meta: dict[str, Any] | None = None
    items: list[TimelineItem] = []

    for row in rows:
        row_type = row.get("type")
        timestamp = str(row.get("timestamp", ""))
        payload = row.get("payload", {})
        if not isinstance(payload, dict):
            continue

        if row_type == "session_meta":
            session_meta = payload
            continue

        if row_type == "response_item":
            payload_type = payload.get("type")
            role = payload.get("role")
            if payload_type == "message":
                if role in {"user", "assistant"}:
                    text = extract_message_text(payload.get("content"))
                    if text:
                        items.append(
                            TimelineItem(
                                timestamp=timestamp,
                                kind="message",
                                role=role,
                                summary=text,
                                raw_type=row_type,
                            )
                        )
                elif include_system and role in {"system", "developer"}:
                    text = extract_message_text(payload.get("content"))
                    if text:
                        items.append(
                            TimelineItem(
                                timestamp=timestamp,
                                kind="context",
                                role=role,
                                summary=text,
                                raw_type=row_type,
                            )
                        )
            elif payload_type in {"function_call", "custom_tool_call"}:
                items.append(
                    TimelineItem(
                        timestamp=timestamp,
                        kind="tool_call",
                        role=role,
                        summary=summarize_tool_call(payload),
                        raw_type=row_type,
                    )
                )
            elif payload_type == "function_call_output":
                items.append(
                    TimelineItem(
                        timestamp=timestamp,
                        kind="tool_output",
                        role=role,
                        summary=summarize_tool_output(payload),
                        raw_type=row_type,
                    )
                )
            continue

        if row_type == "event_msg":
            summary = summarize_event(payload)
            if summary:
                items.append(
                    TimelineItem(
                        timestamp=timestamp,
                        kind="event",
                        role=None,
                        summary=summary,
                        raw_type=row_type,
                    )
                )
            continue

        if include_system and row_type == "turn_context":
            cwd = payload.get("cwd")
            summary = payload.get("summary")
            text = f"cwd={cwd}"
            if summary and summary != "none":
                text += f"; summary={summary}"
            items.append(
                TimelineItem(
                    timestamp=timestamp,
                    kind="turn_context",
                    role=None,
                    summary=short(text),
                    raw_type=row_type,
                )
            )

    return session_meta, items


def find_session_file(codex_home: Path, session_id: str) -> Path | None:
    for base in (codex_home / "sessions", codex_home / "archived_sessions"):
        if not base.exists():
            continue
        for path in base.rglob("*.jsonl"):
            if session_id in path.name:
                return path
    return None


def render_markdown(session_meta: dict[str, Any] | None, session_file: Path, items: list[TimelineItem]) -> str:
    lines = ["# Codex Session Timeline", ""]
    lines.append(f"- Session file: `{session_file}`")
    if session_meta:
        lines.append(f"- Session ID: `{session_meta.get('id', 'unknown')}`")
        lines.append(f"- CWD: `{session_meta.get('cwd', '')}`")
        lines.append(f"- Started at: `{session_meta.get('timestamp', '')}`")
        lines.append(f"- Source: `{session_meta.get('source', '')}` / `{session_meta.get('originator', '')}`")
    lines.append("")
    lines.append("## Timeline")
    if not items:
        lines.append("- No timeline items extracted.")
        lines.append("")
        return "\n".join(lines)

    for item in items:
        role = f" / {item.role}" if item.role else ""
        lines.append(f"- `{item.timestamp}` [{item.kind}{role}] {item.summary}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract a readable timeline from a Codex session JSONL file.")
    parser.add_argument("--session-file")
    parser.add_argument("--session-id")
    parser.add_argument("--codex-home", default=str(Path.home() / ".codex"))
    parser.add_argument("--max-items", type=int, default=80)
    parser.add_argument("--include-system", action="store_true")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    args = parser.parse_args()

    codex_home = Path(args.codex_home).expanduser().resolve()
    session_file: Path | None = None
    if args.session_file:
        session_file = Path(args.session_file).expanduser().resolve()
    elif args.session_id:
        session_file = find_session_file(codex_home, args.session_id)

    if not session_file or not session_file.exists():
        raise SystemExit("session file not found")

    rows = load_jsonl(session_file)
    session_meta, items = parse_rows(rows, include_system=args.include_system)
    report = {
        "session_file": str(session_file),
        "session_meta": session_meta,
        "timeline": [
            {
                "timestamp": item.timestamp,
                "kind": item.kind,
                "role": item.role,
                "summary": item.summary,
                "raw_type": item.raw_type,
            }
            for item in items[: max(args.max_items, 1)]
        ],
    }

    if args.format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(render_markdown(session_meta, session_file, items[: max(args.max_items, 1)]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

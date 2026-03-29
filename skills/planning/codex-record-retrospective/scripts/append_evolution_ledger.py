#!/usr/bin/env python3
"""Append a structured entry to the evolution ledger JSONL."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_LEDGER_PATH = Path("artifacts/evolution/evolution-ledger.jsonl")
VALID_STATUSES = {"record-only", "patch-proposed", "apply-approved", "accepted", "rejected"}


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def ensure_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def derive_entries(payload: dict[str, Any]) -> list[dict[str, Any]]:
    timestamp = payload.get("timestamp") or utc_now_iso()
    project_path = payload.get("project_path")
    recommendation_status = payload.get("recommendation_status") or "record-only"
    if recommendation_status not in VALID_STATUSES:
        raise SystemExit(f"invalid recommendation_status: {recommendation_status}")

    entries: list[dict[str, Any]] = []
    recommendations = payload.get("recommendations")
    if isinstance(recommendations, list) and recommendations:
        for rec in recommendations:
            if not isinstance(rec, dict):
                continue
            entries.append(
                {
                    "timestamp": timestamp,
                    "project_path": project_path,
                    "lesson_id": rec.get("lesson_id"),
                    "evidence_strength": rec.get("evidence_strength") or payload.get("evidence_strength"),
                    "recommendation_status": rec.get("approval_level") or recommendation_status,
                    "accepted_targets": ensure_list(rec.get("accepted_targets") or rec.get("target_files")),
                    "rejected_reason": rec.get("rejected_reason") or payload.get("rejected_reason"),
                    "applied_commit_or_note": rec.get("applied_commit_or_note") or payload.get("applied_commit_or_note"),
                    "source_retrospective": payload.get("source_retrospective") or payload.get("source_file"),
                    "source_recommendation": payload.get("source_recommendation"),
                }
            )
    else:
        entries.append(
            {
                "timestamp": timestamp,
                "project_path": project_path,
                "lesson_id": payload.get("lesson_id"),
                "evidence_strength": payload.get("evidence_strength"),
                "recommendation_status": recommendation_status,
                "accepted_targets": ensure_list(payload.get("accepted_targets")),
                "rejected_reason": payload.get("rejected_reason"),
                "applied_commit_or_note": payload.get("applied_commit_or_note"),
                "source_retrospective": payload.get("source_retrospective") or payload.get("source_file"),
                "source_recommendation": payload.get("source_recommendation"),
            }
        )

    filtered = [entry for entry in entries if entry.get("lesson_id")]
    if not filtered:
        raise SystemExit("no ledger entries derived from input")
    return filtered


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-json", required=True, help="Recommendation or retrospective JSON input")
    parser.add_argument("--ledger-path", default=str(DEFAULT_LEDGER_PATH), help="Ledger JSONL path")
    args = parser.parse_args()

    input_path = Path(args.input_json).resolve()
    ledger_path = Path(args.ledger_path)
    if not ledger_path.is_absolute():
        ledger_path = Path.cwd() / ledger_path

    payload = load_json(input_path)
    if not isinstance(payload, dict):
        raise SystemExit("input JSON must be an object")

    entries = derive_entries(payload)
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    with ledger_path.open("a", encoding="utf-8") as handle:
        for entry in entries:
            handle.write(json.dumps(entry, ensure_ascii=False) + "\n")

    print(f"appended {len(entries)} ledger entr{'y' if len(entries) == 1 else 'ies'} to {ledger_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

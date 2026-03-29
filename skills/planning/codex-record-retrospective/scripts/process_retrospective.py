#!/usr/bin/env python3
"""Process a retrospective JSON into recommendation artifacts and ledger entries."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
RECOMMEND_SCRIPT = SCRIPT_DIR / "generate_evolution_recommendations.py"
LEDGER_SCRIPT = SCRIPT_DIR / "append_evolution_ledger.py"
RENDER_SCRIPT = SCRIPT_DIR / "render_retrospective_report.py"
DEFAULT_LEDGER_PATH = Path("artifacts/evolution/evolution-ledger.jsonl")


def utc_date_prefix() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def slugify(value: str) -> str:
    import re

    slug = re.sub(r"[^a-zA-Z0-9]+", "-", value.strip()).strip("-").lower()
    return slug or "retrospective"


def infer_topic(payload: dict[str, Any], input_path: Path) -> str:
    for key in ("topic", "project_name", "lesson_id"):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return slugify(value)
    project_path = payload.get("project_path")
    if isinstance(project_path, str) and project_path.strip():
        return slugify(Path(project_path).name)
    return slugify(input_path.stem)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--retrospective-json", required=True, help="Path to retrospective JSON input")
    parser.add_argument("--mapping-json", help="Optional lesson-target mapping JSON")
    parser.add_argument("--retrospective-md", help="Optional retrospective Markdown output path")
    parser.add_argument("--output-json", help="Optional recommendation JSON output path")
    parser.add_argument("--output-md", help="Optional recommendation Markdown output path")
    parser.add_argument("--ledger-path", default=str(DEFAULT_LEDGER_PATH), help="Ledger JSONL path")
    parser.add_argument("--skip-ledger", action="store_true", help="Do not append ledger entries")
    args = parser.parse_args()

    retrospective_path = Path(args.retrospective_json).resolve()
    retrospective = load_json(retrospective_path)
    if not isinstance(retrospective, dict):
        raise SystemExit("retrospective JSON must be an object")

    topic = infer_topic(retrospective, retrospective_path)
    date_prefix = utc_date_prefix()

    output_json = Path(args.output_json) if args.output_json else Path(f"artifacts/evolution/{date_prefix}-{topic}-recommendations.json")
    output_md = Path(args.output_md) if args.output_md else Path(f"artifacts/evolution/{date_prefix}-{topic}-recommendations.md")
    retrospective_md = Path(args.retrospective_md) if args.retrospective_md else Path(f"artifacts/retrospectives/{date_prefix}-{topic}.md")
    ledger_path = Path(args.ledger_path)

    if not output_json.is_absolute():
        output_json = Path.cwd() / output_json
    if not output_md.is_absolute():
        output_md = Path.cwd() / output_md
    if not retrospective_md.is_absolute():
        retrospective_md = Path.cwd() / retrospective_md
    if not ledger_path.is_absolute():
        ledger_path = Path.cwd() / ledger_path

    render = subprocess.run(
        [
            sys.executable,
            str(RENDER_SCRIPT),
            "--retrospective-json",
            str(retrospective_path),
            "--output-md",
            str(retrospective_md),
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    if render.returncode != 0:
        sys.stderr.write(render.stderr or render.stdout)
        return render.returncode

    cmd = [
        sys.executable,
        str(RECOMMEND_SCRIPT),
        "--retrospective-json",
        str(retrospective_path),
        "--output-json",
        str(output_json),
        "--output-md",
        str(output_md),
    ]
    if args.mapping_json:
        cmd.extend(["--mapping-json", args.mapping_json])

    recommend = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if recommend.returncode != 0:
        sys.stderr.write(recommend.stderr or recommend.stdout)
        return recommend.returncode

    ledger_result = None
    if not args.skip_ledger:
        ledger_cmd = [
            sys.executable,
            str(LEDGER_SCRIPT),
            "--input-json",
            str(output_json),
            "--ledger-path",
            str(ledger_path),
        ]
        ledger_result = subprocess.run(ledger_cmd, text=True, capture_output=True, check=False)
        if ledger_result.returncode != 0:
            sys.stderr.write(ledger_result.stderr or ledger_result.stdout)
            return ledger_result.returncode

    summary = {
        "retrospective_json": str(retrospective_path),
        "retrospective_md": str(retrospective_md),
        "recommendation_json": str(output_json),
        "recommendation_md": str(output_md),
        "ledger_path": None if args.skip_ledger else str(ledger_path),
        "topic": topic,
    }
    if ledger_result and ledger_result.stdout.strip():
        summary["ledger_result"] = ledger_result.stdout.strip()

    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

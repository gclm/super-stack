#!/usr/bin/env python3

import json
import os
import sys
from pathlib import Path


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    event_name = str(payload.get("hook_event_name", "")).lower()
    cwd = payload.get("cwd") or os.getcwd()
    workdir = Path(cwd)
    planning_dir = workdir / ".planning"
    state_file = planning_dir / "STATE.md"
    hook_log = planning_dir / ".super-stack-codex-hooks.log"

    if planning_dir.exists():
        with hook_log.open("a", encoding="utf-8") as handle:
            handle.write(f"{event_name}\n")

    if event_name == "sessionstart" and state_file.exists():
        lines = state_file.read_text(encoding="utf-8").splitlines()[:20]
        additional_context = "[super-stack] resuming from .planning/STATE.md\n" + "\n".join(lines)
        print(json.dumps({"additionalContext": additional_context}, ensure_ascii=False))
        return 0

    if event_name == "stop" and state_file.exists():
        print(
            json.dumps(
                {"additionalContext": "[super-stack] remember to leave STATE.md current"},
                ensure_ascii=False,
            )
        )
        return 0

    print("{}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

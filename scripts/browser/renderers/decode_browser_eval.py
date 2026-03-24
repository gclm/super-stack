#!/usr/bin/env python3

import json
import pathlib
import sys


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: decode_browser_eval.py <input.raw> <output.json>")

    raw_path = pathlib.Path(sys.argv[1])
    output_path = pathlib.Path(sys.argv[2])

    raw = raw_path.read_text(encoding="utf-8").strip()
    decoded = json.loads(raw)
    if not isinstance(decoded, str):
        raise SystemExit(f"expected eval output to decode to string, got {type(decoded).__name__}")

    payload = json.loads(decoded)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

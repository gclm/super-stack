#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from managed_config_lib import (
    get_block,
    get_commands,
    get_config_files,
    get_contains,
    get_managed_files,
    get_markers,
    get_registered_entries,
    get_target_file,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", required=True)
    parser.add_argument("--runtime-root", default="")
    parser.add_argument("--home", default=str(Path.home()))
    parser.add_argument("--field", required=True)
    args = parser.parse_args()

    get_block(args.block)

    if args.field == "config_files":
        for item in get_config_files(args.block, runtime_root=args.runtime_root, home=args.home):
            print(item)
        return 0

    if args.field == "commands":
        for item in get_commands(args.block, runtime_root=args.runtime_root, home=args.home):
            print(item)
        return 0

    if args.field == "managed_files":
        for item in get_managed_files(args.block, runtime_root=args.runtime_root, home=args.home):
            print(item)
        return 0

    if args.field == "contains":
        for item in get_contains(args.block, runtime_root=args.runtime_root, home=args.home):
            print(item)
        return 0

    if args.field == "registered_entries":
        for item in get_registered_entries(args.block, runtime_root=args.runtime_root, home=args.home):
            print(item)
        return 0

    if args.field == "markers":
        for item in get_markers(args.block, runtime_root=args.runtime_root, home=args.home):
            print(item)
        return 0

    if args.field == "target_file":
        target = get_target_file(args.block, runtime_root=args.runtime_root, home=args.home)
        if target:
            print(target)
        return 0

    raise SystemExit(f"unsupported field: {args.field}")


if __name__ == "__main__":
    raise SystemExit(main())

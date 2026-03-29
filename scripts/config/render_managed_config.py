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
    render_claude_hooks,
    render_claude_mcp,
    render_codex_agents,
    render_codex_mcp,
    render_codex_hooks,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block", required=True)
    parser.add_argument("--runtime-root", default="")
    parser.add_argument("--config-file", default="")
    args = parser.parse_args()

    get_block(args.block)

    if args.block == "codex_agents":
        print(render_codex_agents(args.block))
        return 0

    if args.block == "codex_hooks":
        config_text = ""
        if args.config_file:
            config_text = Path(args.config_file).read_text(encoding="utf-8")
        print(render_codex_hooks(args.block, args.runtime_root, config_text))
        return 0

    if args.block == "codex_mcp":
        print(render_codex_mcp(args.block))
        return 0

    if args.block == "claude_hooks":
        print(render_claude_hooks(args.block, args.runtime_root), end="")
        return 0

    if args.block == "claude_mcp":
        print(render_claude_mcp(args.block), end="")
        return 0

    raise SystemExit(f"unsupported block: {args.block}")


if __name__ == "__main__":
    raise SystemExit(main())

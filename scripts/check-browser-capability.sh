#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

python3 - <<'PY'
import json
import os
from pathlib import Path

home = Path.home()

candidate_bins = []
if os.environ.get("SUPER_STACK_BROWSE_BIN"):
    candidate_bins.append(("override", Path(os.environ["SUPER_STACK_BROWSE_BIN"]).expanduser()))

default_candidates = [
    ("super-stack-browser", home / ".claude-stack" / "bin" / "super-stack-browser"),
]

candidate_bins.extend(default_candidates)

available_local = [
    (name, candidate)
    for name, candidate in candidate_bins
    if candidate.is_file() and os.access(candidate, os.X_OK)
]

if available_local:
    print("ACTIVE_LOCAL")
    primary_name, primary_path = available_local[0]
    print(f"provider=local-binary:{primary_name}:{primary_path}")
    if len(available_local) > 1:
        fallbacks = ",".join(f"{name}:{path}" for name, path in available_local[1:])
        print(f"fallbacks={fallbacks}")
    raise SystemExit(0)

settings_path = home / ".claude" / "settings.json"
installed_path = home / ".claude" / "plugins" / "installed_plugins.json"

enabled = set()
installed = set()
mcp_names = set()

if settings_path.exists():
    try:
        settings = json.loads(settings_path.read_text())
    except Exception:
        settings = {}

    enabled_plugins = settings.get("enabledPlugins", {})
    if isinstance(enabled_plugins, dict):
        enabled = {name for name, value in enabled_plugins.items() if value}

    mcp_servers = settings.get("mcpServers", {})
    if isinstance(mcp_servers, dict):
        mcp_names = set(mcp_servers.keys())

if installed_path.exists():
    try:
        installed_data = json.loads(installed_path.read_text())
    except Exception:
        installed_data = {}

    plugins = installed_data.get("plugins", {})
    if isinstance(plugins, dict):
        installed = set(plugins.keys())

active_browser_plugins = sorted(
    name for name in enabled if any(token in name.lower() for token in ("browser", "playwright", "chrome"))
)
installed_browser_plugins = sorted(
    name for name in installed if any(token in name.lower() for token in ("browser", "playwright", "chrome"))
)
active_mcp = sorted(
    name for name in mcp_names if any(token in name.lower() for token in ("browser", "playwright", "chrome"))
)

if active_mcp:
    print("ACTIVE_MCP")
    print("mcps=" + ",".join(active_mcp))
elif active_browser_plugins:
    print("ACTIVE_PLUGIN")
    print("plugins=" + ",".join(active_browser_plugins))
elif installed_browser_plugins:
    print("INSTALLED_ONLY")
    print("plugins=" + ",".join(installed_browser_plugins))
else:
    print("MISSING")
PY

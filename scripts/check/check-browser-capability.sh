#!/usr/bin/env bash

set -euo pipefail

python3 - <<'PY'
import json
import os
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib

home = Path.home()

candidate_bins = []
if os.environ.get("SUPER_STACK_BROWSE_BIN"):
    candidate_bins.append(("override", Path(os.environ["SUPER_STACK_BROWSE_BIN"]).expanduser()))

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

browser_tokens = ("browser", "playwright", "chrome", "devtools")
active_mcp = []
enabled_plugins = []
installed_plugins = []

codex_path = home / ".codex" / "config.toml"
if codex_path.exists():
    try:
        codex_data = tomllib.loads(codex_path.read_text(encoding="utf-8"))
    except Exception:
        codex_data = {}

    mcp_servers = codex_data.get("mcp_servers", {})
    if isinstance(mcp_servers, dict):
        for name, config in mcp_servers.items():
            if not any(token in name.lower() for token in browser_tokens):
                continue
            if isinstance(config, dict) and config.get("enabled", True):
                active_mcp.append(f"codex:{name}")

settings_path = home / ".claude" / "settings.json"
installed_path = home / ".claude" / "plugins" / "installed_plugins.json"

if settings_path.exists():
    try:
        settings = json.loads(settings_path.read_text(encoding="utf-8"))
    except Exception:
        settings = {}

    claude_mcp_servers = settings.get("mcpServers", {})
    if isinstance(claude_mcp_servers, dict):
        for name in claude_mcp_servers.keys():
            if any(token in name.lower() for token in browser_tokens):
                active_mcp.append(f"claude:{name}")

    enabled = settings.get("enabledPlugins", {})
    if isinstance(enabled, dict):
        enabled_plugins = sorted(
            name for name, value in enabled.items() if value and any(token in name.lower() for token in browser_tokens)
        )

if installed_path.exists():
    try:
        installed_data = json.loads(installed_path.read_text(encoding="utf-8"))
    except Exception:
        installed_data = {}

    plugins = installed_data.get("plugins", {})
    if isinstance(plugins, dict):
        installed_plugins = sorted(
            name for name in plugins.keys() if any(token in name.lower() for token in browser_tokens)
        )

active_mcp = sorted(set(active_mcp))

if active_mcp:
    print("ACTIVE_MCP")
    print("mcps=" + ",".join(active_mcp))
elif enabled_plugins:
    print("ACTIVE_PLUGIN")
    print("plugins=" + ",".join(enabled_plugins))
elif installed_plugins:
    print("INSTALLED_ONLY")
    print("plugins=" + ",".join(installed_plugins))
else:
    print("MISSING")
PY

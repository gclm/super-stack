#!/usr/bin/env python3

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = REPO_ROOT / "config" / "managed-config.json"


def load_manifest() -> dict[str, Any]:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def get_server_catalog() -> dict[str, dict[str, Any]]:
    manifest = load_manifest()
    catalog = manifest.get("server_defs", {})
    if not isinstance(catalog, dict):
        raise SystemExit("managed-config.json must define a top-level server_defs object")
    return catalog


def render_templates(value: Any, **kwargs: str) -> Any:
    if isinstance(value, str):
        return value.format(**kwargs)
    if isinstance(value, list):
        return [render_templates(item, **kwargs) for item in value]
    if isinstance(value, dict):
        rendered = {key: render_templates(item, **kwargs) for key, item in value.items()}
        if "command_template" in rendered and "command" not in rendered:
            rendered["command"] = rendered.pop("command_template")
        return rendered
    return value


def normalize_mcp_server_entry(entry: Any, catalog: dict[str, dict[str, Any]]) -> dict[str, Any]:
    if isinstance(entry, str):
        server_id = entry
        overrides: dict[str, Any] = {}
    elif isinstance(entry, dict):
        server_id = entry.get("id", "")
        if not server_id:
            raise SystemExit("MCP server override entries must include a non-empty id")
        overrides = {key: value for key, value in entry.items() if key != "id"}
    else:
        raise SystemExit(f"unsupported MCP server entry type: {type(entry).__name__}")

    definition = catalog.get(server_id)
    if not isinstance(definition, dict):
        raise SystemExit(f"unknown MCP server definition: {server_id}")

    merged = dict(definition)
    merged.update(overrides)
    merged["id"] = server_id
    return merged


def resolve_mcp_server_command(server: dict[str, Any]) -> str:
    env_name = server.get("command_env", "")
    if env_name:
        command = os.environ.get(env_name, "")
        if command:
            return command

    command_name = server.get("command_name", "")
    if command_name:
        return shutil.which(command_name) or ""

    return ""


def resolve_mcp_servers_for_block(block_name: str, runtime_root: str = "", home: str = "") -> list[dict[str, Any]]:
    content = get_rendered_content(block_name, runtime_root=runtime_root, home=home)
    servers = content.get("servers", [])
    if not isinstance(servers, list):
        raise SystemExit(f"{block_name} content must define a servers list")

    catalog = get_server_catalog()
    resolved: list[dict[str, Any]] = []
    for entry in servers:
        server = normalize_mcp_server_entry(entry, catalog)
        command = resolve_mcp_server_command(server)
        if not command:
            continue

        resolved.append(
            {
                "id": server["id"],
                "command": command,
                "args": list(server.get("args", [])),
                "enabled": bool(server.get("enabled", True)),
            }
        )
    return resolved


def toml_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def json_string_escape(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)[1:-1]


def get_block(block_name: str) -> dict[str, Any]:
    manifest = load_manifest()
    try:
        return manifest["blocks"][block_name]
    except KeyError as exc:
        raise SystemExit(f"unknown block: {block_name}") from exc


def get_rendered_content(block_name: str, runtime_root: str = "", home: str = "") -> dict[str, Any]:
    block = get_block(block_name)
    return render_templates(
        block.get("content", {}),
        runtime_root=runtime_root,
        home=home,
    )


def get_verify(block_name: str, runtime_root: str = "", home: str = "") -> dict[str, Any]:
    block = get_block(block_name)
    return render_templates(block.get("verify", {}), runtime_root=runtime_root, home=home)


def get_target_file(block_name: str, runtime_root: str = "", home: str = "") -> str:
    block = get_block(block_name)
    target = block.get("target_file_template")
    if not target:
        return ""
    return render_templates(target, runtime_root=runtime_root, home=home)


def get_managed_files(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    block = get_block(block_name)
    return render_templates(
        block.get("managed_files", []),
        runtime_root=runtime_root,
        home=home,
    )


def get_markers(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    block = get_block(block_name)
    verify = get_verify(block_name, runtime_root=runtime_root, home=home)
    markers = verify.get("markers")
    if markers is None:
        markers = [block.get("begin_marker", ""), block.get("end_marker", "")]
    return [item for item in markers if item]


def get_contains(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    verify = get_verify(block_name, runtime_root=runtime_root, home=home)
    contains = list(verify.get("contains", []))
    if verify.get("include_resolved_server_markers"):
        resolved_servers = resolve_mcp_servers_for_block(block_name, runtime_root=runtime_root, home=home)
        if block_name == "codex_mcp":
            contains.extend(f"[mcp_servers.{server['id']}]" for server in resolved_servers)
        elif block_name == "claude_mcp":
            contains.extend(json.dumps(server["id"], ensure_ascii=False) for server in resolved_servers)
        else:
            raise SystemExit(f"include_resolved_server_markers is unsupported for block: {block_name}")
    return contains


def get_registered_entries(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    verify = get_verify(block_name, runtime_root=runtime_root, home=home)
    return list(verify.get("registered_entries", []))


def get_config_files(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    content = get_rendered_content(block_name, runtime_root=runtime_root, home=home)
    return [agent["config_file"] for agent in content.get("agent_defs", [])]


def get_commands(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    content = get_rendered_content(block_name, runtime_root=runtime_root, home=home)
    if block_name == "codex_hooks":
        return [toml_escape(hook["command"]) for hook in content.get("hooks", [])]
    if block_name == "claude_hooks":
        commands: list[str] = []
        for entries in content.get("hooks", {}).values():
            for entry in entries:
                for hook in entry.get("hooks", []):
                    command = hook.get("command")
                    if command:
                        commands.append(json_string_escape(command))
        return commands
    raise SystemExit(f"commands field is unsupported for block: {block_name}")


def render_codex_agents(block_name: str) -> str:
    content = get_rendered_content(block_name)
    lines = [
        "[features]",
        f'multi_agent = {str(content["features"]["multi_agent"]).lower()}',
        "",
        "[agents]",
        f'max_threads = {content["agents"]["max_threads"]}',
        f'max_depth = {content["agents"]["max_depth"]}',
    ]
    for agent in content["agent_defs"]:
        lines.extend(
            [
                "",
                f'[agents.{agent["id"]}]',
                f'description = "{agent["description"]}"',
                f'config_file = "{agent["config_file"]}"',
            ]
        )
    return "\n".join(lines)


def render_codex_hooks(block_name: str, runtime_root: str, config_text: str) -> str:
    content = get_rendered_content(block_name, runtime_root=runtime_root)
    lines = []
    if content.get("include_hooks_table") and "[hooks]" not in config_text.splitlines():
        lines.extend(["[hooks]", ""])
    for hook in content["hooks"]:
        lines.extend(
            [
                f'[[hooks.{hook["event"]}]]',
                f'command = "{toml_escape(hook["command"])}"',
                "",
            ]
        )
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines)


def render_codex_mcp(block_name: str) -> str:
    resolved = resolve_mcp_servers_for_block(block_name)
    lines: list[str] = []
    for index, server in enumerate(resolved):
        if index > 0:
            lines.append("")
        args = ", ".join(f'"{toml_escape(arg)}"' for arg in server.get("args", []))
        lines.extend(
            [
                f'[mcp_servers.{server["id"]}]',
                f'command = "{toml_escape(server["command"])}"',
                f"args = [{args}]",
                f'enabled = {str(server["enabled"]).lower()}',
            ]
        )
    return "\n".join(lines)


def render_claude_hooks(block_name: str, runtime_root: str) -> str:
    content = get_rendered_content(block_name, runtime_root=runtime_root)
    return json.dumps(content, ensure_ascii=False, indent=2) + "\n"


def render_claude_mcp(block_name: str) -> str:
    resolved = resolve_mcp_servers_for_block(block_name)
    rendered = {
        "mcpServers": {
            server["id"]: {
                "command": server["command"],
                "args": server["args"],
                "enabled": server["enabled"],
            }
            for server in resolved
        }
    }
    return json.dumps(rendered, ensure_ascii=False, indent=2) + "\n"

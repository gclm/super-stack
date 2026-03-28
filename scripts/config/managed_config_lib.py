#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = REPO_ROOT / "config" / "managed-config.json"


def load_manifest() -> dict[str, Any]:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


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
    return render_templates(block.get("content", {}), runtime_root=runtime_root, home=home)


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
    return render_templates(block.get("managed_files", []), runtime_root=runtime_root, home=home)


def get_markers(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    block = get_block(block_name)
    verify = get_verify(block_name, runtime_root=runtime_root, home=home)
    markers = verify.get("markers")
    if markers is None:
        markers = [block.get("begin_marker", ""), block.get("end_marker", "")]
    return [item for item in markers if item]


def get_contains(block_name: str, runtime_root: str = "", home: str = "") -> list[str]:
    verify = get_verify(block_name, runtime_root=runtime_root, home=home)
    return list(verify.get("contains", []))


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


def render_claude_hooks(block_name: str, runtime_root: str) -> str:
    content = get_rendered_content(block_name, runtime_root=runtime_root)
    return json.dumps(content, ensure_ascii=False, indent=2) + "\n"

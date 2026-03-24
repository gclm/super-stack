#!/usr/bin/env python3

import argparse
import json
import os
import re
import shlex
import sys
from pathlib import Path

READONLY_COMMANDS = {
    "ack",
    "ag",
    "cat",
    "cmp",
    "date",
    "df",
    "diff",
    "dir",
    "du",
    "echo",
    "egrep",
    "env",
    "fgrep",
    "file",
    "find",
    "grep",
    "head",
    "hostname",
    "htop",
    "id",
    "ifconfig",
    "ip",
    "jq",
    "less",
    "ll",
    "ls",
    "lsof",
    "man",
    "more",
    "netstat",
    "open",
    "ping",
    "printenv",
    "ps",
    "pwd",
    "rg",
    "ss",
    "stat",
    "tail",
    "top",
    "type",
    "uname",
    "uptime",
    "wc",
    "whereis",
    "which",
    "whoami",
    "yq",
}

READONLY_GIT_SUBCOMMANDS = {
    "blame",
    "branch",
    "cat-file",
    "config",
    "diff",
    "fetch",
    "help",
    "log",
    "ls-files",
    "ls-tree",
    "reflog",
    "remote",
    "rev-list",
    "rev-parse",
    "show",
    "status",
    "tag",
    "version",
}

READONLY_NPM_SUBCOMMANDS = {"audit", "config", "help", "info", "list", "ls", "outdated", "search", "show", "view"}
READONLY_PNPM_SUBCOMMANDS = {"audit", "config", "help", "info", "list", "ls", "outdated", "root", "store", "why"}
READONLY_YARN_SUBCOMMANDS = {"config", "help", "info", "list", "outdated", "why"}
READONLY_PIP_SUBCOMMANDS = {"check", "freeze", "list", "show"}
READONLY_BREW_SUBCOMMANDS = {"config", "deps", "doctor", "info", "list", "search"}

WRAPPER_COMMANDS = {"builtin", "command", "env", "exec", "nice", "nohup", "sudo"}
WRAPPER_VALUE_OPTIONS = {
    "env": {"-C", "-S", "-u", "--chdir", "--split-string", "--unset"},
    "nice": {"-n"},
    "sudo": {"-g", "-h", "-p", "-r", "-t", "-u", "-C", "--group", "--host", "--prompt", "--role", "--type", "--user"},
}

COMMAND_SPLIT_RE = re.compile(r"\s*(?:&&|\|\||[;|])\s*")
ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*$")
WRITE_OPERATOR_RE = re.compile(r"(^|[^\d<])>>?|2>>?|&>|1>|2>|<<<")
SUBSHELL_RE = re.compile(r"`|\$\(")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", choices=["claude", "codex"], required=True)
    return parser.parse_args()


def load_payload() -> dict:
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def get_command(payload: dict) -> str:
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return ""

    for key in ("command", "cmd"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return value.strip()
    return ""


def is_shell_tool(payload: dict) -> bool:
    tool_name = str(payload.get("tool_name", "")).lower()
    return tool_name in {"bash", "shell", "exec", "exec_command"}


def split_segments(command: str) -> list[str]:
    parts = [part.strip() for part in COMMAND_SPLIT_RE.split(command) if part.strip()]
    return parts if parts else [command.strip()]


def skip_wrapper_tokens(tokens: list[str]) -> list[str]:
    if not tokens:
        return tokens

    index = 0
    active_wrapper = None
    skip_next = False

    while index < len(tokens):
        token = tokens[index]

        if skip_next:
            skip_next = False
            index += 1
            continue

        if token == "--":
            index += 1
            break

        if ASSIGNMENT_RE.match(token):
            index += 1
            continue

        normalized = Path(token).name.lower()

        if active_wrapper and token.startswith("-"):
            if token in WRAPPER_VALUE_OPTIONS.get(active_wrapper, set()) and "=" not in token:
                skip_next = True
            index += 1
            continue

        if normalized in WRAPPER_COMMANDS:
            active_wrapper = normalized
            index += 1
            continue

        break

    return tokens[index:]


def is_readonly_git(tokens: list[str]) -> bool:
    if len(tokens) < 2:
        return False
    return tokens[1] in READONLY_GIT_SUBCOMMANDS


def is_readonly_package_manager(tokens: list[str]) -> bool:
    if len(tokens) < 2:
        return False

    command = tokens[0]
    subcommand = tokens[1]

    if command == "npm":
        return subcommand in READONLY_NPM_SUBCOMMANDS
    if command == "pnpm":
        return subcommand in READONLY_PNPM_SUBCOMMANDS
    if command == "yarn":
        return subcommand in READONLY_YARN_SUBCOMMANDS
    if command in {"pip", "pip3"}:
        return subcommand in READONLY_PIP_SUBCOMMANDS
    if command == "brew":
        return subcommand in READONLY_BREW_SUBCOMMANDS
    return False


def segment_is_readonly(segment: str) -> bool:
    if not segment:
        return False

    if WRITE_OPERATOR_RE.search(segment):
        return False
    if SUBSHELL_RE.search(segment):
        return False
    if " tee " in f" {segment} " or segment.endswith(" tee") or segment.startswith("tee "):
        return False

    try:
        tokens = shlex.split(segment, posix=True)
    except ValueError:
        return False

    tokens = skip_wrapper_tokens(tokens)
    if not tokens:
        return False

    command = Path(tokens[0]).name.lower()

    if command in READONLY_COMMANDS:
        return True
    if command == "git":
        return is_readonly_git(tokens)
    if is_readonly_package_manager(tokens):
        return True
    if command == "sed" and "-i" not in tokens and "--in-place" not in tokens:
        return any(token.startswith("-n") or token == "-n" for token in tokens[1:])

    return False


def command_is_readonly(command: str) -> bool:
    normalized = command.strip()
    if not normalized:
        return False

    if normalized.startswith(("rm ", "mv ", "cp ", "chmod ", "chown ", "truncate ", "tee ")):
        return False

    return all(segment_is_readonly(segment) for segment in split_segments(normalized))


def build_allow_response(command: str, host: str) -> dict:
    reason = "super-stack: 只读命令自动放行"
    system_message = f"{reason} -> {command}"

    response = {
        "permissionDecision": "allow",
        "reason": reason,
        "systemMessage": system_message,
        "hookSpecificOutput": {
            "permissionDecision": "allow",
            "permissionDecisionReason": reason,
        },
    }

    if host == "codex":
        response["decision"] = "allow"

    return response


def append_log(payload: dict, verdict: str, command: str) -> None:
    cwd = payload.get("cwd") or os.getcwd()
    planning_dir = Path(cwd) / ".planning"
    if not planning_dir.exists():
        return

    log_path = planning_dir / ".super-stack-readonly-hook.log"
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(f"{verdict}\t{command}\n")


def main() -> int:
    args = parse_args()
    payload = load_payload()

    if not is_shell_tool(payload):
        print("{}")
        return 0

    command = get_command(payload)
    if not command:
        print("{}")
        return 0

    if command_is_readonly(command):
        append_log(payload, "allow", command)
        print(json.dumps(build_allow_response(command, args.host), ensure_ascii=False))
        return 0

    append_log(payload, "pass", command)
    print("{}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

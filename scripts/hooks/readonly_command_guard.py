#!/usr/bin/env python3
"""
Two-tier command guard for Codex / Claude Code hooks.

Strategy (see docs/architecture/decisions/readonly-command-hook.md):
  - allow: whitelisted read-only commands auto-approved
  - ask:  everything else goes to the host default confirmation flow

No deny tier. The hook reduces noise, not replaces user judgment.
"""

import argparse
import json
import os
import re
import shlex
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

READONLY_COMMANDS = frozenset({
    # file / directory viewing
    "cat", "head", "tail", "ls", "ll", "find", "stat", "du", "df", "wc",
    "file", "cmp", "diff", "dir",
    # search / filter
    "grep", "egrep", "fgrep", "rg", "ack", "ag", "jq", "yq", "sort", "uniq",
    # display / output
    "echo", "printf", "type", "which", "whereis", "nl",
    # environment / system info
    "pwd", "printenv", "whoami", "date", "hostname", "uname", "uptime",
    "env", "id",
    # process / network info (read-only)
    "ps", "top", "htop", "lsof", "ss", "netstat", "ifconfig", "ip", "ping",
    # misc read-only viewers
    "man", "less", "more",
})

# git subcommands that are purely read-only
READONLY_GIT_SUBCOMMANDS = frozenset({
    "blame", "branch", "cat-file", "config", "diff", "fetch", "help", "log",
    "ls-files", "ls-tree", "reflog", "remote", "rev-list", "rev-parse",
    "show", "status", "tag", "version",
})

# Flags that make an otherwise-readonly git subcommand mutate state.
GIT_READONLY_SUBCOMMAND_MUTATING_FLAGS = {
    "branch": frozenset({"-d", "-D", "--delete"}),
}

READONLY_NPM_SUBCOMMANDS = frozenset({"audit", "config", "help", "info", "list", "ls", "outdated", "search", "show", "view"})
READONLY_PNPM_SUBCOMMANDS = frozenset({"audit", "config", "help", "info", "list", "ls", "outdated", "root", "store", "why"})
READONLY_YARN_SUBCOMMANDS = frozenset({"config", "help", "info", "list", "outdated", "why"})
READONLY_PIP_SUBCOMMANDS = frozenset({"check", "freeze", "list", "show"})
READONLY_BREW_SUBCOMMANDS = frozenset({"config", "deps", "doctor", "info", "list", "search"})

WRAPPER_COMMANDS = frozenset({"builtin", "command", "env", "exec", "nice", "nohup", "sudo"})
WRAPPER_VALUE_OPTIONS = {
    "env": frozenset({"-C", "-S", "-u", "--chdir", "--split-string", "--unset"}),
    "nice": frozenset({"-n"}),
    "sudo": frozenset({"-g", "-h", "-p", "-r", "-t", "-u", "-C", "--group", "--host", "--prompt", "--role", "--type", "--user"}),
}

# ---------------------------------------------------------------------------
# Regex patterns
# ---------------------------------------------------------------------------

SEGMENT_SPLIT_RE = re.compile(r"\s*(?:&&|\|\||[;|])\s*")
ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*$")

# Any write-like redirection token
_RAW_REDIRECT_RE = re.compile(r"(?:^|[^<])>>?|&>|1>|2>|<<<")

# 2>/dev/null or 2>>/dev/null is read-only (stderr discard)
_STDERR_NULL_RE = re.compile(r"2>>?/dev/null")

# Subshell / command substitution
SUBSHELL_RE = re.compile(r"`|\$\(")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="super-stack readonly command guard")
    parser.add_argument("--host", choices=["claude", "codex"], required=True)
    parser.add_argument("--classify", help="Classify a single command and print JSON")
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
    return str(payload.get("tool_name", "")).lower() in {"bash", "shell", "exec", "exec_command"}


def split_segments(command: str) -> list[str]:
    parts = [p.strip() for p in SEGMENT_SPLIT_RE.split(command) if p.strip()]
    return parts if parts else [command.strip()]


def skip_wrapper_tokens(tokens: list[str]) -> list[str]:
    """Skip leading VAR=value assignments and wrapper commands."""
    idx = 0
    active_wrapper = None
    skip_next = False

    while idx < len(tokens):
        tok = tokens[idx]

        if skip_next:
            skip_next = False
            idx += 1
            continue

        if tok == "--":
            idx += 1
            break

        if ASSIGNMENT_RE.match(tok):
            idx += 1
            continue

        normalized = Path(tok).name.lower()

        if active_wrapper and tok.startswith("-"):
            opts = WRAPPER_VALUE_OPTIONS.get(active_wrapper, frozenset())
            if tok in opts and "=" not in tok:
                skip_next = True
            idx += 1
            continue

        if normalized in WRAPPER_COMMANDS:
            active_wrapper = normalized
            idx += 1
            continue

        break

    return tokens[idx:]


# ---------------------------------------------------------------------------
# Segment-level checks
# ---------------------------------------------------------------------------


def _has_write_redirection(segment: str) -> bool:
    """True when the segment contains a real write redirection (not 2>/dev/null)."""
    if not _RAW_REDIRECT_RE.search(segment):
        return False
    # Strip 2>/dev/null then re-check
    cleaned = _STDERR_NULL_RE.sub("", segment)
    return bool(_RAW_REDIRECT_RE.search(cleaned))


def _is_readonly_git(tokens: list[str]) -> bool:
    if len(tokens) < 2:
        return False
    subcmd = tokens[1]
    if subcmd not in READONLY_GIT_SUBCOMMANDS:
        return False
    # Reject if mutating flags are present
    mutating = GIT_READONLY_SUBCOMMAND_MUTATING_FLAGS.get(subcmd)
    if mutating and any(t in mutating for t in tokens[2:]):
        return False
    return True


def _is_readonly_package_manager(tokens: list[str]) -> bool:
    if len(tokens) < 2:
        return False
    cmd, subcmd = tokens[0], tokens[1]
    table = {
        "npm": READONLY_NPM_SUBCOMMANDS,
        "pnpm": READONLY_PNPM_SUBCOMMANDS,
        "yarn": READONLY_YARN_SUBCOMMANDS,
        "pip": READONLY_PIP_SUBCOMMANDS,
        "pip3": READONLY_PIP_SUBCOMMANDS,
        "brew": READONLY_BREW_SUBCOMMANDS,
    }
    allowed = table.get(cmd)
    return subcmd in allowed if allowed else False


def segment_is_readonly(segment: str) -> bool:
    if not segment:
        return False

    if _has_write_redirection(segment):
        return False
    if SUBSHELL_RE.search(segment):
        return False
    if " tee " in f" {segment} " or segment.startswith("tee ") or segment.endswith(" tee"):
        return False

    try:
        tokens = shlex.split(segment, posix=True)
    except ValueError:
        return False

    tokens = skip_wrapper_tokens(tokens)
    if not tokens:
        return False

    cmd = Path(tokens[0]).name.lower()

    if cmd in READONLY_COMMANDS:
        return True
    if cmd == "git":
        return _is_readonly_git(tokens)
    if _is_readonly_package_manager(tokens):
        return True
    # sed: only -n (extract-only) mode, not -i (in-place)
    if cmd == "sed" and "-i" not in tokens and "--in-place" not in tokens:
        return any(t == "-n" or t.startswith("-n") for t in tokens[1:])

    return False


# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------


def classify_command(command: str) -> dict:
    normalized = command.strip()
    if not normalized:
        return {"verdict": "ask", "riskLevel": "medium", "reason": "super-stack: empty command"}

    segments = split_segments(normalized)
    if all(segment_is_readonly(s) for s in segments):
        return {"verdict": "allow", "riskLevel": "low", "reason": "super-stack: readonly command auto-allow"}

    return {"verdict": "ask", "riskLevel": "medium", "reason": "super-stack: not whitelisted, fallback to host default"}


# ---------------------------------------------------------------------------
# Response / logging
# ---------------------------------------------------------------------------


def build_decision_response(command: str, host: str, verdict: str, reason: str, risk_level: str) -> dict:
    response = {
        "permissionDecision": verdict,
        "reason": reason,
        "systemMessage": f"{reason} -> {command}",
        "hookSpecificOutput": {
            "permissionDecision": verdict,
            "permissionDecisionReason": reason,
            "riskLevel": risk_level,
        },
    }
    if host == "codex":
        response["decision"] = verdict
    return response


def append_log(payload: dict, verdict: str, risk_level: str, command: str) -> None:
    cwd = payload.get("cwd") or os.getcwd()
    harness_dir = Path(cwd) / "harness"
    if not harness_dir.exists():
        return
    runtime_dir = harness_dir / ".runtime"
    runtime_dir.mkdir(parents=True, exist_ok=True)
    log_path = runtime_dir / "super-stack-readonly-hook.log"
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(f"{verdict}\t{risk_level}\t{command}\n")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> int:
    args = parse_args()

    if args.classify is not None:
        print(json.dumps(classify_command(args.classify), ensure_ascii=False))
        return 0

    payload = load_payload()
    if not is_shell_tool(payload):
        print("{}")
        return 0

    command = get_command(payload)
    if not command:
        print("{}")
        return 0

    decision = classify_command(command)
    verdict = decision["verdict"]
    reason = decision["reason"]
    risk_level = decision["riskLevel"]

    append_log(payload, verdict, risk_level, command)

    if verdict == "allow":
        print(json.dumps(build_decision_response(command, args.host, verdict, reason, risk_level), ensure_ascii=False))
        return 0

    # ask: fall through to host default
    print("{}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

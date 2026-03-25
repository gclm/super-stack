#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

fail() {
  printf '[测试失败] %s\n' "$*" >&2
  exit 1
}

assert_count() {
  local expected="$1"
  local pattern="$2"
  local path="$3"
  local actual
  actual="$(rg -c --fixed-strings "$pattern" "$path")"
  [[ "$actual" == "$expected" ]] || fail "${path} 中 ${pattern} 计数为 ${actual}，预期 ${expected}"
}

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT
export HOME="${TMP_HOME}"

mkdir -p "${HOME}/.codex" "${HOME}/.claude"
printf '#:schema https://developers.openai.com/codex/config-schema.json\n\n' > "${HOME}/.codex/config.toml"
printf '{}\n' > "${HOME}/.claude/settings.json"
mkdir -p "${HOME}/.super-stack/runtime/.codex/hooks" "${HOME}/.super-stack/runtime/scripts/hooks"
cp "${REPO_ROOT}/.codex/hooks/super_stack_state.py" "${HOME}/.super-stack/runtime/.codex/hooks/super_stack_state.py"
cp "${REPO_ROOT}/scripts/hooks/readonly_command_guard.py" "${HOME}/.super-stack/runtime/scripts/hooks/readonly_command_guard.py"

bash "${REPO_ROOT}/scripts/install/merge-codex-hooks.sh"
bash "${REPO_ROOT}/scripts/install/merge-codex-hooks.sh"
bash "${REPO_ROOT}/scripts/install/merge-claude-hooks.sh"
bash "${REPO_ROOT}/scripts/install/merge-claude-hooks.sh"

assert_count 1 "# BEGIN SUPER-STACK HOOKS" "${HOME}/.codex/config.toml"
assert_count 1 "[[hooks.session_start]]" "${HOME}/.codex/config.toml"
assert_count 1 "[[hooks.pre_tool_use]]" "${HOME}/.codex/config.toml"
assert_count 1 "[[hooks.stop]]" "${HOME}/.codex/config.toml"

python3 - <<'PY' "${HOME}/.claude/settings.json"
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
hooks = settings.get("hooks", {})
for name in ("SessionStart", "PreToolUse", "Stop"):
    entries = hooks.get(name)
    if not isinstance(entries, list) or len(entries) != 1:
        raise SystemExit(f"{name} entries invalid: {entries!r}")
PY

printf '[测试通过] hook merge idempotent\n'

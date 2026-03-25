#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

fail() {
  printf '[测试失败] %s\n' "$*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "预期文件不存在：${path}"
}

assert_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "预期目录不存在：${path}"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "预期路径已被清理，但仍存在：${path}"
}

assert_contains() {
  local path="$1"
  local text="$2"
  rg -q --fixed-strings "$text" "$path" || fail "未在 ${path} 中找到：${text}"
}

assert_not_dir() {
  local path="$1"
  [[ ! -d "$path" ]] || fail "预期目录不应存在：${path}"
}

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT

export HOME="${TMP_HOME}"

mkdir -p "${HOME}/.codex" "${HOME}/.claude"
printf 'ORIGINAL CODEX AGENTS\n' > "${HOME}/.codex/AGENTS.md"
printf '# user config\n' > "${HOME}/.codex/config.toml"
printf 'ORIGINAL CLAUDE ROUTER\n' > "${HOME}/.claude/CLAUDE.md"
printf '{"foo":1}\n' > "${HOME}/.claude/settings.json"

bash "${REPO_ROOT}/scripts/install/reset-install-state.sh"
bash "${REPO_ROOT}/scripts/install/sync-to-codex.sh"
bash "${REPO_ROOT}/scripts/install/sync-to-claude.sh"

check_output="$(bash "${REPO_ROOT}/scripts/check/check-global-install.sh")"
printf '%s\n' "$check_output" | rg -q '结果：通过' || fail "全局安装检查未通过"

assert_file "${HOME}/.codex/AGENTS.md"
assert_file "${HOME}/.claude/CLAUDE.md"
assert_file "${HOME}/.codex/config.toml"
assert_file "${HOME}/.claude/settings.json"
assert_dir "${HOME}/.super-stack/runtime"
assert_dir "${HOME}/.super-stack/state"
assert_file "${HOME}/.super-stack/state/install-manifest.tsv"
assert_dir "${HOME}/.super-stack/backup"
assert_dir "${HOME}/.super-stack/backup/install-state"
assert_dir "${HOME}/.agents/skills"

assert_file "${HOME}/.super-stack/runtime/.codex/hooks/super_stack_state.py"
assert_not_dir "${HOME}/.super-stack/runtime/.git"
assert_not_dir "${HOME}/.super-stack/runtime/.github"
assert_not_dir "${HOME}/.super-stack/runtime/.idea"
assert_not_dir "${HOME}/.super-stack/runtime/.planning"
assert_not_dir "${HOME}/.super-stack/runtime/docs"
assert_not_dir "${HOME}/.super-stack/runtime/tests"
assert_not_dir "${HOME}/.super-stack/runtime/.agents"
assert_not_dir "${HOME}/.super-stack/runtime/.claude"
assert_not_dir "${HOME}/.super-stack/runtime/.codex/agents"

assert_contains "${HOME}/.codex/AGENTS.md" "single global workflow source managed by super-stack"
assert_contains "${HOME}/.claude/CLAUDE.md" "single global workflow source managed by super-stack"
assert_contains "${HOME}/.codex/config.toml" "readonly_command_guard.py"
assert_contains "${HOME}/.claude/settings.json" "[super-stack] resuming from .planning/STATE.md"

first_skill_name="$(find "${REPO_ROOT}/.agents/skills" -maxdepth 2 -mindepth 2 -type d | sort | head -n 1 | xargs basename)"
assert_dir "${HOME}/.agents/skills/${first_skill_name}"
assert_dir "${HOME}/.claude/skills/${first_skill_name}"

bash "${REPO_ROOT}/scripts/install/uninstall-global.sh"

assert_contains "${HOME}/.codex/AGENTS.md" "ORIGINAL CODEX AGENTS"
assert_contains "${HOME}/.codex/config.toml" "# user config"
assert_contains "${HOME}/.claude/CLAUDE.md" "ORIGINAL CLAUDE ROUTER"
assert_contains "${HOME}/.claude/settings.json" '{"foo":1}'

assert_not_exists "${HOME}/.super-stack/runtime"
assert_not_exists "${HOME}/.agents/skills/${first_skill_name}"
assert_not_exists "${HOME}/.claude/skills/${first_skill_name}"

printf '[测试通过] global install roundtrip\n'

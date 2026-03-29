#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CODEX_HOME="${HOME}/.codex"
CLAUDE_HOME="${HOME}/.claude"
RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"
USER_AGENTS_HOME="${HOME}/.agents"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${SUPER_STACK_BACKUP_ROOT}/uninstall-${TIMESTAMP}"
MANAGED_CHECK_SCRIPT="${REPO_ROOT}/scripts/config/check_managed_config.py"

backup_if_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    ensure_dir "${BACKUP_ROOT}"
    local safe_label="${label//\//_}"
    cp -R "$path" "${BACKUP_ROOT}/${safe_label}"
    log "已备份 ${path} -> ${BACKUP_ROOT}/${safe_label}"
  fi
}

remove_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    rm -rf "$path"
    log "已删除 ${path}"
  fi
}

log "开始执行 super-stack 全局卸载"
log "备份目录：${BACKUP_ROOT}"

TEMP_STATE_ROOT=""
if [[ -d "$(state_root)" ]]; then
  TEMP_STATE_ROOT="$(mktemp -d)"
  cp -R "$(state_root)" "${TEMP_STATE_ROOT}/state"
fi

backup_if_exists "${RUNTIME_ROOT}" "runtime_super-stack"
backup_if_exists "${CODEX_HOME}/AGENTS.md" "codex_AGENTS.md"
backup_if_exists "${CLAUDE_HOME}/CLAUDE.md" "claude_CLAUDE.md"
backup_if_exists "${CODEX_HOME}/config.toml" "codex_config.toml"
backup_if_exists "${CLAUDE_HOME}/settings.json" "claude_settings.json"

remove_if_exists "${RUNTIME_ROOT}"

while IFS= read -r skill_dir; do
  skill_name="$(basename "$skill_dir")"
  remove_if_exists "${USER_AGENTS_HOME}/skills/${skill_name}"
  remove_if_exists "${CODEX_HOME}/skills/${skill_name}"
  remove_if_exists "${CLAUDE_HOME}/skills/${skill_name}"
done < <(iterate_managed_skill_dirs)

while IFS= read -r managed_file; do
  [[ -n "$managed_file" ]] || continue
  remove_if_exists "$managed_file"
done < <(managed_config_lines codex_agents managed_files)

if [[ -n "${TEMP_STATE_ROOT}" ]]; then
  SUPER_STACK_STATE_ROOT="${TEMP_STATE_ROOT}/state"
  SUPER_STACK_MANIFEST="${SUPER_STACK_STATE_ROOT}/install-manifest.tsv"
fi

restore_recorded_targets
if [[ -n "${TEMP_STATE_ROOT}" ]]; then
  rm -rf "${TEMP_STATE_ROOT}"
else
  rm -rf "$(state_root)"
fi

log "super-stack 全局卸载完成"
log "备份已存放到 ${BACKUP_ROOT}"
log "如存在安装前记录，相关文件已恢复。"

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CODEX_HOME="${HOME}/.codex"
CLAUDE_HOME="${HOME}/.claude"
USER_AGENTS_HOME="${HOME}/.agents"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${CODEX_HOME}/backups/super-stack-uninstall-${TIMESTAMP}"

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

backup_if_exists "${CODEX_HOME}/super-stack" "codex_super-stack"
backup_if_exists "${CLAUDE_HOME}/super-stack" "claude_super-stack"
backup_if_exists "${CODEX_HOME}/AGENTS.md" "codex_AGENTS.md"
backup_if_exists "${CLAUDE_HOME}/CLAUDE.md" "claude_CLAUDE.md"
backup_if_exists "${CODEX_HOME}/config.toml" "codex_config.toml"
backup_if_exists "${CLAUDE_HOME}/settings.json" "claude_settings.json"

remove_if_exists "${CODEX_HOME}/super-stack"
remove_if_exists "${CLAUDE_HOME}/super-stack"

while IFS= read -r skill_dir; do
  skill_name="$(basename "$skill_dir")"
  remove_if_exists "${USER_AGENTS_HOME}/skills/${skill_name}"
  remove_if_exists "${CODEX_HOME}/skills/${skill_name}"
  remove_if_exists "${CLAUDE_HOME}/skills/${skill_name}"
done < <(find "${REPO_ROOT}/.agents/skills" -maxdepth 2 -mindepth 2 -type d | sort)

for agent_file in \
  "${CODEX_HOME}/agents/super-stack-explorer.toml" \
  "${CODEX_HOME}/agents/super-stack-planner.toml" \
  "${CODEX_HOME}/agents/super-stack-reviewer.toml"; do
  remove_if_exists "$agent_file"
done

restore_recorded_targets
rm -rf "$(state_root)"

log "super-stack 全局卸载完成"
log "备份已存放到 ${BACKUP_ROOT}"
log "如存在安装前记录，相关文件已恢复。"

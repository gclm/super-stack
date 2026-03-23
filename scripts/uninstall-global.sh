#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CODEX_HOME="${HOME}/.codex"
CLAUDE_HOME="${HOME}/.claude"
USER_AGENTS_HOME="${HOME}/.agents"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${CODEX_HOME}/backups/super-stack-uninstall-${TIMESTAMP}"

SUPER_STACK_SKILLS=(
  brainstorm
  build
  discuss
  map-codebase
  plan
  qa
  review
  ship
  verify
)

backup_if_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    ensure_dir "${BACKUP_ROOT}"
    local safe_label="${label//\//_}"
    cp -R "$path" "${BACKUP_ROOT}/${safe_label}"
    log "Backed up ${path} -> ${BACKUP_ROOT}/${safe_label}"
  fi
}

remove_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    rm -rf "$path"
    log "Removed ${path}"
  fi
}

log "Starting super-stack global uninstall"
log "Backup root: ${BACKUP_ROOT}"

backup_if_exists "${CODEX_HOME}/super-stack" "codex_super-stack"
backup_if_exists "${CLAUDE_HOME}/super-stack" "claude_super-stack"
backup_if_exists "${CODEX_HOME}/AGENTS.md" "codex_AGENTS.md"
backup_if_exists "${CLAUDE_HOME}/CLAUDE.md" "claude_CLAUDE.md"

remove_managed_block "${CODEX_HOME}/AGENTS.md" "# BEGIN SUPER-STACK GLOBAL" "# END SUPER-STACK GLOBAL"
remove_managed_block "${CLAUDE_HOME}/CLAUDE.md" "<!-- BEGIN SUPER-STACK GLOBAL -->" "<!-- END SUPER-STACK GLOBAL -->"
log "Removed managed global routing blocks"

remove_if_exists "${CODEX_HOME}/super-stack"
remove_if_exists "${CLAUDE_HOME}/super-stack"

for skill in "${SUPER_STACK_SKILLS[@]}"; do
  remove_if_exists "${USER_AGENTS_HOME}/skills/${skill}"
  remove_if_exists "${CODEX_HOME}/skills/${skill}"
  remove_if_exists "${CLAUDE_HOME}/skills/${skill}"
done

for agent_file in \
  "${CODEX_HOME}/agents/super-stack-explorer.toml" \
  "${CODEX_HOME}/agents/super-stack-planner.toml" \
  "${CODEX_HOME}/agents/super-stack-reviewer.toml"; do
  remove_if_exists "$agent_file"
done

log "super-stack global uninstall complete"
log "Your backups are stored in ${BACKUP_ROOT}"
log "This script does not modify ~/.codex/config.toml or remove non-super-stack global content."

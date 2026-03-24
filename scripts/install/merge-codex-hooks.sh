#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CODEX_HOME="${HOME}/.codex"
CONFIG_FILE="${CODEX_HOME}/config.toml"
HOOK_SCRIPT="${CODEX_HOME}/super-stack/.codex/hooks/super_stack_state.py"
READONLY_HOOK_SCRIPT="${CODEX_HOME}/super-stack/scripts/hooks/readonly_command_guard.py"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${CODEX_HOME}/backups"
BACKUP_FILE="${BACKUP_DIR}/config.super-stack-hooks.${TIMESTAMP}.toml"

ensure_dir "$CODEX_HOME"
ensure_dir "$BACKUP_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
  cp "$CONFIG_FILE" "$BACKUP_FILE"
else
  printf '#:schema https://developers.openai.com/codex/config-schema.json\n\n' > "$CONFIG_FILE"
fi

BLOCK=""
if ! rg -q '^\[hooks\]$' "$CONFIG_FILE"; then
  BLOCK="${BLOCK}[hooks]

"
fi

BLOCK="${BLOCK}[[hooks.session_start]]
command = \"python3 \\\"${HOOK_SCRIPT}\\\"\"

[[hooks.pre_tool_use]]
command = \"python3 \\\"${READONLY_HOOK_SCRIPT}\\\" --host codex\"

[[hooks.stop]]
command = \"python3 \\\"${HOOK_SCRIPT}\\\"\"
"

append_managed_block "$CONFIG_FILE" "# BEGIN SUPER-STACK HOOKS" "# END SUPER-STACK HOOKS" "$BLOCK"

log "已将 Codex hooks 合并到 ${CONFIG_FILE}"
if [[ -f "$BACKUP_FILE" ]]; then
  log "已写入备份：${BACKUP_FILE}"
fi

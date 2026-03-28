#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CLAUDE_HOME="${HOME}/.claude"
RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"
SKILLS_DEST="${CLAUDE_HOME}/skills"
RENDER_SCRIPT="${SCRIPT_DIR}/../config/render_managed_config.py"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${SUPER_STACK_BACKUP_ROOT}/claude-hooks"
BACKUP_FILE="${BACKUP_DIR}/settings.super-stack-hooks.${TIMESTAMP}.json"

merge_claude_hooks() {
  local settings_file="$1"

  ensure_dir "$CLAUDE_HOME"
  ensure_dir "$BACKUP_DIR"

  if [[ -f "$settings_file" ]]; then
    cp "$settings_file" "$BACKUP_FILE"
  else
    printf '{}\n' > "$settings_file"
  fi

  python3 - "$settings_file" "$RENDER_SCRIPT" "$RUNTIME_ROOT" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
render_script = Path(sys.argv[2])
runtime_root = sys.argv[3]

rendered = subprocess.run(
    [sys.executable, str(render_script), "--block", "claude_hooks", "--runtime-root", runtime_root],
    text=True,
    capture_output=True,
    check=True,
)
source = json.loads(rendered.stdout)
settings = json.loads(settings_path.read_text() or "{}")

source_hooks = source.get("hooks")
if not isinstance(source_hooks, dict):
    raise SystemExit("hooks source must contain a top-level 'hooks' object")

settings_hooks = settings.get("hooks")
if not isinstance(settings_hooks, dict):
    settings_hooks = {}
    settings["hooks"] = settings_hooks

added = 0

for event_name, entries in source_hooks.items():
    if not isinstance(entries, list):
        continue

    existing_entries = settings_hooks.get(event_name)
    if not isinstance(existing_entries, list):
        existing_entries = []
        settings_hooks[event_name] = existing_entries

    seen = {json.dumps(item, sort_keys=True, ensure_ascii=False) for item in existing_entries}

    for entry in entries:
        fingerprint = json.dumps(entry, sort_keys=True, ensure_ascii=False)
        if fingerprint in seen:
            continue
        existing_entries.append(entry)
        seen.add(fingerprint)
        added += 1

settings_path.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n")
print(f"ADDED={added}")
PY

  log "已将 Claude hooks 合并到 ${settings_file}"
  if [[ -f "$BACKUP_FILE" ]]; then
    log "已写入备份：${BACKUP_FILE}"
  fi
}

ensure_dir "$CLAUDE_HOME"
record_target_state "${CLAUDE_HOME}/CLAUDE.md" "claude_CLAUDE.md"
record_target_state "${CLAUDE_HOME}/settings.json" "claude_settings.json"
record_target_state "$RUNTIME_ROOT" "runtime_super-stack"
copy_runtime_tree "$RUNTIME_ROOT"
mirror_repo_skills "$SKILLS_DEST"

write_global_router_file "${CLAUDE_HOME}/CLAUDE.md" "shared global workflow source" "Claude" "Global Claude-facing skills are mirrored into \`${SKILLS_DEST}\`."

merge_claude_hooks "${CLAUDE_HOME}/settings.json"

log "已将纯运行仓库资产复制到 ${RUNTIME_ROOT}"
log "已将 Claude 全局 skills 镜像到 ${SKILLS_DEST}"
log "已更新 ${CLAUDE_HOME}/CLAUDE.md 中的全局路由"
log "已将 Claude hooks 合并到 ${CLAUDE_HOME}/settings.json"
log "Claude 已启用仅全局模式。"

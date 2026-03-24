#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CLAUDE_HOME="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_HOME}/settings.json"
HOOKS_SOURCE="${REPO_ROOT}/.claude/hooks/hooks.json"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${CLAUDE_HOME}/backups"
BACKUP_FILE="${BACKUP_DIR}/settings.super-stack-hooks.${TIMESTAMP}.json"

ensure_dir "$CLAUDE_HOME"
ensure_dir "$BACKUP_DIR"

if [[ ! -f "$HOOKS_SOURCE" ]]; then
  die "未找到 Claude hooks 源文件：${HOOKS_SOURCE}"
fi

if [[ -f "$SETTINGS_FILE" ]]; then
  cp "$SETTINGS_FILE" "$BACKUP_FILE"
else
  printf '{}\n' > "$SETTINGS_FILE"
fi

python3 - "$SETTINGS_FILE" "$HOOKS_SOURCE" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
hooks_source_path = Path(sys.argv[2])

settings = json.loads(settings_path.read_text() or "{}")
source = json.loads(hooks_source_path.read_text())

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

log "已将 Claude hooks 合并到 ${SETTINGS_FILE}"
if [[ -f "$BACKUP_FILE" ]]; then
  log "已写入备份：${BACKUP_FILE}"
fi

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CLAUDE_HOME="${HOME}/.claude"
DEST="${CLAUDE_HOME}/super-stack"
SKILLS_DEST="${CLAUDE_HOME}/skills"

ensure_dir "$CLAUDE_HOME"
ensure_dir "$SKILLS_DEST"
record_target_state "${CLAUDE_HOME}/CLAUDE.md" "claude_CLAUDE.md"
record_target_state "${CLAUDE_HOME}/settings.json" "claude_settings.json"
record_target_state "$DEST" "claude_super-stack"
copy_tree "${REPO_ROOT}" "$DEST"

for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
  [[ -d "$skill_dir" ]] || continue
  copy_tree "$skill_dir" "${SKILLS_DEST}/$(basename "$skill_dir")"
done

cat > "${CLAUDE_HOME}/CLAUDE.md" <<EOF
# Super Stack Global Router

Use \`${DEST}/AGENTS.md\` as the shared global workflow source.

- This is the default global workflow router for Claude.
- This repository is the single global workflow source managed by super-stack.
- Global Claude-facing skills are mirrored into \`${SKILLS_DEST}\`.
- Treat global super-stack as the canonical system configuration.
EOF

bash "${SCRIPT_DIR}/merge-claude-hooks.sh"

log "已将 Claude 全局资产复制到 ${DEST}"
log "已将 Claude 全局 skills 镜像到 ${SKILLS_DEST}"
log "已更新 ${CLAUDE_HOME}/CLAUDE.md 中的全局路由"
log "已将 Claude hooks 合并到 ${CLAUDE_HOME}/settings.json"
log "Claude 已启用仅全局模式。"

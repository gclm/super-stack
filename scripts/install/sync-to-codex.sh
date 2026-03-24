#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CODEX_HOME="${HOME}/.codex"
STACK_DEST="${CODEX_HOME}/super-stack"
AGENTS_DEST="${CODEX_HOME}/agents"
USER_AGENTS_HOME="${HOME}/.agents"
USER_SKILLS_DEST="${USER_AGENTS_HOME}/skills"

ensure_dir "$AGENTS_DEST"
ensure_dir "$USER_SKILLS_DEST"

record_target_state "${CODEX_HOME}/AGENTS.md" "codex_AGENTS.md"
record_target_state "${CODEX_HOME}/config.toml" "codex_config.toml"
record_target_state "$STACK_DEST" "codex_super-stack"

ensure_dir "$STACK_DEST"

copy_tree "${REPO_ROOT}/.agents" "${STACK_DEST}/.agents"
copy_tree "${REPO_ROOT}/protocols" "${STACK_DEST}/protocols"
copy_tree "${REPO_ROOT}/templates" "${STACK_DEST}/templates"
copy_tree "${REPO_ROOT}/scripts" "${STACK_DEST}/scripts"
copy_tree "${REPO_ROOT}/.codex" "${STACK_DEST}/.codex"
cp "${REPO_ROOT}/AGENTS.md" "${STACK_DEST}/AGENTS.md"
cp "${REPO_ROOT}/README.md" "${STACK_DEST}/README.md"

for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
  [[ -d "$skill_dir" ]] || continue
  copy_tree "$skill_dir" "${USER_SKILLS_DEST}/$(basename "$skill_dir")"
done

for agent_file in "${REPO_ROOT}"/.codex/agents/*.toml; do
  cp "$agent_file" "${AGENTS_DEST}/$(basename "$agent_file")"
done

cat > "${CODEX_HOME}/AGENTS.md" <<EOF
# Super Stack Global Router

Use \`${STACK_DEST}/AGENTS.md\` as the global workflow source.

- This is the default global workflow router for Codex.
- This repository is the single global workflow source managed by super-stack.
- Global super-stack skills are installed to \`${USER_SKILLS_DEST}\`.
- Treat global super-stack as the canonical system configuration.
EOF

write_if_missing "${REPO_ROOT}/.codex/config.toml" "${CODEX_HOME}/config.toml"
bash "${SCRIPT_DIR}/merge-codex-hooks.sh"

log "已将 Codex 全局资产复制到 ${CODEX_HOME}"
log "已将 skills 安装到 ${USER_SKILLS_DEST}"
log "已更新 ${CODEX_HOME}/AGENTS.md 中的全局路由"
log "已将 Codex hooks 合并到 ${CODEX_HOME}/config.toml"
log "Codex 已启用仅全局模式。"
log "如果你已自定义 ~/.codex/config.toml，请在手动合并 super-stack 设置前先审阅。"

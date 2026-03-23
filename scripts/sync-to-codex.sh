#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CODEX_HOME="${HOME}/.codex"
STACK_DEST="${CODEX_HOME}/super-stack"
AGENTS_DEST="${CODEX_HOME}/agents"
LEGACY_SKILLS_DEST="${CODEX_HOME}/skills"
USER_AGENTS_HOME="${HOME}/.agents"
USER_SKILLS_DEST="${USER_AGENTS_HOME}/skills"

ensure_dir "$LEGACY_SKILLS_DEST"
ensure_dir "$STACK_DEST"
ensure_dir "$AGENTS_DEST"
ensure_dir "$USER_SKILLS_DEST"

copy_tree "${REPO_ROOT}/.agents" "${STACK_DEST}/.agents"
copy_tree "${REPO_ROOT}/protocols" "${STACK_DEST}/protocols"
copy_tree "${REPO_ROOT}/templates" "${STACK_DEST}/templates"
copy_tree "${REPO_ROOT}/.codex" "${STACK_DEST}/.codex"
cp "${REPO_ROOT}/AGENTS.md" "${STACK_DEST}/AGENTS.md"
cp "${REPO_ROOT}/README.md" "${STACK_DEST}/README.md"

for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
  [[ -d "$skill_dir" ]] || continue
  copy_tree "$skill_dir" "${LEGACY_SKILLS_DEST}/$(basename "$skill_dir")"
  copy_tree "$skill_dir" "${USER_SKILLS_DEST}/$(basename "$skill_dir")"
done

for agent_file in "${REPO_ROOT}"/.codex/agents/*.toml; do
  cp "$agent_file" "${AGENTS_DEST}/$(basename "$agent_file")"
done

cat > "${CODEX_HOME}/AGENTS.md" <<EOF
# Super Stack Global Router

Use \`${STACK_DEST}/AGENTS.md\` as the global workflow source.

- This is the default global workflow router for Codex.
- Prefer project-local \`AGENTS.md\` and \`.codex/AGENTS.md\` when a repository provides them.
- Global super-stack skills are installed to \`${USER_SKILLS_DEST}\`.
- Legacy compatibility mirrors are also installed to \`${LEGACY_SKILLS_DEST}\`.
- Treat global super-stack as the default system, and project-level files only as thin overrides.
EOF

write_if_missing "${REPO_ROOT}/.codex/config.toml" "${CODEX_HOME}/config.toml"

log "Codex global assets copied into ${CODEX_HOME}"
log "Skills installed to ${USER_SKILLS_DEST}"
log "Legacy compatibility mirrors installed to ${LEGACY_SKILLS_DEST}"
log "Global AGENTS routing updated in ${CODEX_HOME}/AGENTS.md"
log "Global-first strategy active for Codex; use project-level files only as thin overrides."
log "If you already use a custom ~/.codex/config.toml, review it before manually merging super-stack settings."

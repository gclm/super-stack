#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CLAUDE_HOME="${HOME}/.claude"
DEST="${CLAUDE_HOME}/super-stack"
SKILLS_DEST="${CLAUDE_HOME}/skills"

ensure_dir "$CLAUDE_HOME"
ensure_dir "$SKILLS_DEST"
copy_tree "${REPO_ROOT}" "$DEST"

for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
  [[ -d "$skill_dir" ]] || continue
  copy_tree "$skill_dir" "${SKILLS_DEST}/$(basename "$skill_dir")"
done

cat > "${CLAUDE_HOME}/CLAUDE.md" <<EOF
# Super Stack Global Router

Use \`${DEST}/AGENTS.md\` as the shared global workflow source.

- This is the default global workflow router for Claude.
- Prefer project-local \`AGENTS.md\`, \`.claude/CLAUDE.md\`, and project-local skills when a repository provides them.
- Global Claude-facing skills are mirrored into \`${SKILLS_DEST}\`.
- Treat global super-stack as the default system, and project-level files only as thin overrides.
EOF

log "Claude global assets copied to ${DEST}"
log "Claude global skills mirrored to ${SKILLS_DEST}"
log "Global CLAUDE routing updated in ${CLAUDE_HOME}/CLAUDE.md"
log "Global-first strategy active for Claude; use project-level files only as thin overrides."

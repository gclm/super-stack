#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

HOST=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$HOST" ]] || die "--host is required"
[[ -n "$TARGET" ]] || die "--target is required"
[[ -d "$TARGET" ]] || die "Target directory does not exist: $TARGET"

SUPER_DIR="${TARGET}/.super-stack"
SHARED_SKILLS_DIR="${SUPER_DIR}/.agents/skills"

log "Syncing shared core into ${SUPER_DIR}"
ensure_dir "$SUPER_DIR"

copy_tree "${REPO_ROOT}/.agents" "${SUPER_DIR}/.agents"
copy_tree "${REPO_ROOT}/protocols" "${SUPER_DIR}/protocols"
copy_tree "${REPO_ROOT}/templates" "${SUPER_DIR}/templates"
copy_tree "${REPO_ROOT}/.claude" "${SUPER_DIR}/.claude"
copy_tree "${REPO_ROOT}/.claude-plugin" "${SUPER_DIR}/.claude-plugin"
copy_tree "${REPO_ROOT}/.codex" "${SUPER_DIR}/.codex"
cp "${REPO_ROOT}/AGENTS.md" "${SUPER_DIR}/AGENTS.md"
cp "${REPO_ROOT}/README.md" "${SUPER_DIR}/README.md"

ensure_dir "${TARGET}/.agents/skills"
for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
  [[ -d "$skill_dir" ]] || continue
  copy_dir_if_missing "$skill_dir" "${TARGET}/.agents/skills/$(basename "$skill_dir")"
done

append_managed_block \
  "${TARGET}/AGENTS.md" \
  "# BEGIN SUPER-STACK" \
  "# END SUPER-STACK" \
  "Shared workflow guidance lives in \`.super-stack/AGENTS.md\`.
Primary project-local skills are mirrored into \`.agents/skills/\`.
The canonical shared copy remains under \`.super-stack/.agents/skills/\` and may be organized in grouped subdirectories.
For Codex, treat root \`AGENTS.md\` as the primary workflow router and use project-local skills as detailed stage references."

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  ensure_dir "${TARGET}/.claude/skills"
  for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
    [[ -d "$skill_dir" ]] || continue
    copy_dir_if_missing "$skill_dir" "${TARGET}/.claude/skills/$(basename "$skill_dir")"
  done

  append_managed_block \
    "${TARGET}/.claude/CLAUDE.md" \
    "<!-- BEGIN SUPER-STACK -->" \
    "<!-- END SUPER-STACK -->" \
    "Use \`.super-stack/.claude/CLAUDE.md\` and \`.super-stack/AGENTS.md\` as the shared workflow source.
Claude-facing project skills are mirrored into \`.claude/skills/\`.
The canonical shared copy remains under \`.super-stack/.agents/skills/\` and may be organized in grouped subdirectories."
fi

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  append_managed_block \
    "${TARGET}/.codex/AGENTS.md" \
    "# BEGIN SUPER-STACK" \
    "# END SUPER-STACK" \
    "Supplement local Codex guidance with \`.super-stack/.codex/AGENTS.md\` and \`.super-stack/AGENTS.md\`.
Codex-facing project skills are mirrored into \`.agents/skills/\`.
The canonical shared copy remains under \`.super-stack/.agents/skills/\` and may be organized in grouped subdirectories.
Do not rely solely on automatic skill execution; use root \`AGENTS.md\` as the main workflow router."

  write_if_missing "${REPO_ROOT}/.codex/config.toml" "${TARGET}/.codex/config.toml"

  ensure_dir "${TARGET}/.codex/agents"
  for agent_file in "${REPO_ROOT}"/.codex/agents/*.toml; do
    write_if_missing "$agent_file" "${TARGET}/.codex/agents/$(basename "$agent_file")"
  done
fi

log "Project sync complete for ${TARGET}"

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/check-project-install.sh --target /path/to/project [--host claude|codex|all]
EOF
}

TARGET=""
HOST="all"
WARNINGS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$TARGET" ]] || die "--target is required"
[[ -d "$TARGET" ]] || die "Target directory does not exist: $TARGET"

case "$HOST" in
  claude|codex|all) ;;
  *) die "Invalid --host: $HOST" ;;
esac

ok() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    ok "${label}: ${path}"
  else
    warn "${label}: missing (${path})"
  fi
}

check_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "$path" ]]; then
    ok "${label}: ${path}"
  else
    warn "${label}: missing (${path})"
  fi
}

check_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [[ ! -f "$path" ]]; then
    warn "${label}: file missing (${path})"
    return
  fi

  if rg -q --fixed-strings "$pattern" "$path"; then
    ok "${label}"
  else
    warn "${label}: pattern not found in ${path}"
  fi
}

count_skill_entries() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    printf '0'
    return
  fi
  find "$path" -maxdepth 2 -type f -name 'SKILL.md' | wc -l | tr -d ' '
}

printf '== super-stack project install check ==\n'
printf 'target: %s\n' "$TARGET"
printf 'host: %s\n' "$HOST"
printf '\n'

printf '== Shared ==\n'
check_file "${TARGET}/AGENTS.md" "Project root AGENTS"
check_file "${TARGET}/.super-stack/AGENTS.md" "Project shared stack AGENTS"
check_dir "${TARGET}/.super-stack/.agents/skills" "Canonical shared skills directory"
check_dir "${TARGET}/.agents/skills" "Project mirrored skills directory"
check_contains "${TARGET}/AGENTS.md" "# BEGIN SUPER-STACK" "Project AGENTS managed block present"
check_contains "${TARGET}/AGENTS.md" "Shared workflow guidance lives in \`.super-stack/AGENTS.md\`." "Project AGENTS points to .super-stack"
check_contains "${TARGET}/AGENTS.md" "The canonical shared copy remains under \`.super-stack/.agents/skills/\` and may be organized in grouped subdirectories." "Project AGENTS explains canonical grouped skills"
printf 'Project mirrored skills: %s\n' "$(count_skill_entries "${TARGET}/.agents/skills")"
printf '\n'

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  printf '== Codex ==\n'
  check_file "${TARGET}/.codex/AGENTS.md" "Project Codex AGENTS"
  check_file "${TARGET}/.codex/config.toml" "Project Codex config"
  check_dir "${TARGET}/.codex/agents" "Project Codex agents"
  check_contains "${TARGET}/.codex/AGENTS.md" "# BEGIN SUPER-STACK" "Project Codex managed block present"
  check_contains "${TARGET}/.codex/AGENTS.md" "Do not rely solely on automatic skill execution; use root \`AGENTS.md\` as the main workflow router." "Project Codex router guidance present"
  printf '\n'
fi

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  printf '== Claude ==\n'
  check_file "${TARGET}/.claude/CLAUDE.md" "Project Claude CLAUDE.md"
  check_dir "${TARGET}/.claude/skills" "Project Claude mirrored skills"
  check_contains "${TARGET}/.claude/CLAUDE.md" "<!-- BEGIN SUPER-STACK -->" "Project Claude managed block present"
  check_contains "${TARGET}/.claude/CLAUDE.md" "Use \`.super-stack/.claude/CLAUDE.md\` and \`.super-stack/AGENTS.md\` as the shared workflow source." "Project Claude points to .super-stack"
  printf 'Claude mirrored skills: %s\n' "$(count_skill_entries "${TARGET}/.claude/skills")"
  printf '\n'
fi

printf '== Key Skill Consistency ==\n'
for skill in discuss brainstorm review verify; do
  mirrored="$(find "${TARGET}/.agents/skills" -maxdepth 2 -type f -path "*/${skill}/SKILL.md" | head -n 1 || true)"
  canonical="$(find "${TARGET}/.super-stack/.agents/skills" -maxdepth 4 -type f -path "*/${skill}/SKILL.md" | head -n 1 || true)"
  if [[ -z "$mirrored" || -z "$canonical" ]]; then
    warn "Skill ${skill}: missing mirrored or canonical file"
    continue
  fi
  if cmp -s "$mirrored" "$canonical"; then
    ok "Skill ${skill}: mirrored content matches canonical"
  else
    warn "Skill ${skill}: mirrored content differs from canonical"
  fi
done
printf '\n'

if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'RESULT: PASS\n'
  printf 'super-stack project install looks healthy.\n'
else
  printf 'RESULT: WARN (%s issue(s))\n' "$WARNINGS"
  printf 'Review the warnings above. Re-run ./scripts/install.sh --host %s --mode project --target %s if needed.\n' "$HOST" "$TARGET"
fi

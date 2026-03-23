#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CODEX_HOME="${HOME}/.codex"
CLAUDE_HOME="${HOME}/.claude"
USER_AGENTS_HOME="${HOME}/.agents"

CODEX_STACK_AGENTS="${CODEX_HOME}/super-stack/AGENTS.md"
CODEX_AGENTS_FILE="${CODEX_HOME}/AGENTS.md"
CODEX_CONFIG_FILE="${CODEX_HOME}/config.toml"
CODEX_SKILLS_DIR="${CODEX_HOME}/skills"
USER_SKILLS_DIR="${USER_AGENTS_HOME}/skills"
CLAUDE_STACK_AGENTS="${CLAUDE_HOME}/super-stack/AGENTS.md"
CLAUDE_FILE="${CLAUDE_HOME}/CLAUDE.md"
CLAUDE_SKILLS_DIR="${CLAUDE_HOME}/skills"

WARNINGS=0

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

printf '== super-stack global install check ==\n'
printf 'repo: %s\n' "${REPO_ROOT}"
printf 'home: %s\n' "${HOME}"
printf '\n'

printf '== Codex ==\n'
check_file "$CODEX_STACK_AGENTS" "Codex shared stack AGENTS"
check_file "$CODEX_AGENTS_FILE" "Codex global AGENTS"
check_file "$CODEX_CONFIG_FILE" "Codex config"
check_dir "$USER_SKILLS_DIR" "User skills directory"
check_dir "$CODEX_SKILLS_DIR" "Codex legacy skills directory"
check_contains "$CODEX_AGENTS_FILE" "# BEGIN SUPER-STACK GLOBAL" "Codex global managed block present"
check_contains "$CODEX_AGENTS_FILE" "Use \`${CODEX_HOME}/super-stack/AGENTS.md\` as the global workflow source." "Codex global routing points to super-stack"
check_contains "$CODEX_AGENTS_FILE" "Global super-stack skills are installed to \`${USER_SKILLS_DIR}\`." "Codex AGENTS mentions ~/.agents skills"
printf 'Codex user-visible skills: %s\n' "$(count_skill_entries "$USER_SKILLS_DIR")"
printf 'Codex legacy mirrored skills: %s\n' "$(count_skill_entries "$CODEX_SKILLS_DIR")"
printf '\n'

printf '== Claude ==\n'
check_file "$CLAUDE_STACK_AGENTS" "Claude shared stack AGENTS"
check_file "$CLAUDE_FILE" "Claude global CLAUDE.md"
check_dir "$CLAUDE_SKILLS_DIR" "Claude global skills directory"
check_contains "$CLAUDE_FILE" "<!-- BEGIN SUPER-STACK GLOBAL -->" "Claude global managed block present"
check_contains "$CLAUDE_FILE" "Use \`${CLAUDE_HOME}/super-stack/AGENTS.md\` as the shared global workflow source." "Claude global routing points to super-stack"
printf 'Claude mirrored skills: %s\n' "$(count_skill_entries "$CLAUDE_SKILLS_DIR")"
printf '\n'

printf '== Strategy ==\n'
check_contains "$CODEX_AGENTS_FILE" "Prefer project-local \`AGENTS.md\` and \`.codex/AGENTS.md\` when a repository provides them." "Codex uses global-first with project overrides"
check_contains "$CLAUDE_FILE" "Prefer project-local \`AGENTS.md\`, \`.claude/CLAUDE.md\`, and project-local skills when a repository provides them." "Claude uses global-first with project overrides"
printf '\n'

if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'RESULT: PASS\n'
  printf 'super-stack global-first install looks healthy.\n'
else
  printf 'RESULT: WARN (%s issue(s))\n' "$WARNINGS"
  printf 'Review the warnings above. Re-run ./scripts/install.sh --host all --mode global if needed.\n'
fi

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

check_exact_content() {
  local path="$1"
  local expected="$2"
  local label="$3"

  if [[ ! -f "$path" ]]; then
    warn "${label}: file missing (${path})"
    return
  fi

  local actual
  actual="$(cat "$path")"

  if [[ "$actual" == "$expected" ]]; then
    ok "${label}"
  else
    warn "${label}: content does not match expected"
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

EXPECTED_CODEX_AGENTS=$(cat <<EOF
# Super Stack Global Router

Use \`${CODEX_HOME}/super-stack/AGENTS.md\` as the global workflow source.

- This is the default global workflow router for Codex.
- Prefer project-local \`AGENTS.md\` and \`.codex/AGENTS.md\` when a repository provides them.
- Global super-stack skills are installed to \`${USER_SKILLS_DIR}\`.
- Legacy compatibility mirrors are also installed to \`${CODEX_SKILLS_DIR}\`.
- Treat global super-stack as the default system, and project-level files only as thin overrides.
EOF
)

EXPECTED_CLAUDE_ROUTER=$(cat <<EOF
# Super Stack Global Router

Use \`${CLAUDE_HOME}/super-stack/AGENTS.md\` as the shared global workflow source.

- This is the default global workflow router for Claude.
- Prefer project-local \`AGENTS.md\`, \`.claude/CLAUDE.md\`, and project-local skills when a repository provides them.
- Global Claude-facing skills are mirrored into \`${CLAUDE_SKILLS_DIR}\`.
- Treat global super-stack as the default system, and project-level files only as thin overrides.
EOF
)

printf '== Codex ==\n'
check_file "$CODEX_STACK_AGENTS" "Codex shared stack AGENTS"
check_file "$CODEX_AGENTS_FILE" "Codex global AGENTS"
check_file "$CODEX_CONFIG_FILE" "Codex config"
check_dir "$USER_SKILLS_DIR" "User skills directory"
check_dir "$CODEX_SKILLS_DIR" "Codex legacy skills directory"
check_exact_content "$CODEX_AGENTS_FILE" "$EXPECTED_CODEX_AGENTS" "Codex global router content matches expected"
printf 'Codex user-visible skills: %s\n' "$(count_skill_entries "$USER_SKILLS_DIR")"
printf 'Codex legacy mirrored skills: %s\n' "$(count_skill_entries "$CODEX_SKILLS_DIR")"
printf '\n'

printf '== Claude ==\n'
check_file "$CLAUDE_STACK_AGENTS" "Claude shared stack AGENTS"
check_file "$CLAUDE_FILE" "Claude global CLAUDE.md"
check_dir "$CLAUDE_SKILLS_DIR" "Claude global skills directory"
check_exact_content "$CLAUDE_FILE" "$EXPECTED_CLAUDE_ROUTER" "Claude global router content matches expected"
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

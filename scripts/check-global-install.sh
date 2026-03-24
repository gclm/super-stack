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
CLAUDE_SETTINGS_FILE="${CLAUDE_HOME}/settings.json"
REPO_AGENTS_FILE="${REPO_ROOT}/AGENTS.md"
REPO_SKILLS_DIR="${REPO_ROOT}/.agents/skills"

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

check_same_content() {
  local actual_path="$1"
  local expected_path="$2"
  local label="$3"

  if [[ ! -f "$actual_path" ]]; then
    warn "${label}: file missing (${actual_path})"
    return
  fi

  if [[ ! -f "$expected_path" ]]; then
    warn "${label}: expected file missing (${expected_path})"
    return
  fi

  if cmp -s "$actual_path" "$expected_path"; then
    ok "${label}"
  else
    warn "${label}: content differs from ${expected_path}"
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

count_expected_skill_names() {
  find "${REPO_SKILLS_DIR}" -maxdepth 2 -mindepth 2 -type d | wc -l | tr -d ' '
}

count_matching_skill_names() {
  local dest_root="$1"
  local count=0
  local skill_dir

  if [[ ! -d "$dest_root" ]]; then
    printf '0'
    return
  fi

  while IFS= read -r skill_dir; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    if [[ -f "${dest_root}/${skill_name}/SKILL.md" ]]; then
      count=$((count + 1))
    fi
  done < <(find "${REPO_SKILLS_DIR}" -maxdepth 2 -mindepth 2 -type d | sort)

  printf '%s' "$count"
}

printf '== super-stack global install check ==\n'
printf 'repo: %s\n' "${REPO_ROOT}"
printf 'home: %s\n' "${HOME}"
printf '\n'

EXPECTED_SKILL_COUNT="$(count_expected_skill_names)"

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
check_same_content "$CODEX_STACK_AGENTS" "$REPO_AGENTS_FILE" "Codex shared stack AGENTS matches repo"
check_exact_content "$CODEX_AGENTS_FILE" "$EXPECTED_CODEX_AGENTS" "Codex global router content matches expected"
check_contains "$CODEX_CONFIG_FILE" "super_stack_state.py" "Codex hooks merged"
check_contains "$CODEX_CONFIG_FILE" "readonly_command_guard.py" "Codex readonly auto-allow hook merged"
printf 'Codex user-visible skills (all): %s\n' "$(count_skill_entries "$USER_SKILLS_DIR")"
printf 'Codex legacy mirrored skills (all): %s\n' "$(count_skill_entries "$CODEX_SKILLS_DIR")"
printf 'Codex managed skill matches: %s/%s\n' "$(count_matching_skill_names "$USER_SKILLS_DIR")" "$EXPECTED_SKILL_COUNT"
printf '\n'

printf '== Claude ==\n'
check_file "$CLAUDE_STACK_AGENTS" "Claude shared stack AGENTS"
check_file "$CLAUDE_FILE" "Claude global CLAUDE.md"
check_dir "$CLAUDE_SKILLS_DIR" "Claude global skills directory"
check_file "$CLAUDE_SETTINGS_FILE" "Claude settings"
check_same_content "$CLAUDE_STACK_AGENTS" "$REPO_AGENTS_FILE" "Claude shared stack AGENTS matches repo"
check_exact_content "$CLAUDE_FILE" "$EXPECTED_CLAUDE_ROUTER" "Claude global router content matches expected"
check_contains "$CLAUDE_SETTINGS_FILE" "[super-stack] resuming from .planning/STATE.md" "Claude SessionStart hook merged"
check_contains "$CLAUDE_SETTINGS_FILE" "readonly_command_guard.py" "Claude readonly auto-allow hook merged"
check_contains "$CLAUDE_SETTINGS_FILE" "[super-stack] remember to leave STATE.md current" "Claude Stop hook merged"
printf 'Claude mirrored skills (all): %s\n' "$(count_skill_entries "$CLAUDE_SKILLS_DIR")"
printf 'Claude managed skill matches: %s/%s\n' "$(count_matching_skill_names "$CLAUDE_SKILLS_DIR")" "$EXPECTED_SKILL_COUNT"
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

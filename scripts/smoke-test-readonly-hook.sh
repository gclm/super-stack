#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

HOOK_SCRIPT="${REPO_ROOT}/scripts/hooks/readonly_command_guard.py"
WORKDIR="${HOME}/tmp/super-stack-readonly-hook-$(date +%s)"
WARNINGS=0

ok() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

run_case() {
  local label="$1"
  local host="$2"
  local tool_name="$3"
  local command="$4"
  local expected="$5"
  local output

  output="$(printf '%s' "{\"tool_name\":\"${tool_name}\",\"tool_input\":{\"command\":\"${command}\"},\"cwd\":\"${WORKDIR}\",\"hook_event_name\":\"PreToolUse\"}" \
    | python3 "$HOOK_SCRIPT" --host "$host")"

  case "$expected" in
    allow)
      if printf '%s' "$output" | rg -q '"permissionDecision": ?"allow"'; then
        ok "${label}: allow"
      else
        warn "${label}: expected allow"
        printf '%s\n' "$output"
      fi
      ;;
    pass)
      if [[ "$output" == "{}" ]]; then
        ok "${label}: pass-through"
      else
        warn "${label}: expected pass-through"
        printf '%s\n' "$output"
      fi
      ;;
  esac
}

ensure_dir "$WORKDIR/.planning"
rm -f "$WORKDIR/.planning/.super-stack-readonly-hook.log"

printf '== super-stack readonly hook smoke test ==\n'
printf 'hook: %s\n' "$HOOK_SCRIPT"
printf 'workdir: %s\n' "$WORKDIR"
printf '\n'

run_case "claude-git-status" "claude" "Bash" "git status" "allow"
run_case "claude-pipeline" "claude" "Bash" "git status | head -5" "allow"
run_case "claude-redirect-write" "claude" "Bash" "git status > /tmp/out.txt" "pass"
run_case "codex-rg" "codex" "shell" "pwd && rg TODO README.md" "allow"
run_case "codex-rm" "codex" "shell" "rm -rf tmp-build" "pass"

if [[ -f "$WORKDIR/.planning/.super-stack-readonly-hook.log" ]]; then
  ok "readonly-hook-log: created"
else
  warn "readonly-hook-log: missing"
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'RESULT: PASS\n'
  printf 'Readonly auto-allow hook smoke test passed.\n'
else
  printf 'RESULT: WARN (%s issue(s))\n' "$WARNINGS"
  printf 'Inspect scripts/hooks/readonly_command_guard.py and hook wiring.\n'
fi

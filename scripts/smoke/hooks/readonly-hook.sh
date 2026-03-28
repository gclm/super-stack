#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

HOOK_SCRIPT="${REPO_ROOT}/scripts/hooks/readonly_command_guard.py"
WORKDIR="${HOME}/tmp/super-stack-readonly-hook-$(date +%s)"
WARNINGS=0

ok() {
  printf '[通过] %s\n' "$*"
}

warn() {
  printf '[警告] %s\n' "$*"
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
        warn "${label}: 预期 allow"
        printf '%s\n' "$output"
      fi
      ;;
    pass)
      if [[ "$output" == "{}" ]]; then
        ok "${label}: pass-through"
      else
        warn "${label}: 预期 pass-through"
        printf '%s\n' "$output"
      fi
      ;;
    deny)
      if printf '%s' "$output" | rg -q '"permissionDecision": ?"deny"'; then
        ok "${label}: deny"
      else
        warn "${label}: 预期 deny"
        printf '%s\n' "$output"
      fi
      ;;
  esac
}

run_classify_case() {
  local label="$1"
  local command="$2"
  local expected_verdict="$3"
  local expected_risk="$4"
  local output

  output="$(python3 "$HOOK_SCRIPT" --host codex --classify "$command")"

  if printf '%s' "$output" | rg -q "\"verdict\": ?\"${expected_verdict}\"" \
    && printf '%s' "$output" | rg -q "\"riskLevel\": ?\"${expected_risk}\""; then
    ok "${label}: ${expected_verdict}/${expected_risk}"
  else
    warn "${label}: 预期 ${expected_verdict}/${expected_risk}"
    printf '%s\n' "$output"
  fi
}

ensure_dir "$WORKDIR/.planning"
rm -f "$WORKDIR/.planning/.super-stack-readonly-hook.log"

printf '== super-stack 只读 hook 冒烟测试 ==\n'
printf 'hook 脚本: %s\n' "$HOOK_SCRIPT"
printf '工作目录: %s\n' "$WORKDIR"
printf '\n'

run_case "claude-git-status" "claude" "Bash" "git status" "allow"
run_case "claude-pipeline" "claude" "Bash" "git status | head -5" "allow"
run_case "claude-redirect-write" "claude" "Bash" "git status > /tmp/out.txt" "pass"
run_case "codex-rg" "codex" "shell" "pwd && rg TODO README.md" "allow"
run_case "codex-rm" "codex" "shell" "rm -rf tmp-build" "deny"
run_classify_case "classify-allow" "pwd" "allow" "low"
run_classify_case "classify-ask" "mkdir tmp-build" "ask" "medium"
run_classify_case "classify-deny" "git reset --hard" "deny" "high"

if [[ -f "$WORKDIR/.planning/.super-stack-readonly-hook.log" ]]; then
  ok "readonly-hook-log: 已创建"
else
  warn "readonly-hook-log: 缺失"
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf '结果：通过\n'
  printf '只读自动放行 hook 冒烟测试通过。\n'
else
  printf '结果：警告（%s 个问题）\n' "$WARNINGS"
  printf '请检查 scripts/hooks/readonly_command_guard.py 与 hook 接线。\n'
fi

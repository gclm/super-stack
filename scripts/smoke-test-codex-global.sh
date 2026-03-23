#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CODEX_BIN="${CODEX_BIN:-${HOME}/.local/bin/codex}"
WORKDIR_BASE="${HOME}/tmp/super-stack-smoke-test"
WARNINGS=0

ok() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

run_case() {
  local stage="$1"
  local prompt="$2"
  local output

  output="$(cd "$WORKDIR" && "$CODEX_BIN" exec --skip-git-repo-check \
    "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit stage for this request and reply with exactly one line in the format STAGE=<name>: ${prompt}" \
    2>&1 || true)"

  if printf '%s' "$output" | rg -q "STAGE=${stage}"; then
    ok "${stage}: matched"
  else
    warn "${stage}: expected STAGE=${stage}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

if [[ ! -x "$CODEX_BIN" ]]; then
  die "Codex binary not found or not executable: ${CODEX_BIN}"
fi

WORKDIR="${WORKDIR_BASE}-$(date +%s)"
ensure_dir "$WORKDIR"

printf '== super-stack codex global smoke test ==\n'
printf 'codex: %s\n' "$CODEX_BIN"
printf 'workdir: %s\n' "$WORKDIR"
printf '\n'

run_case "discuss" "我想先把需求范围、约束和成功标准梳理清楚，再决定下一步。"
run_case "brainstorm" "这个功能有两三种实现路线，我想先比较方案、权衡取舍，再决定采用哪一个。"
run_case "review" "代码已经差不多写完了，请你重点检查正确性、回归风险和缺失测试。"
run_case "verify" "改动我觉得做完了，但请先根据最新证据确认它是否真的达成目标，再决定能不能宣称完成。"

visibility_output="$(cd "$WORKDIR" && "$CODEX_BIN" exec --skip-git-repo-check \
  "Do not read any repository-specific files. First list the available globally visible skills in this session. Then reply with exactly one line: GLOBAL-SUPPORT-SKILLS-OK if you can see debug, tdd-execution, release-check, frontend-refactor, bugfix-verification, and api-change-check." \
  2>&1 || true)"

if printf '%s' "$visibility_output" | rg -q "GLOBAL-SUPPORT-SKILLS-OK"; then
  ok "supporting skills: visible"
else
  warn "supporting skills: expected all support skills to be visible"
  printf '%s\n' "$visibility_output" | sed -n '1,160p'
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'RESULT: PASS\n'
  printf 'Codex global super-stack routing smoke test passed.\n'
else
  printf 'RESULT: WARN (%s issue(s))\n' "$WARNINGS"
  printf 'Global routing drift may exist. Re-run ./scripts/check-global-install.sh and inspect ~/.codex/AGENTS.md plus ~/.agents/skills.\n'
fi

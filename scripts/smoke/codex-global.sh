#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CODEX_BIN="$(resolve_codex_bin || true)"
WORKDIR_BASE="${HOME}/tmp/super-stack-smoke-test"
WARNINGS=0

ok() {
  printf '[通过] %s\n' "$*"
}

warn() {
  printf '[警告] %s\n' "$*"
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
    ok "${stage}: 匹配成功"
  else
    warn "${stage}: 预期 STAGE=${stage}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

if [[ -z "$CODEX_BIN" || ! -x "$CODEX_BIN" ]]; then
  die "未找到 Codex 二进制，或其不可执行：${CODEX_BIN}"
fi

WORKDIR="${WORKDIR_BASE}-$(date +%s)"
ensure_dir "$WORKDIR"

printf '== super-stack Codex 全局冒烟测试 ==\n'
printf 'codex: %s\n' "$CODEX_BIN"
printf '工作目录: %s\n' "$WORKDIR"
printf '\n'

run_case "discuss" "我想先把需求范围、约束和成功标准梳理清楚，再决定下一步。"
run_case "brainstorm" "这个功能有两三种实现路线，我想先比较方案、权衡取舍，再决定采用哪一个。"
run_case "review" "代码已经差不多写完了，请你重点检查正确性、回归风险和缺失测试。"
run_case "verify" "改动我觉得做完了，但请先根据最新证据确认它是否真的达成目标，再决定能不能宣称完成。"

visibility_output="$(cd "$WORKDIR" && "$CODEX_BIN" exec --skip-git-repo-check \
  "Do not read any repository-specific files. First list the available globally visible skills in this session. Then reply with exactly one line: GLOBAL-SUPPORT-SKILLS-OK if you can see debug, tdd-execution, release-check, frontend-refactor, bugfix-verification, api-change-check, database-design, api-design, architecture-design, migration-design, query-optimization, backend-refactor, integration-design, service-boundary-review, scalability-check, observability-design, incident-debug, security-review, performance-investigation, and browse." \
  2>&1 || true)"

if printf '%s' "$visibility_output" | rg -q "GLOBAL-SUPPORT-SKILLS-OK"; then
  ok "supporting skills: 可见"
else
  warn "supporting skills: 预期所有 supporting skills 都可见"
  printf '%s\n' "$visibility_output" | sed -n '1,160p'
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf '结果：通过\n'
  printf 'Codex 全局 super-stack 路由冒烟测试通过。\n'
else
  printf '结果：警告（%s 个问题）\n' "$WARNINGS"
  printf '全局路由可能发生漂移。请重新执行 ./scripts/check/check-global-install.sh，并检查 ~/.codex/AGENTS.md 与 ~/.agents/skills。\n'
fi

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CODEX_BIN="$(resolve_codex_bin || true)"
WORKDIR_BASE="${HOME}/tmp/super-stack-regression-suite"
WARNINGS=0

ok() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

run_stage_case() {
  local label="$1"
  local expected="$2"
  local prompt="$3"
  local output

  output="$(cd "$WORKDIR" && "$CODEX_BIN" exec --skip-git-repo-check \
    "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit stage for this request and reply with exactly one line in the format STAGE=<name>: ${prompt}" \
    2>&1 || true)"

  if printf '%s' "$output" | rg -q "STAGE=${expected}"; then
    ok "${label}: matched ${expected}"
  else
    warn "${label}: expected STAGE=${expected}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

run_skill_case() {
  local label="$1"
  local expected="$2"
  local prompt="$3"
  local output

  output="$(cd "$WORKDIR" && "$CODEX_BIN" exec --skip-git-repo-check \
    "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit supporting skill for this request and reply with exactly one line in the format SKILL=<name>: ${prompt}" \
    2>&1 || true)"

  if printf '%s' "$output" | rg -q "SKILL=${expected}"; then
    ok "${label}: matched ${expected}"
  else
    warn "${label}: expected SKILL=${expected}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

if [[ -z "$CODEX_BIN" || ! -x "$CODEX_BIN" ]]; then
  die "Codex binary not found or not executable: ${CODEX_BIN}"
fi

WORKDIR="${WORKDIR_BASE}-$(date +%s)"
ensure_dir "$WORKDIR"
ensure_dir "$WORKDIR/.planning"
cat > "$WORKDIR/.planning/STATE.md" <<'EOF'
# STATE

- current focus: codex hook regression
EOF
rm -f "$WORKDIR/.planning/.super-stack-codex-hooks.log"

printf '== super-stack codex regression suite ==\n'
printf 'codex: %s\n' "$CODEX_BIN"
printf 'workdir: %s\n' "$WORKDIR"
printf '\n'

run_stage_case "discuss-scope-mode" "discuss" "这个项目现在更像技能验证样本，不是立刻做产品。先帮我把范围、非目标、文档语言和提交规范梳理清楚。"
run_stage_case "brainstorm-reference-boundary" "brainstorm" "我想参考一个旧项目的前端，但不确定应该复用信息架构还是直接复用实现，先比较两三种路线。"
run_stage_case "map-codebase-runtime-footprint" "map-codebase" "这是一个陌生仓库，而且我怀疑它的关键线索还在本机运行目录、日志和 launch agents 里，先给我做结构扫描。"
run_stage_case "build-environment-preflight" "build" "任务已经明确了，请直接实现，但先检查当前 shell、node、cargo 和默认运行入口是不是可用。"
run_stage_case "review-entrypoint-regression" "review" "这次改动新增了一个调试二进制，我需要你重点检查默认运行入口和 dev 路径有没有被破坏。"
run_stage_case "verify-scope-alignment" "verify" "改动我觉得完成了，但请先确认它是否仍然是验证样本范围，而不是已经悄悄变成产品开发。"
run_stage_case "qa-runtime-hygiene" "qa" "请做一轮质量验证，除了功能外，也检查启动链、工具链 warning 和本地运行态噪音。"

run_skill_case "frontend-refactor-boundary" "frontend-refactor" "这个前端需要重构，但我要保留参考项目的信息架构，不要默认直接复制它的实现。"
run_skill_case "debug-environment-vs-code" "debug" "现在程序启动失败，我不确定是代码 bug、shell 初始化问题，还是默认运行入口坏了，先帮我定位。"

if [[ -f "$WORKDIR/.planning/.super-stack-codex-hooks.log" ]] && \
  rg -q "sessionstart" "$WORKDIR/.planning/.super-stack-codex-hooks.log" && \
  rg -q "stop" "$WORKDIR/.planning/.super-stack-codex-hooks.log"; then
  ok "codex-hooks: SessionStart and Stop observed"
else
  warn "codex-hooks: expected SessionStart and Stop in .planning/.super-stack-codex-hooks.log"
  if [[ -f "$WORKDIR/.planning/.super-stack-codex-hooks.log" ]]; then
    sed -n '1,120p' "$WORKDIR/.planning/.super-stack-codex-hooks.log"
  fi
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'RESULT: PASS\n'
  printf 'Codex regression suite passed.\n'
else
  printf 'RESULT: WARN (%s issue(s))\n' "$WARNINGS"
  printf 'Regression drift may exist. Inspect AGENTS routing, updated skill text, and global install state.\n'
fi

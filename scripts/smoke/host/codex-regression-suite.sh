#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

CODEX_BIN="$(resolve_codex_bin || true)"
WORKDIR_BASE="${HOME}/tmp/super-stack-regression-suite"
WARNINGS=0

ok() {
  printf '[通过] %s\n' "$*"
}

warn() {
  printf '[警告] %s\n' "$*"
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
    ok "${label}: 匹配 ${expected}"
  else
    warn "${label}: 预期 STAGE=${expected}"
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
    ok "${label}: 匹配 ${expected}"
  else
    warn "${label}: 预期 SKILL=${expected}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

if [[ -z "$CODEX_BIN" || ! -x "$CODEX_BIN" ]]; then
  die "未找到 Codex 二进制，或其不可执行：${CODEX_BIN}"
fi

WORKDIR="${WORKDIR_BASE}-$(date +%s)"
ensure_dir "$WORKDIR"
ensure_dir "$WORKDIR/harness"
cat > "$WORKDIR/harness/state.md" <<'EOF'
# STATE

- current focus: codex hook regression
EOF
rm -f "$WORKDIR/harness/.runtime/super-stack-codex-hooks.log"

printf '== super-stack Codex 回归套件 ==\n'
printf 'codex: %s\n' "$CODEX_BIN"
printf '工作目录: %s\n' "$WORKDIR"
printf '\n'

run_stage_case "discuss-scope-mode" "discuss" "这个项目现在更像技能验证样本，不是立刻做产品。先帮我把范围、非目标、文档语言和提交规范梳理清楚。"
run_stage_case "brainstorm-reference-boundary" "brainstorm" "我想参考一个旧项目的前端，但不确定应该复用信息架构还是直接复用实现，先比较两三种路线。"
run_stage_case "map-codebase-runtime-footprint" "map-codebase" "这是一个陌生仓库。不要先做需求澄清，也不要先规划实现路线。请直接为我建立代码库地图，重点覆盖 stack、目录结构、架构边界、集成、测试布局，以及仓库外的运行时线索，例如本机日志、launch agents 和本地配置。"
run_stage_case "build-environment-preflight" "build" "任务已经明确了，请直接实现，但先检查当前 shell、node、cargo 和默认运行入口是不是可用。"
run_stage_case "review-entrypoint-regression" "review" "这次改动新增了一个调试二进制，我需要你重点检查默认运行入口和 dev 路径有没有被破坏。"
run_stage_case "verify-scope-alignment" "verify" "先不要做发布检查，也不要评估上线准备度。请只根据最新证据确认这次改动是否真的达成目标，并检查范围有没有从验证样本悄悄漂移成产品开发。"
run_stage_case "qa-runtime-hygiene" "qa" "请做一轮质量验证，除了功能外，也检查启动链、工具链 warning 和本地运行态噪音。"

run_skill_case "frontend-refactor-boundary" "frontend-refactor" "这个前端需要重构，但我要保留参考项目的信息架构，不要默认直接复制它的实现。"
run_skill_case "debug-environment-vs-code" "debug" "现在程序启动失败，我不确定是代码 bug、shell 初始化问题，还是默认运行入口坏了，先帮我定位。"

if [[ -f "$WORKDIR/harness/.runtime/super-stack-codex-hooks.log" ]] && \
  rg -q "sessionstart" "$WORKDIR/harness/.runtime/super-stack-codex-hooks.log" && \
  rg -q "stop" "$WORKDIR/harness/.runtime/super-stack-codex-hooks.log"; then
  ok "codex-hooks: 已观察到 SessionStart 和 Stop"
else
  warn "codex-hooks: 预期在 harness/.runtime/super-stack-codex-hooks.log 中看到 SessionStart 和 Stop"
  if [[ -f "$WORKDIR/harness/.runtime/super-stack-codex-hooks.log" ]]; then
    sed -n '1,120p' "$WORKDIR/harness/.runtime/super-stack-codex-hooks.log"
  fi
fi

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf '结果：通过\n'
  printf 'Codex 回归套件通过。\n'
else
  printf '结果：警告（%s 个问题）\n' "$WARNINGS"
  printf '回归可能发生漂移。请检查 AGENTS 路由、更新后的 skill 文本和全局安装状态。\n'
fi

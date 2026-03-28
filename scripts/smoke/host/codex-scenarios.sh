#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CODEX_BIN="$(resolve_codex_bin || true)"
WORKDIR_BASE="${HOME}/tmp/super-stack-scenario-test"
WARNINGS=0

ok() {
  printf '[通过] %s\n' "$*"
}

warn() {
  printf '[警告] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
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

printf '== super-stack Codex 场景冒烟测试 ==\n'
printf 'codex: %s\n' "$CODEX_BIN"
printf '工作目录: %s\n' "$WORKDIR"
printf '\n'

run_skill_case "browse" "browse" "这个页面在点击保存后按钮状态不对，我需要你去浏览器里看 DOM、console 和 network 到底发生了什么。"
run_skill_case "security" "security-review" "请审查这次登录和文件上传改动，重点看鉴权、权限绕过、数据泄露和潜在 SSRF 风险。"
run_skill_case "incident" "incident-debug" "线上刚出现大面积 500 和队列积压，我需要先判断影响范围、能否回滚以及下一步最安全的处置动作。"
run_skill_case "performance" "performance-investigation" "这个接口最近延迟暴涨，但我还不知道是 CPU、数据库还是网络问题，先帮我做性能调查。"

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf '结果：通过\n'
  printf 'Codex 场景 skill 路由冒烟测试通过。\n'
else
  printf '结果：警告（%s 个问题）\n' "$WARNINGS"
  printf '场景路由可能发生漂移。请检查全局 skills 与 AGENTS 路由。\n'
fi

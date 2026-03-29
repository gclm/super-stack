#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

CLAUDE_BIN="$(resolve_claude_bin || true)"
WORKDIR_BASE="${HOME}/tmp/super-stack-claude-smoke-test"
WARNINGS=0

ok() {
  printf '[通过] %s\n' "$*"
}

warn() {
  printf '[警告] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

run_prompt() {
  local prompt="$1"
  local debug_file="${2:-}"

  if [[ -n "$debug_file" ]]; then
    printf '%s' "$prompt" | "$CLAUDE_BIN" -p \
      --permission-mode bypassPermissions \
      --allowedTools Read \
      --debug hooks \
      --debug-file "$debug_file"
    return
  fi

  printf '%s' "$prompt" | "$CLAUDE_BIN" -p \
    --permission-mode bypassPermissions \
    --allowedTools Read
}

run_stage_case() {
  local label="$1"
  local expected="$2"
  local alternate="${3:-}"
  local prompt="$4"
  local output

  output="$(cd "$WORKDIR" && run_prompt "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit stage for this request and reply with exactly one line in the format STAGE=<name>: ${prompt}" 2>&1 || true)"

  if printf '%s' "$output" | rg -q "STAGE=${expected}" || { [[ -n "$alternate" ]] && printf '%s' "$output" | rg -q "STAGE=${alternate}"; }; then
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

  output="$(cd "$WORKDIR" && run_prompt "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit supporting skill for this request and reply with exactly one line in the format SKILL=<name>: ${prompt}" 2>&1 || true)"

  if printf '%s' "$output" | rg -q "SKILL=${expected}"; then
    ok "${label}: 匹配 ${expected}"
  else
    warn "${label}: 预期 SKILL=${expected}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

check_browser_capability() {
  local result

  result="$("${SCRIPT_DIR}/../check/check-browser-capability.sh")"

  case "$(printf '%s' "$result" | sed -n '1p')" in
    ACTIVE_LOCAL)
      ok "Claude 浏览器能力：本地 provider 已激活（$(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g'))"
      ;;
    ACTIVE_MCP)
      ok "Claude 浏览器能力：MCP provider 已激活（$(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g'))"
      ;;
    ACTIVE_PLUGIN)
      ok "Claude 浏览器能力：browser plugin 已激活（$(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g'))"
      ;;
    INSTALLED_ONLY)
      warn "Claude 浏览器能力：browser plugin 已安装但未启用（$(printf '%s' "$result" | sed -n '2p'))"
      ;;
    *)
      warn "Claude 浏览器能力：未检测到已激活的 browser MCP 或 browser plugin"
      ;;
  esac
}

if [[ -z "$CLAUDE_BIN" || ! -x "$CLAUDE_BIN" ]]; then
  die "未找到 Claude 二进制，或其不可执行：${CLAUDE_BIN}"
fi

WORKDIR="${WORKDIR_BASE}-$(date +%s)"
DEBUG_FILE="$(mktemp)"
ensure_dir "$WORKDIR/harness"
cat > "$WORKDIR/harness/state.md" <<'EOF'
# STATE

- current focus: smoke-test Claude global hooks
EOF

printf '== super-stack Claude 全局冒烟测试 ==\n'
printf 'claude: %s\n' "$CLAUDE_BIN"
printf '工作目录: %s\n' "$WORKDIR"
printf '\n'

hook_output="$(cd "$WORKDIR" && run_prompt "Reply with exactly HOOK-SMOKE" "$DEBUG_FILE" 2>&1 || true)"
if printf '%s' "$hook_output" | rg -q '^HOOK-SMOKE$'; then
  ok "Claude print 模式：基础 prompt 执行成功"
else
  warn "Claude print 模式：预期输出 HOOK-SMOKE"
  printf '%s\n' "$hook_output" | sed -n '1,120p'
fi

if rg -q "Loading skills from: .*user=${HOME}/.claude/skills" "$DEBUG_FILE"; then
  ok "Claude 全局 skills 路径已加载"
else
  warn "Claude 调试日志中未观察到全局 skills 路径"
fi

if rg -q "\\[super-stack\\] resuming from harness/state.md" "$DEBUG_FILE"; then
  ok "Claude SessionStart hook 已触发"
else
  warn "未观察到 Claude SessionStart hook 输出"
fi

if rg -q "remember to leave harness/state.md current" "$DEBUG_FILE"; then
  ok "Claude Stop hook 已触发"
else
  warn "未观察到 Claude Stop hook 输出"
fi

run_stage_case "discuss-stage" "discuss" "" "我想先把需求范围、约束和成功标准梳理清楚，再决定下一步。"
run_stage_case "review-stage" "review" "code-review" "代码已经差不多写完了，请你重点检查正确性、回归风险和缺失测试。"
run_stage_case "verify-stage" "verify" "" "改动我觉得做完了，但请先根据最新证据确认它是否真的达成目标，再决定能不能宣称完成。"
run_skill_case "browse-skill" "browse" "这个页面点击保存后按钮状态异常，我需要你去浏览器里看 DOM、console 和 network 到底发生了什么。"

check_browser_capability

rm -f "$DEBUG_FILE"

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf '结果：通过\n'
  printf 'Claude 全局 super-stack 冒烟测试通过。\n'
else
  printf '结果：警告（%s 个问题）\n' "$WARNINGS"
  printf '如需完整 UI 级验证，请检查 ~/.claude/settings.json、~/.claude/skills 和浏览器能力接线。\n'
fi

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

CLAUDE_BIN="$(resolve_claude_bin || true)"
WORKDIR_BASE="${HOME}/tmp/super-stack-claude-smoke-test"
WARNINGS=0

ok() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
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
  local prompt="$3"
  local output

  output="$(cd "$WORKDIR" && run_prompt "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit stage for this request and reply with exactly one line in the format STAGE=<name>: ${prompt}" 2>&1 || true)"

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

  output="$(cd "$WORKDIR" && run_prompt "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit supporting skill for this request and reply with exactly one line in the format SKILL=<name>: ${prompt}" 2>&1 || true)"

  if printf '%s' "$output" | rg -q "SKILL=${expected}"; then
    ok "${label}: matched ${expected}"
  else
    warn "${label}: expected SKILL=${expected}"
    printf '%s\n' "$output" | sed -n '1,120p'
  fi
}

check_browser_capability() {
  local result

  result="$(python3 - <<'PY'
import json
from pathlib import Path

home = Path.home() / ".claude"
settings_path = home / "settings.json"
installed_path = home / "plugins" / "installed_plugins.json"

enabled = set()
installed = set()
mcp_names = set()

if settings_path.exists():
    settings = json.loads(settings_path.read_text())
    enabled_plugins = settings.get("enabledPlugins", {})
    if isinstance(enabled_plugins, dict):
        enabled = {name for name, value in enabled_plugins.items() if value}
    mcp_servers = settings.get("mcpServers", {})
    if isinstance(mcp_servers, dict):
        mcp_names = set(mcp_servers.keys())

if installed_path.exists():
    installed_data = json.loads(installed_path.read_text())
    plugins = installed_data.get("plugins", {})
    if isinstance(plugins, dict):
        installed = set(plugins.keys())

active_browser_plugins = sorted(name for name in enabled if any(token in name.lower() for token in ("browser", "playwright", "chrome")))
installed_browser_plugins = sorted(name for name in installed if any(token in name.lower() for token in ("browser", "playwright", "chrome")))
active_mcp = sorted(name for name in mcp_names if any(token in name.lower() for token in ("browser", "playwright", "chrome")))

if active_browser_plugins or active_mcp:
    print("ACTIVE")
    print("plugins=" + ",".join(active_browser_plugins))
    print("mcps=" + ",".join(active_mcp))
elif installed_browser_plugins:
    print("INSTALLED_ONLY")
    print("plugins=" + ",".join(installed_browser_plugins))
else:
    print("MISSING")
PY
)"

  case "$(printf '%s' "$result" | sed -n '1p')" in
    ACTIVE)
      ok "Claude browser capability: active ($(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g'))"
      ;;
    INSTALLED_ONLY)
      warn "Claude browser capability: browser plugin installed but not enabled ($(printf '%s' "$result" | sed -n '2p'))"
      ;;
    *)
      warn "Claude browser capability: no active browser plugin or browser MCP detected"
      ;;
  esac
}

if [[ -z "$CLAUDE_BIN" || ! -x "$CLAUDE_BIN" ]]; then
  die "Claude binary not found or not executable: ${CLAUDE_BIN}"
fi

WORKDIR="${WORKDIR_BASE}-$(date +%s)"
DEBUG_FILE="$(mktemp)"
ensure_dir "$WORKDIR/.planning"
cat > "$WORKDIR/.planning/STATE.md" <<'EOF'
# STATE

- current focus: smoke-test Claude global hooks
EOF

printf '== super-stack claude global smoke test ==\n'
printf 'claude: %s\n' "$CLAUDE_BIN"
printf 'workdir: %s\n' "$WORKDIR"
printf '\n'

hook_output="$(cd "$WORKDIR" && run_prompt "Reply with exactly HOOK-SMOKE" "$DEBUG_FILE" 2>&1 || true)"
if printf '%s' "$hook_output" | rg -q '^HOOK-SMOKE$'; then
  ok "Claude print mode: basic prompt succeeded"
else
  warn "Claude print mode: expected HOOK-SMOKE"
  printf '%s\n' "$hook_output" | sed -n '1,120p'
fi

if rg -q "Loading skills from: .*user=${HOME}/.claude/skills" "$DEBUG_FILE"; then
  ok "Claude global skills path loaded"
else
  warn "Claude global skills path not observed in debug log"
fi

if rg -q "\\[super-stack\\] resuming from \\.planning/STATE.md" "$DEBUG_FILE"; then
  ok "Claude SessionStart hook fired"
else
  warn "Claude SessionStart hook output not observed"
fi

if rg -q "remember to leave STATE.md current" "$DEBUG_FILE"; then
  ok "Claude Stop hook fired"
else
  warn "Claude Stop hook output not observed"
fi

run_stage_case "discuss-stage" "discuss" "我想先把需求范围、约束和成功标准梳理清楚，再决定下一步。"
run_stage_case "review-stage" "review" "代码已经差不多写完了，请你重点检查正确性、回归风险和缺失测试。"
run_stage_case "verify-stage" "verify" "改动我觉得做完了，但请先根据最新证据确认它是否真的达成目标，再决定能不能宣称完成。"
run_skill_case "browse-skill" "browse" "这个页面点击保存后按钮状态异常，我需要你去浏览器里看 DOM、console 和 network 到底发生了什么。"

check_browser_capability

rm -f "$DEBUG_FILE"

printf '\n'
if [[ "$WARNINGS" -eq 0 ]]; then
  printf 'RESULT: PASS\n'
  printf 'Claude global super-stack smoke test passed.\n'
else
  printf 'RESULT: WARN (%s issue(s))\n' "$WARNINGS"
  printf 'Inspect ~/.claude/settings.json, ~/.claude/skills, and browser capability wiring if full UI verification is required.\n'
fi

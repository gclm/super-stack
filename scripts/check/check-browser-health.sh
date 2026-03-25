#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

BROWSER_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser"
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"
IDLE_TIMEOUT_MS="${AGENT_BROWSER_IDLE_TIMEOUT_MS:-${SUPER_STACK_BROWSER_IDLE_TIMEOUT_MS:-900000}}"

chrome_total_rss_kb="$(ps -axo rss=,command= | LC_ALL=C awk '/Google Chrome/ && !/awk/ {sum+=$1} END {print sum+0}')"
headless_count="$(ps -axo command= | LC_ALL=C awk '/Google Chrome/ && /--headless(=new)?/ && !/awk/ {count++} END {print count+0}')"
browser_use_count="$(ps -axo command= | LC_ALL=C awk '/browser_use|agent-browser-darwin/ && !/awk/ {count++} END {print count+0}')"
chrome_total_rss_mb="$((chrome_total_rss_kb / 1024))"

session_info="unavailable"
session_status="missing"
if [[ -x "${BROWSER_BIN}" ]]; then
  if session_output="$("${BROWSER_BIN}" session 2>/dev/null)"; then
    session_info="${session_output}"
    if printf '%s\n' "${session_output}" | grep -Fq "${SESSION_NAME}"; then
      session_status="active"
    else
      session_status="idle"
    fi
  fi
fi

printf 'BROWSER_BIN=%s\n' "${BROWSER_BIN}"
printf 'SESSION_NAME=%s\n' "${SESSION_NAME}"
printf 'SESSION_STATUS=%s\n' "${session_status}"
printf 'IDLE_TIMEOUT_MS=%s\n' "${IDLE_TIMEOUT_MS}"
printf 'HEADLESS_CHROME_COUNT=%s\n' "${headless_count}"
printf 'CHROME_TOTAL_RSS_MB=%s\n' "${chrome_total_rss_mb}"
printf 'BROWSER_USE_RESIDUE_COUNT=%s\n' "${browser_use_count}"

if [[ "${session_info}" != "unavailable" ]]; then
  printf 'SESSION_INFO=%s\n' "$(printf '%s' "${session_info}" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/ $//')"
fi

if (( browser_use_count > 0 )); then
  log "检测到 browser_use 或旧 agent-browser 残留。建议优先运行 ~/.super-stack/runtime/bin/super-stack-browser-reset 并确认旧链路已停止。"
fi

if (( headless_count > 1 )); then
  log "检测到多个 headless Chrome。若当前并未并发执行浏览器任务，建议运行 ~/.super-stack/runtime/bin/super-stack-browser-reset。"
fi

if (( chrome_total_rss_mb > 4096 )); then
  log "Chrome 总内存已超过 4GB。若近期任务已结束，建议运行 ~/.super-stack/runtime/bin/super-stack-browser-reset 以回收 renderer。"
fi

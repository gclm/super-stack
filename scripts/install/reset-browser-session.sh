#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

BROWSER_BIN="${HOME}/.claude-stack/bin/super-stack-browser"
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"

if [[ ! -x "${BROWSER_BIN}" ]]; then
  die "未找到稳定浏览器入口：${BROWSER_BIN}。请先运行 ./scripts/install/setup-browser.sh"
fi

log "正在重置稳定浏览器会话：${SESSION_NAME}"
"${BROWSER_BIN}" close >/dev/null 2>&1 || true
sleep 1
"${BROWSER_BIN}" session >/dev/null 2>&1 || true
log "稳定浏览器会话已重置完成"

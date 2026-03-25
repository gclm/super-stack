#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

BROWSER_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser"
HEALTH_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser-health"
RESET_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser-reset"

[[ -x "${BROWSER_BIN}" ]] || die "未找到稳定浏览器入口：${BROWSER_BIN}"
[[ -x "${HEALTH_BIN}" ]] || die "未找到浏览器健康检查入口：${HEALTH_BIN}"
[[ -x "${RESET_BIN}" ]] || die "未找到浏览器重置入口：${RESET_BIN}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

log "执行浏览器 preflight 健康检查"
"${HEALTH_BIN}" | tee "${TMP_DIR}/preflight.txt" >/dev/null

log "打开 about:blank 验证稳定浏览器入口"
"${BROWSER_BIN}" open "about:blank" >/dev/null
"${BROWSER_BIN}" wait 500 >/dev/null || true
LANDED_URL="$("${BROWSER_BIN}" get url)"
[[ "${LANDED_URL}" == "about:blank" ]] || die "稳定浏览器入口未落在 about:blank，实际为：${LANDED_URL}"

log "执行浏览器 postflight 健康检查"
"${HEALTH_BIN}" | tee "${TMP_DIR}/postflight.txt" >/dev/null

log "重置稳定浏览器会话"
"${RESET_BIN}" >/dev/null

log "浏览器生命周期 smoke 通过"

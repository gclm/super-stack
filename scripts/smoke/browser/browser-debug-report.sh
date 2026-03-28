#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

URL=""
OUTPUT=""
SELECTOR=""
NETWORK_FILTER=""
HINT=""
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"
BROWSER_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser"
HEALTH_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser-health"
RENDER_PY="${SCRIPT_DIR}/../browser/renderers/render_browser_debug_report.py"

usage() {
  cat <<'EOF'
用法：
  scripts/smoke/browser/browser-debug-report.sh --url URL [--selector CSS] [--network-filter PATTERN] [--hint TEXT] [--output PATH]

示例：
  bash scripts/smoke/browser/browser-debug-report.sh \
    --url "http://localhost:3000" \
    --selector "#app" \
    --network-filter "/api/" \
    --hint "首页白屏，怀疑接口或 hydration 异常" \
    --output artifacts/browser-debug-report.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    --selector)
      SELECTOR="${2:-}"
      shift 2
      ;;
    --network-filter)
      NETWORK_FILTER="${2:-}"
      shift 2
      ;;
    --hint)
      HINT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1"
      ;;
  esac
done

[[ -n "${URL}" ]] || die "必须提供 --url"
[[ -x "${BROWSER_BIN}" ]] || die "未找到稳定浏览器入口：${BROWSER_BIN}"
[[ -x "${HEALTH_BIN}" ]] || die "未找到浏览器健康检查入口：${HEALTH_BIN}"
[[ -f "${RENDER_PY}" ]] || die "未找到调试报告 renderer：${RENDER_PY}"

if [[ -z "${OUTPUT}" ]]; then
  ensure_dir "${REPO_ROOT}/artifacts"
  OUTPUT="${REPO_ROOT}/artifacts/browser-debug-report-$(date +%Y%m%d-%H%M%S).md"
else
  case "${OUTPUT}" in
    /*) ;;
    *) OUTPUT="${REPO_ROOT}/${OUTPUT}" ;;
  esac
  ensure_dir "$(dirname "${OUTPUT}")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

TITLE_TXT="${TMP_DIR}/title.txt"
URL_TXT="${TMP_DIR}/url.txt"
SNAPSHOT_TXT="${TMP_DIR}/snapshot.txt"
CONSOLE_TXT="${TMP_DIR}/console.txt"
ERRORS_TXT="${TMP_DIR}/errors.txt"
NETWORK_JSON="${TMP_DIR}/network.json"
HEALTH_TXT="${TMP_DIR}/health.txt"

log "执行浏览器 preflight 健康检查"
"${HEALTH_BIN}" > "${HEALTH_TXT}" || true

log "使用 ${BROWSER_BIN} 打开调试页面"
"${BROWSER_BIN}" open "${URL}" >/dev/null
"${BROWSER_BIN}" wait 1500 >/dev/null || true

"${BROWSER_BIN}" get title > "${TITLE_TXT}" || true
"${BROWSER_BIN}" get url > "${URL_TXT}" || true
if [[ -n "${SELECTOR}" ]]; then
  "${BROWSER_BIN}" snapshot --compact --depth 6 --selector "${SELECTOR}" > "${SNAPSHOT_TXT}" || true
else
  "${BROWSER_BIN}" snapshot --compact --depth 6 > "${SNAPSHOT_TXT}" || true
fi
"${BROWSER_BIN}" console > "${CONSOLE_TXT}" || true
"${BROWSER_BIN}" errors > "${ERRORS_TXT}" || true
if [[ -n "${NETWORK_FILTER}" ]]; then
  "${BROWSER_BIN}" network requests --json --filter "${NETWORK_FILTER}" > "${NETWORK_JSON}" || true
else
  "${BROWSER_BIN}" network requests --json > "${NETWORK_JSON}" || true
fi
"${HEALTH_BIN}" >> "${HEALTH_TXT}" || true

python3 "${RENDER_PY}" \
  "${TITLE_TXT}" \
  "${URL_TXT}" \
  "${SNAPSHOT_TXT}" \
  "${CONSOLE_TXT}" \
  "${ERRORS_TXT}" \
  "${NETWORK_JSON}" \
  "${HEALTH_TXT}" \
  "${SESSION_NAME}" \
  "${SELECTOR}" \
  "${NETWORK_FILTER}" \
  "${HINT}" \
  "${OUTPUT}"

log "浏览器前端诊断报告已写入 ${OUTPUT}"

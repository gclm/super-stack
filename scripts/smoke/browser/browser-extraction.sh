#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

URL=""
OUTPUT=""
ADAPTER="auto"
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"
BROWSER_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser"
BROWSER_DIR="${SCRIPT_DIR}/../browser"

usage() {
  cat <<'EOF'
用法：
  scripts/smoke/browser/browser-extraction.sh --url URL [--adapter auto|wechat-article|xiaohongshu-note|douyin-content|juejin-article|generic-page] [--output PATH]

示例：
  bash scripts/smoke/browser/browser-extraction.sh \
    --url "https://www.xiaohongshu.com/explore/..." \
    --output artifacts/xiaohongshu-note.md
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
    --adapter)
      ADAPTER="${2:-}"
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
[[ -x "${BROWSER_BIN}" ]] || die "未找到稳定浏览器入口：${BROWSER_BIN}。请先运行 ./scripts/install/install.sh --host all"

if [[ -z "${OUTPUT}" ]]; then
  ensure_dir "${REPO_ROOT}/artifacts"
  OUTPUT="${REPO_ROOT}/artifacts/browser-extraction-$(date +%Y%m%d-%H%M%S).md"
else
  case "${OUTPUT}" in
    /*) ;;
    *) OUTPUT="${REPO_ROOT}/${OUTPUT}" ;;
  esac
  ensure_dir "$(dirname "${OUTPUT}")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

EVIDENCE_JSON="${TMP_DIR}/evidence.json"

detect_adapter() {
  local url="$1"
  case "$url" in
    *mp.weixin.qq.com/s/*) printf 'wechat-article\n' ;;
    *xiaohongshu.com/explore/*|*xiaohongshu.com/discovery/item/*) printf 'xiaohongshu-note\n' ;;
    *douyin.com/*) printf 'douyin-content\n' ;;
    *juejin.cn/post/*) printf 'juejin-article\n' ;;
    *) printf 'generic-page\n' ;;
  esac
}

if [[ "${ADAPTER}" == "auto" ]]; then
  ADAPTER="$(detect_adapter "${URL}")"
fi

case "${ADAPTER}" in
  wechat-article|xiaohongshu-note|douyin-content|juejin-article|generic-page) ;;
  *) die "不支持的 --adapter：${ADAPTER}" ;;
esac

EXTRACTOR_JS="${BROWSER_DIR}/extractors/${ADAPTER}.js"
OPEN_GALLERY_JS="${BROWSER_DIR}/extractors/${ADAPTER}-open-gallery.js"
DECODE_PY="${BROWSER_DIR}/renderers/decode_browser_eval.py"
RENDER_PY="${BROWSER_DIR}/renderers/render_browser_report.py"

[[ -f "${EXTRACTOR_JS}" ]] || die "未找到提取器：${EXTRACTOR_JS}"
[[ -f "${OPEN_GALLERY_JS}" ]] || die "未找到 gallery 脚本：${OPEN_GALLERY_JS}"
[[ -f "${DECODE_PY}" ]] || die "未找到 decode renderer：${DECODE_PY}"
[[ -f "${RENDER_PY}" ]] || die "未找到 report renderer：${RENDER_PY}"

log "正在使用 ${BROWSER_BIN} 打开目标页面"
"${BROWSER_BIN}" open "${URL}" >/dev/null
"${BROWSER_BIN}" wait 1500 >/dev/null

LANDED_URL="$("${BROWSER_BIN}" get url)"
PAGE_TITLE="$("${BROWSER_BIN}" get title)"

"${BROWSER_BIN}" eval "$(cat "${OPEN_GALLERY_JS}")" >/dev/null || true
"${BROWSER_BIN}" wait 1000 >/dev/null || true
"${BROWSER_BIN}" eval "$(cat "${EXTRACTOR_JS}")" > "${EVIDENCE_JSON}.raw"
python3 "${DECODE_PY}" "${EVIDENCE_JSON}.raw" "${EVIDENCE_JSON}"
python3 "${RENDER_PY}" "${EVIDENCE_JSON}" "${URL}" "${LANDED_URL}" "${PAGE_TITLE}" "${SESSION_NAME}" "${OUTPUT}"

log "浏览器提取报告已写入 ${OUTPUT}"

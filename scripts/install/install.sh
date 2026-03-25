#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"
BIN_DIR="${RUNTIME_ROOT}/bin"
MANAGED_BIN_DIR="${REPO_ROOT}/bin"

ensure_browser_wrappers() {
  local stable_wrapper="${BIN_DIR}/super-stack-browser"
  local health_wrapper="${BIN_DIR}/super-stack-browser-health"
  local reset_wrapper="${BIN_DIR}/super-stack-browser-reset"

  ensure_dir "${BIN_DIR}"

  if ! command -v agent-browser >/dev/null 2>&1; then
    log "正在通过 npm 全局安装 agent-browser"
    npm install -g agent-browser
  else
    log "agent-browser 已存在于 PATH 中"
  fi

  cp "${MANAGED_BIN_DIR}/super-stack-browser" "${stable_wrapper}"
  cp "${MANAGED_BIN_DIR}/super-stack-browser-health" "${health_wrapper}"
  cp "${MANAGED_BIN_DIR}/super-stack-browser-reset" "${reset_wrapper}"
  chmod +x "${stable_wrapper}" "${health_wrapper}" "${reset_wrapper}"

  log "稳定浏览器入口已就绪：${stable_wrapper}"
  log "浏览器健康检查入口已就绪：${health_wrapper}"
  log "浏览器会话重置入口已就绪：${reset_wrapper}"
}

usage() {
  cat <<'EOF'
用法：
  scripts/install/install.sh --host claude|codex|all

示例：
  scripts/install/install.sh --host codex
  scripts/install/install.sh --host claude
  scripts/install/install.sh --host all
EOF
}

HOST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
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

[[ -n "$HOST" ]] || die "必须提供 --host"

case "$HOST" in
  claude|codex|all) ;;
  *) die "无效的 --host：$HOST" ;;
esac

bash "${SCRIPT_DIR}/reset-install-state.sh"
ensure_browser_wrappers

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/sync-to-claude.sh"
fi

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/sync-to-codex.sh"
fi

log "安装完成"
log "super-stack 已启用仅全局模式"

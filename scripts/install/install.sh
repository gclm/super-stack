#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"
BIN_DIR="${RUNTIME_ROOT}/bin"
MANAGED_BIN_DIR="${REPO_ROOT}/bin"

ensure_browser_wrappers() {
  local wrapper_name
  local target_path

  ensure_dir "${BIN_DIR}"

  if ! command -v agent-browser >/dev/null 2>&1; then
    log "正在通过 npm 全局安装 agent-browser"
    npm install -g agent-browser
  else
    log "agent-browser 已存在于 PATH 中"
  fi

  while IFS= read -r wrapper_name; do
    [[ -n "${wrapper_name}" ]] || continue
    target_path="${BIN_DIR}/${wrapper_name}"
    cp "${MANAGED_BIN_DIR}/${wrapper_name}" "${target_path}"
    chmod +x "${target_path}"
    case "${wrapper_name}" in
      super-stack-browser)
        log "稳定浏览器入口已就绪：${target_path}"
        ;;
      super-stack-browser-health)
        log "浏览器健康检查入口已就绪：${target_path}"
        ;;
      super-stack-browser-reset)
        log "浏览器会话重置入口已就绪：${target_path}"
        ;;
      *)
        log "浏览器 wrapper 已就绪：${target_path}"
        ;;
    esac
  done < <(browser_wrapper_names)
}

usage() {
  cat <<'EOF'
用法：
  scripts/install/install.sh --host claude|codex|all

说明：
  该脚本必须从 source repo 执行。
  ~/.super-stack/runtime 是纯运行仓库，不保证包含重新安装所需的完整源材料。

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

reset_install_state
log "已重置全局安装状态目录：$(state_root)"
record_source_repo_path
ensure_browser_wrappers

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/install-claude.sh"
fi

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/install-codex.sh"
fi

log "安装完成"
log "super-stack 已启用仅全局模式"
log "当前 runtime 采用纯运行仓库模型；后续安装或重装请始终从 source repo 发起。"

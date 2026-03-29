#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"

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
log "浏览器能力当前不再由 super-stack 安装 agent-browser wrapper；请在宿主侧配置 browser MCP 或 browser plugin。"

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/install-claude.sh"
fi

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/install-codex.sh"
fi

log "安装完成"
log "super-stack 已启用仅全局模式"
log "当前 runtime 采用纯运行仓库模型；后续安装或重装请始终从 source repo 发起。"

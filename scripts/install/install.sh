#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

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
bash "${SCRIPT_DIR}/setup-browser.sh"

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/sync-to-claude.sh"
fi

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/sync-to-codex.sh"
fi

log "安装完成"
log "super-stack 已启用仅全局模式"

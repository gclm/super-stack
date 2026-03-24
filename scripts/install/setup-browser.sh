#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

BROWSER_ROOT="${HOME}/.claude-stack"
BIN_DIR="${BROWSER_ROOT}/bin"

ensure_dir "${BIN_DIR}"

write_executable() {
  local target="$1"
  local content="$2"
  printf '%s\n' "$content" > "$target"
  chmod +x "$target"
}

resolve_global_agent_browser_bin() {
  local prefix
  prefix="$(npm config get prefix 2>/dev/null || true)"
  if [[ -n "${prefix}" && -x "${prefix}/bin/agent-browser" ]]; then
    printf '%s\n' "${prefix}/bin/agent-browser"
    return 0
  fi
  return 1
}

install_agent_browser() {
  local stable_wrapper="${BIN_DIR}/super-stack-browser"

  if ! command -v agent-browser >/dev/null 2>&1; then
    log "正在通过 npm 全局安装 agent-browser"
    npm install -g agent-browser
  else
    log "agent-browser 已存在于 PATH 中"
  fi

  write_executable "${stable_wrapper}" '#!/usr/bin/env bash
set -euo pipefail
TARGET="${SUPER_STACK_AGENT_BROWSER_BIN:-$(command -v agent-browser || true)}"
if [[ -z "${TARGET}" || ! -x "${TARGET}" ]]; then
  PREFIX="$(npm config get prefix 2>/dev/null || true)"
  if [[ -n "${PREFIX}" && -x "${PREFIX}/bin/agent-browser" ]]; then
    TARGET="${PREFIX}/bin/agent-browser"
  fi
fi
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"
if [[ ! -x "$TARGET" ]]; then
  printf "[super-stack] 错误：agent-browser 不可用。请先运行 ./scripts/install/setup-browser.sh\n" >&2
  exit 1
fi
exec "$TARGET" --auto-connect --session-name "$SESSION_NAME" "$@"'

  log "稳定浏览器入口已就绪：${stable_wrapper}"
  if resolved_bin="$(resolve_global_agent_browser_bin)"; then
    log "已解析到全局 agent-browser 二进制：${resolved_bin}"
  fi
}

remove_browser_use_artifacts() {
  local wrapper="${BIN_DIR}/browser-use"
  local tool_dir="${BROWSER_ROOT}/tools/browser-use-cli"
  local legacy_gstack="${BIN_DIR}/gstack-browse"
  local legacy_super_stack="${BIN_DIR}/super-stack-browse"
  local direct_wrapper="${BIN_DIR}/agent-browser"

  if [[ -e "${wrapper}" ]]; then
    rm -f "${wrapper}"
    log "已删除废弃的 browser-use 包装脚本：${wrapper}"
  fi

  if [[ -d "${tool_dir}" ]]; then
    rm -rf "${tool_dir}"
    log "已删除废弃的 browser-use 工具目录：${tool_dir}"
  fi

  if [[ -e "${direct_wrapper}" ]]; then
    rm -f "${direct_wrapper}"
    log "已删除废弃的直连浏览器包装脚本：${direct_wrapper}"
  fi

  if [[ -e "${legacy_gstack}" ]]; then
    rm -f "${legacy_gstack}"
    log "已删除废弃的旧 browse 包装脚本：${legacy_gstack}"
  fi

  if [[ -e "${legacy_super_stack}" ]]; then
    rm -f "${legacy_super_stack}"
    log "已删除废弃的旧 super-stack browse 包装脚本：${legacy_super_stack}"
  fi
}

install_agent_browser
remove_browser_use_artifacts

cat <<EOF
[super-stack] 浏览器提供方已准备完成。

主入口：
  - ${BIN_DIR}/super-stack-browser

说明：
  - super-stack 会通过 npm 全局安装 agent-browser，并只暴露一个稳定包装入口。
  - 日常请优先使用 ${BIN_DIR}/super-stack-browser，以保持自动连接和会话复用稳定。
  - 如需覆盖稳定会话名，可设置 SUPER_STACK_BROWSER_SESSION。
EOF

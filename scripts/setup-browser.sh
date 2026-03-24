#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

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
    log "installing agent-browser globally via npm"
    npm install -g agent-browser
  else
    log "agent-browser already available in PATH"
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
  printf "[super-stack] ERROR: agent-browser is not available. Run ./scripts/setup-browser.sh first.\n" >&2
  exit 1
fi
exec "$TARGET" --auto-connect --session-name "$SESSION_NAME" "$@"'

  log "stable browser entry ready: ${stable_wrapper}"
  if resolved_bin="$(resolve_global_agent_browser_bin)"; then
    log "resolved global agent-browser binary: ${resolved_bin}"
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
    log "removed deprecated browser-use wrapper: ${wrapper}"
  fi

  if [[ -d "${tool_dir}" ]]; then
    rm -rf "${tool_dir}"
    log "removed deprecated browser-use tool dir: ${tool_dir}"
  fi

  if [[ -e "${direct_wrapper}" ]]; then
    rm -f "${direct_wrapper}"
    log "removed deprecated direct browser wrapper: ${direct_wrapper}"
  fi

  if [[ -e "${legacy_gstack}" ]]; then
    rm -f "${legacy_gstack}"
    log "removed deprecated legacy browse wrapper: ${legacy_gstack}"
  fi

  if [[ -e "${legacy_super_stack}" ]]; then
    rm -f "${legacy_super_stack}"
    log "removed deprecated legacy browse wrapper: ${legacy_super_stack}"
  fi
}

install_agent_browser
remove_browser_use_artifacts

cat <<EOF
[super-stack] Browser providers prepared.

Primary:
  - ${BIN_DIR}/super-stack-browser

Notes:
  - super-stack installs agent-browser globally via npm and exposes only one stable wrapper.
  - prefer ${BIN_DIR}/super-stack-browser for daily use so auto-connect and session reuse stay stable.
  - override the stable session name with SUPER_STACK_BROWSER_SESSION if needed.
EOF

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

BROWSER_BIN="${HOME}/.claude-stack/bin/super-stack-browser"
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"

if [[ ! -x "${BROWSER_BIN}" ]]; then
  die "stable browser entry not found: ${BROWSER_BIN}. Run ./scripts/setup-browser.sh first."
fi

log "resetting stable browser session: ${SESSION_NAME}"
"${BROWSER_BIN}" close >/dev/null 2>&1 || true
sleep 1
"${BROWSER_BIN}" session >/dev/null 2>&1 || true
log "stable browser session reset complete"

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

BROWSER_BIN="${HOME}/.super-stack/runtime/bin/super-stack-browser"
SESSION_NAME="${SUPER_STACK_BROWSER_SESSION:-super-stack-browser}"

if [[ ! -x "${BROWSER_BIN}" ]]; then
  die "未找到稳定浏览器入口：${BROWSER_BIN}。请先运行 ./scripts/install/install.sh --host all"
fi

"${BROWSER_BIN%/*}/super-stack-browser-reset"

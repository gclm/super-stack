#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/install.sh --host claude|codex|all --mode project|global [--target PATH]

Examples:
  scripts/install.sh --host all --mode project --target /path/to/project
  scripts/install.sh --host codex --mode global
  scripts/install.sh --host claude --mode global
EOF
}

HOST=""
MODE=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$HOST" ]] || die "--host is required"
[[ -n "$MODE" ]] || die "--mode is required"

case "$HOST" in
  claude|codex|all) ;;
  *) die "Invalid --host: $HOST" ;;
esac

case "$MODE" in
  project|global) ;;
  *) die "Invalid --mode: $MODE" ;;
esac

if [[ "$MODE" == "project" ]]; then
  [[ -n "$TARGET" ]] || die "--target is required for project mode"
  bash "${SCRIPT_DIR}/sync-to-project.sh" --host "$HOST" --target "$TARGET"
  exit 0
fi

bash "${SCRIPT_DIR}/setup-browser.sh"

if [[ "$HOST" == "claude" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/sync-to-claude.sh"
fi

if [[ "$HOST" == "codex" || "$HOST" == "all" ]]; then
  bash "${SCRIPT_DIR}/sync-to-codex.sh"
fi

log "Install complete"
if [[ "$MODE" == "global" ]]; then
  log "super-stack global-first strategy enabled"
  log "Project mode remains available for thin repository-specific overrides"
fi

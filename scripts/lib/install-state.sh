#!/usr/bin/env bash

set -euo pipefail

INSTALL_STATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${INSTALL_STATE_LIB_DIR}/common.sh"

SUPER_STACK_STATE_ROOT="${SUPER_STACK_STATE_BASE}/global-install"
SUPER_STACK_MANIFEST="${SUPER_STACK_STATE_ROOT}/manifest.tsv"

state_root() {
  printf '%s\n' "$SUPER_STACK_STATE_ROOT"
}

state_manifest() {
  printf '%s\n' "$SUPER_STACK_MANIFEST"
}

reset_install_state() {
  rm -rf "$SUPER_STACK_STATE_ROOT"
  mkdir -p "$SUPER_STACK_STATE_ROOT/backups"
  : > "$SUPER_STACK_MANIFEST"
}

manifest_has_target() {
  local target="$1"
  [[ -f "$SUPER_STACK_MANIFEST" ]] && rg -q "^.*\t${target//\//\\/}\t" "$SUPER_STACK_MANIFEST"
}

record_target_state() {
  local target="$1"
  local label="$2"

  mkdir -p "$SUPER_STACK_STATE_ROOT/backups"
  touch "$SUPER_STACK_MANIFEST"

  if manifest_has_target "$target"; then
    return 0
  fi

  local safe_label="${label//\//_}"
  local backup_path="${SUPER_STACK_STATE_ROOT}/backups/${safe_label}"

  if [[ -e "$target" ]]; then
    rm -rf "$backup_path"
    cp -R "$target" "$backup_path"
    printf 'restore\t%s\t%s\n' "$target" "$backup_path" >> "$SUPER_STACK_MANIFEST"
  else
    printf 'remove\t%s\t-\n' "$target" >> "$SUPER_STACK_MANIFEST"
  fi
}

restore_recorded_targets() {
  [[ -f "$SUPER_STACK_MANIFEST" ]] || return 0

  while IFS=$'\t' read -r action target backup_path; do
    [[ -n "$action" ]] || continue

    case "$action" in
      restore)
        mkdir -p "$(dirname "$target")"
        rm -rf "$target"
        cp -R "$backup_path" "$target"
        ;;
      remove)
        rm -rf "$target"
        ;;
    esac
  done < "$SUPER_STACK_MANIFEST"
}

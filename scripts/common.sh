#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
  printf '[super-stack] %s\n' "$*"
}

die() {
  printf '[super-stack] ERROR: %s\n' "$*" >&2
  exit 1
}

ensure_dir() {
  mkdir -p "$1"
}

resolve_codex_bin() {
  if [[ -n "${CODEX_BIN:-}" ]]; then
    printf '%s\n' "$CODEX_BIN"
    return 0
  fi

  if command -v codex >/dev/null 2>&1; then
    command -v codex
    return 0
  fi

  if [[ -x "/usr/local/bin/codex" ]]; then
    printf '/usr/local/bin/codex\n'
    return 0
  fi

  if [[ -x "${HOME}/.local/bin/codex" ]]; then
    printf '%s\n' "${HOME}/.local/bin/codex"
    return 0
  fi

  return 1
}

resolve_claude_bin() {
  if [[ -n "${CLAUDE_BIN:-}" ]]; then
    printf '%s\n' "$CLAUDE_BIN"
    return 0
  fi

  if command -v claude >/dev/null 2>&1; then
    command -v claude
    return 0
  fi

  if [[ -x "${HOME}/.local/bin/claude" ]]; then
    printf '%s\n' "${HOME}/.local/bin/claude"
    return 0
  fi

  if [[ -x "/usr/local/bin/claude" ]]; then
    printf '/usr/local/bin/claude\n'
    return 0
  fi

  return 1
}

copy_tree() {
  local src="$1"
  local dest="$2"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

remove_managed_block() {
  local file="$1"
  local begin="$2"
  local end="$3"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$file" > "${file}.tmp"
  mv "${file}.tmp" "$file"
}

append_managed_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local block="$4"

  ensure_dir "$(dirname "$file")"
  touch "$file"
  remove_managed_block "$file" "$begin" "$end"

  if [[ -s "$file" ]]; then
    printf '\n' >> "$file"
  fi

  {
    printf '%s\n' "$begin"
    printf '%s\n' "$block"
    printf '%s\n' "$end"
  } >> "$file"
}

write_if_missing() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" ]]; then
    return 0
  fi

  ensure_dir "$(dirname "$dest")"
  cp "$src" "$dest"
}

copy_dir_if_missing() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" ]]; then
    return 0
  fi

  ensure_dir "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

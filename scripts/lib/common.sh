#!/usr/bin/env bash

set -euo pipefail

COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${COMMON_LIB_DIR}/../.." && pwd)"
SUPER_STACK_HOME="${HOME}/.super-stack"
SUPER_STACK_RUNTIME_ROOT="${SUPER_STACK_HOME}/runtime"
SUPER_STACK_STATE_BASE="${SUPER_STACK_HOME}/state"
SUPER_STACK_BACKUP_ROOT="${SUPER_STACK_HOME}/backup"

log() {
  printf '[super-stack] %s\n' "$*"
}

die() {
  printf '[super-stack] 错误：%s\n' "$*" >&2
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

copy_path_into_dir() {
  local src="$1"
  local dest_root="$2"
  local relative_path="$3"

  mkdir -p "${dest_root}/$(dirname "$relative_path")"
  cp -R "$src" "${dest_root}/${relative_path}"
}

copy_runtime_tree() {
  local dest_root="$1"

  rm -rf "$dest_root"
  mkdir -p "$dest_root"

  copy_path_into_dir "${REPO_ROOT}/AGENTS.md" "$dest_root" "AGENTS.md"
  copy_path_into_dir "${REPO_ROOT}/README.md" "$dest_root" "README.md"
  copy_path_into_dir "${REPO_ROOT}/bin" "$dest_root" "bin"
  copy_path_into_dir "${REPO_ROOT}/protocols" "$dest_root" "protocols"
  copy_path_into_dir "${REPO_ROOT}/scripts" "$dest_root" "scripts"
  copy_path_into_dir "${REPO_ROOT}/templates" "$dest_root" "templates"
  copy_path_into_dir "${REPO_ROOT}/.codex/hooks" "$dest_root" ".codex/hooks"
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

retry_with_backoff() {
  local max_attempts="$1"
  shift

  local attempt=1
  local base_sleep=3

  while true; do
    if "$@"; then
      return 0
    fi

    if (( attempt >= max_attempts )); then
      return 1
    fi

    local jitter=$((RANDOM % 10))
    local sleep_seconds=$((base_sleep + jitter))
    log "命令执行失败，${sleep_seconds}s 后进行第 $((attempt + 1))/${max_attempts} 次重试：$*"
    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done
}

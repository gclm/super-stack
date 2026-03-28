#!/usr/bin/env bash

set -euo pipefail

COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${COMMON_LIB_DIR}/../.." && pwd)"
SUPER_STACK_HOME="${HOME}/.super-stack"
SUPER_STACK_RUNTIME_ROOT="${SUPER_STACK_HOME}/runtime"
SUPER_STACK_STATE_BASE="${SUPER_STACK_HOME}/state"
SUPER_STACK_BACKUP_ROOT="${SUPER_STACK_HOME}/backup"
SUPER_STACK_MANAGED_CHECK_SCRIPT="${REPO_ROOT}/scripts/config/check_managed_config.py"
BROWSER_WRAPPER_NAMES=(
  "super-stack-browser"
  "super-stack-browser-health"
  "super-stack-browser-reset"
)

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

browser_wrapper_names() {
  printf '%s\n' "${BROWSER_WRAPPER_NAMES[@]}"
}

mirror_repo_skills() {
  local dest_root="$1"
  local skill_dir

  ensure_dir "$dest_root"

  for skill_dir in "${REPO_ROOT}"/.agents/skills/*/*; do
    [[ -d "$skill_dir" ]] || continue
    copy_tree "$skill_dir" "${dest_root}/$(basename "$skill_dir")"
  done
}

write_global_router_file() {
  local dest_file="$1"
  local source_phrase="$2"
  local host_title="$3"
  local skills_line="$4"

  ensure_dir "$(dirname "$dest_file")"

  cat > "$dest_file" <<EOF
# Super Stack Global Router

Use \`${SUPER_STACK_RUNTIME_ROOT}/AGENTS.md\` as the ${source_phrase}.

- This is the default global workflow router for ${host_title}.
- This repository is the single global workflow source managed by super-stack.
- ${skills_line}
- Treat global super-stack as the canonical system configuration.
EOF
}

render_global_router_text() {
  local source_phrase="$1"
  local host_title="$2"
  local skills_line="$3"

  cat <<EOF
# Super Stack Global Router

Use \`${SUPER_STACK_RUNTIME_ROOT}/AGENTS.md\` as the ${source_phrase}.

- This is the default global workflow router for ${host_title}.
- This repository is the single global workflow source managed by super-stack.
- ${skills_line}
- Treat global super-stack as the canonical system configuration.
EOF
}

managed_config_lines() {
  local block="$1"
  local field="$2"

  python3 "$SUPER_STACK_MANAGED_CHECK_SCRIPT" --block "$block" --field "$field" --runtime-root "$SUPER_STACK_RUNTIME_ROOT" --home "$HOME"
}

managed_config_target_file() {
  managed_config_lines "$1" target_file | head -n 1
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

ok() {
  printf '[通过] %s\n' "$*"
}

warn() {
  printf '[警告] %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -f "$path" ]]; then
    ok "${label}: ${path}"
  else
    warn "${label}: 缺失（${path}）"
  fi
}

check_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "$path" ]]; then
    ok "${label}: ${path}"
  else
    warn "${label}: 缺失（${path}）"
  fi
}

check_not_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    warn "${label}: 不应存在（${path}）"
  else
    ok "${label}"
  fi
}

check_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [[ ! -f "$path" ]]; then
    warn "${label}: 文件缺失（${path}）"
    return
  fi

  if rg -q --fixed-strings "$pattern" "$path"; then
    ok "${label}"
  else
    warn "${label}: 未在 ${path} 中找到预期内容"
  fi
}

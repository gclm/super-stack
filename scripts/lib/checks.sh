#!/usr/bin/env bash

set -euo pipefail

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

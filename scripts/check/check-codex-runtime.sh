#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
CODEX_BIN="$(resolve_codex_bin || true)"
CONFIG_FILE="${CODEX_CONFIG_FILE:-${CODEX_HOME}/config.toml}"
CODEX_SOURCE="${CODEX_SOURCE_REPO:-}"

sqlite_home="$CODEX_HOME"
if [[ -f "$CONFIG_FILE" ]]; then
  configured_home="$(sed -nE 's/^sqlite_home = "(.*)"/\1/p' "$CONFIG_FILE" | tail -n 1)"
  if [[ -n "$configured_home" ]]; then
    sqlite_home="$configured_home"
  fi
fi

state_db="${sqlite_home}/state_5.sqlite"
logs_db="${sqlite_home}/logs_1.sqlite"

printf '== Codex 运行时检查 ==\n'
printf 'codex_home: %s\n' "$CODEX_HOME"
printf '配置文件: %s\n' "$CONFIG_FILE"
printf 'sqlite_home: %s\n' "$sqlite_home"
printf 'codex_bin: %s\n' "$CODEX_BIN"
printf '\n'

if [[ -n "$CODEX_BIN" && -x "$CODEX_BIN" ]]; then
  printf 'codex_version: %s\n' "$("$CODEX_BIN" --version 2>/dev/null || true)"
else
  printf 'codex_version: 不可用（二进制不存在或不可执行）\n'
fi

printf '\n== sqlite 文件 ==\n'
[[ -f "$state_db" ]] && printf '[通过] state db: %s\n' "$state_db" || printf '[警告] state db 缺失: %s\n' "$state_db"
[[ -f "$logs_db" ]] && printf '[通过] logs db: %s\n' "$logs_db" || printf '[警告] logs db 缺失: %s\n' "$logs_db"

if [[ -f "$state_db" ]] && command -v sqlite3 >/dev/null 2>&1; then
  printf '\n== 已应用的 state migrations ==\n'
  sqlite3 "$state_db" "select version || '|' || description from _sqlx_migrations order by version;"
fi

if [[ -n "$CODEX_SOURCE" ]]; then
  migrations_dir="${CODEX_SOURCE}/codex-rs/state/migrations"
  if [[ -d "$migrations_dir" ]]; then
    printf '\n== 内置的 state migrations ==\n'
    find "$migrations_dir" -maxdepth 1 -type f | sort | xargs -I{} basename "{}"
  else
    printf '\n[警告] 在 CODEX_SOURCE_REPO 下未找到 migrations 目录：%s\n' "$migrations_dir"
  fi
fi

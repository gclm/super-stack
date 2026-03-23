#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

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

printf '== codex runtime check ==\n'
printf 'codex_home: %s\n' "$CODEX_HOME"
printf 'config: %s\n' "$CONFIG_FILE"
printf 'sqlite_home: %s\n' "$sqlite_home"
printf 'codex_bin: %s\n' "$CODEX_BIN"
printf '\n'

if [[ -n "$CODEX_BIN" && -x "$CODEX_BIN" ]]; then
  printf 'codex_version: %s\n' "$("$CODEX_BIN" --version 2>/dev/null || true)"
else
  printf 'codex_version: unavailable (binary not executable)\n'
fi

printf '\n== sqlite files ==\n'
[[ -f "$state_db" ]] && printf '[OK] state db: %s\n' "$state_db" || printf '[WARN] state db missing: %s\n' "$state_db"
[[ -f "$logs_db" ]] && printf '[OK] logs db: %s\n' "$logs_db" || printf '[WARN] logs db missing: %s\n' "$logs_db"

if [[ -f "$state_db" ]] && command -v sqlite3 >/dev/null 2>&1; then
  printf '\n== applied state migrations ==\n'
  sqlite3 "$state_db" "select version || '|' || description from _sqlx_migrations order by version;"
fi

if [[ -n "$CODEX_SOURCE" ]]; then
  migrations_dir="${CODEX_SOURCE}/codex-rs/state/migrations"
  if [[ -d "$migrations_dir" ]]; then
    printf '\n== bundled state migrations ==\n'
    find "$migrations_dir" -maxdepth 1 -type f | sort | xargs -I{} basename "{}"
  else
    printf '\n[WARN] migrations directory not found under CODEX_SOURCE_REPO: %s\n' "$migrations_dir"
  fi
fi

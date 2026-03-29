#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

STATE_FILE="${REPO_ROOT}/harness/state.md"
HISTORY_FILE="${REPO_ROOT}/harness/history.md"

SOFT_MAX_LINES="${HARNESS_STATE_MAX_LINES:-60}"
SOFT_MAX_BULLETS="${HARNESS_STATE_MAX_BULLETS:-12}"
WARN_ONLY="${HARNESS_STATE_CHECK_WARN_ONLY:-0}"

warn_or_die() {
  local msg="$1"
  if [[ "$WARN_ONLY" == "1" ]]; then
    warn "$msg"
  else
    die "$msg"
  fi
}

require_file() {
  local file="$1"
  local label="$2"
  [[ -f "$file" ]] || warn_or_die "${label} 不存在：${file}"
}

count_bullets() {
  local file="$1"
  rg -n '^- ' "$file" | wc -l | tr -d ' '
}

check_state_size() {
  local lines bullets
  lines="$(wc -l < "$STATE_FILE" | tr -d ' ')"
  bullets="$(count_bullets "$STATE_FILE")"

  log "harness/state.md 行数: ${lines} (阈值 ${SOFT_MAX_LINES})"
  log "harness/state.md 顶层 bullet 数: ${bullets} (阈值 ${SOFT_MAX_BULLETS})"

  if (( lines > SOFT_MAX_LINES )); then
    warn_or_die "harness/state.md 超过建议上限（${lines} > ${SOFT_MAX_LINES}），请归档稳定内容到 harness/history.md"
  fi

  if (( bullets > SOFT_MAX_BULLETS )); then
    warn_or_die "harness/state.md 顶层条目过多（${bullets} > ${SOFT_MAX_BULLETS}），请收敛当前执行态并归档历史态"
  fi
}

changed_in_worktree() {
  local file="$1"
  git status --porcelain -- "$file" | sed '/^$/d' | wc -l | tr -d ' '
}

check_state_history_coupling() {
  local state_changed history_changed
  state_changed="$(changed_in_worktree "$STATE_FILE")"
  history_changed="$(changed_in_worktree "$HISTORY_FILE")"

  if (( state_changed > 0 )) && (( history_changed == 0 )); then
    warn "检测到 harness/state.md 有变更，但 harness/history.md 无变更。若本次包含稳定决策/流程调整，请补一条 history 记录。"
  fi
}

main() {
  require_file "$STATE_FILE" "harness/state.md"
  require_file "$HISTORY_FILE" "harness/history.md"

  check_state_size
  check_state_history_coupling

  ok "harness 状态治理检查通过"
}

main "$@"

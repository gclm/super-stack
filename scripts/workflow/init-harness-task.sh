#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'USAGE'
用法：
  scripts/workflow/init-harness-task.sh --task-id <task-id> [--root <path>]

说明：
  - 默认在当前目录初始化 `harness/tasks/<task-id>/`
  - 若 `harness/state.md` 不存在，会一并创建
USAGE
}

ROOT="$(pwd)"
TASK_ID=""
TODAY="$(date +%F)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --task-id)
      TASK_ID="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1"
      ;;
  esac
done

[[ -n "${TASK_ID}" ]] || die "缺少 --task-id"
[[ "${TASK_ID}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "task-id 只能包含字母、数字、点、下划线和中划线"
[[ -d "${ROOT}" ]] || die "目标根目录不存在：${ROOT}"

HARNESS_ROOT="${ROOT}/harness"
TASK_ROOT="${HARNESS_ROOT}/tasks/${TASK_ID}"
TEMPLATE_ROOT="${REPO_ROOT}/templates/generated-project/harness"
TASK_TEMPLATE_ROOT="${TEMPLATE_ROOT}/tasks/_task-template"

[[ ! -e "${TASK_ROOT}" ]] || die "任务目录已存在：${TASK_ROOT}"
[[ -d "${TASK_TEMPLATE_ROOT}" ]] || die "任务模板目录不存在：${TASK_TEMPLATE_ROOT}"

ensure_dir "${HARNESS_ROOT}/tasks"

if [[ ! -f "${HARNESS_ROOT}/state.md" ]]; then
  cp "${TEMPLATE_ROOT}/state.md" "${HARNESS_ROOT}/state.md"
fi

ensure_dir "${TASK_ROOT}"

render_template() {
  local src="$1"
  local dest="$2"
  sed \
    -e "s/{{TASK_ID}}/${TASK_ID}/g" \
    -e "s/{{DATE}}/${TODAY}/g" \
    "$src" > "$dest"
}

render_template "${TASK_TEMPLATE_ROOT}/brief.md" "${TASK_ROOT}/brief.md"
render_template "${TASK_TEMPLATE_ROOT}/progress.md" "${TASK_ROOT}/progress.md"
render_template "${TASK_TEMPLATE_ROOT}/decisions.md" "${TASK_ROOT}/decisions.md"
render_template "${TASK_TEMPLATE_ROOT}/evidence-index.json" "${TASK_ROOT}/evidence-index.json"
render_template "${TASK_TEMPLATE_ROOT}/verdict.json" "${TASK_ROOT}/verdict.json"

log "已初始化 harness task：${TASK_ROOT}"

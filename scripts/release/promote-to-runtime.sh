#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
用法：
  scripts/release/promote-to-runtime.sh [--level <L1|L2|L3>] [--reviewed] [--dry-run] [--path <path> ...] [path...]

说明：
  - 默认对当前 git 工作区改动执行分级与 promotion
  - `--level` 只能把等级上调，不能压低自动分类结果
  - `--reviewed` 用于显式确认 L3 改动已经过人工 review
  - `--dry-run` 会完整执行 gate，但不实际同步 runtime
EOF
}

collect_paths_from_git() {
  {
    git diff --name-only --relative HEAD
    git ls-files --others --exclude-standard
  } | sed '/^$/d' | awk '!seen[$0]++ { print }'
}

level_rank() {
  case "$1" in
    L1) printf '1\n' ;;
    L2) printf '2\n' ;;
    L3) printf '3\n' ;;
    *) die "未知等级：$1" ;;
  esac
}

higher_level() {
  local left="$1"
  local right="$2"

  if (( $(level_rank "${left}") >= $(level_rank "${right}") )); then
    printf '%s\n' "${left}"
  else
    printf '%s\n' "${right}"
  fi
}

check_runtime_tree() {
  local required_path
  local required_paths=(
    "AGENTS.md"
    "README.md"
    "claude"
    "codex"
    "protocols"
    "scripts/hooks"
    "scripts/lib/common.sh"
    "scripts/workflow"
    "templates"
    ".codex/hooks"
  )

  for required_path in "${required_paths[@]}"; do
    [[ -e "${SUPER_STACK_RUNTIME_ROOT}/${required_path}" ]] || die "runtime 缺少必要路径：${required_path}"
  done

  log "runtime tree 最小检查通过"
}

REQUESTED_LEVEL=""
REVIEWED=0
DRY_RUN=0
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --level)
      REQUESTED_LEVEL="${2:-}"
      shift 2
      ;;
    --reviewed)
      REVIEWED=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --path)
      INPUT_PATHS+=("${2:-}")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        INPUT_PATHS+=("$1")
        shift
      done
      ;;
    *)
      INPUT_PATHS+=("$1")
      shift
      ;;
  esac
done

if [[ "${#INPUT_PATHS[@]}" -eq 0 ]]; then
  while IFS= read -r path; do
    INPUT_PATHS+=("${path}")
  done < <(collect_paths_from_git)
fi

[[ "${#INPUT_PATHS[@]}" -gt 0 ]] || die "未提供改动路径，且当前工作区没有可 promotion 的改动"

CLASSIFIED_LEVEL="$(bash "${REPO_ROOT}/scripts/check/classify-change-risk.sh" --format level "${INPUT_PATHS[@]}")"
EFFECTIVE_LEVEL="${CLASSIFIED_LEVEL}"

if [[ -n "${REQUESTED_LEVEL}" ]]; then
  case "${REQUESTED_LEVEL}" in
    L1|L2|L3) ;;
    *) die "无效的 --level：${REQUESTED_LEVEL}" ;;
  esac
  EFFECTIVE_LEVEL="$(higher_level "${CLASSIFIED_LEVEL}" "${REQUESTED_LEVEL}")"
fi

log "变更分级摘要："
bash "${REPO_ROOT}/scripts/check/classify-change-risk.sh" --format summary "${INPUT_PATHS[@]}"
log "effective risk level: ${EFFECTIVE_LEVEL}"

log "执行 source-side checks"
bash "${REPO_ROOT}/scripts/check/run-source-checks.sh"

if [[ "${EFFECTIVE_LEVEL}" != "L1" ]]; then
  log "执行 targeted smoke"
  bash "${REPO_ROOT}/scripts/smoke/run-targeted-smoke.sh" --level "${EFFECTIVE_LEVEL}" "${INPUT_PATHS[@]}"
fi

if [[ "${EFFECTIVE_LEVEL}" == "L3" && "${REVIEWED}" -ne 1 ]]; then
  die "L3 改动需要显式传入 --reviewed"
fi

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "dry-run：gate 已通过，未执行 runtime sync"
  exit 0
fi

log "同步 runtime 到 ${SUPER_STACK_RUNTIME_ROOT}"
copy_runtime_tree "${SUPER_STACK_RUNTIME_ROOT}"
check_runtime_tree

if [[ -f "${SUPER_STACK_STATE_BASE}/install-manifest.tsv" ]]; then
  log "检测到全局安装清单，执行 host-level check"
  bash "${REPO_ROOT}/scripts/check/check-global-install.sh"
else
  log "未检测到 install-manifest.tsv，跳过 host-level check"
fi

log "promotion 完成：level=${EFFECTIVE_LEVEL}"

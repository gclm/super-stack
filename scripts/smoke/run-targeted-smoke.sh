#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
用法：
  scripts/smoke/run-targeted-smoke.sh [--level <L1|L2|L3>] [--path <path> ...] [path...]

说明：
  - 默认按路径选择最小 smoke
  - 若未提供路径，则读取当前 git 工作区改动
EOF
}

collect_paths_from_git() {
  {
    git diff --name-only --relative HEAD
    git ls-files --others --exclude-standard
  } | sed '/^$/d' | awk '!seen[$0]++ { print }'
}

LEVEL=""
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --level)
      LEVEL="${2:-}"
      shift 2
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

[[ "${#INPUT_PATHS[@]}" -gt 0 ]] || die "未提供改动路径，且当前工作区没有可 smoke 的改动"

if [[ -z "${LEVEL}" ]]; then
  LEVEL="$(bash "${REPO_ROOT}/scripts/check/classify-change-risk.sh" --format level "${INPUT_PATHS[@]}")"
fi

case "${LEVEL}" in
  L1)
    log "L1 改动默认不需要 targeted smoke"
    exit 0
    ;;
  L2|L3) ;;
  *)
    die "无效的 --level：${LEVEL}"
    ;;
esac

needs_integration=0
needs_unit=0

for path in "${INPUT_PATHS[@]}"; do
  if [[ "${path}" == "AGENTS.md" ]] \
    || [[ "${path}" == protocols/* ]] \
    || [[ "${path}" == .codex/* ]] \
    || [[ "${path}" == .claude/* ]] \
    || [[ "${path}" == scripts/install/* ]] \
    || [[ "${path}" == scripts/check/* ]] \
    || [[ "${path}" == scripts/config/* ]] \
    || [[ "${path}" == scripts/hooks/* ]] \
    || [[ "${path}" == scripts/lib/* ]] \
    || [[ "${path}" == scripts/release/* ]] \
    || [[ "${path}" == scripts/smoke/* ]]; then
    needs_integration=1
    break
  fi

  if [[ "${path}" == .agents/skills/* ]] \
    || [[ "${path}" == templates/* ]] \
    || [[ "${path}" == scripts/workflow/* ]] \
    || [[ "${path}" == tests/* ]]; then
    needs_unit=1
  fi
done

if [[ "${needs_integration}" -eq 1 ]]; then
  log "命中 integration smoke 路径，执行 integration 测试层"
  bash "${REPO_ROOT}/scripts/test/test.sh" --layer integration
  exit 0
fi

if [[ "${needs_unit}" -eq 1 ]]; then
  log "命中 unit smoke 路径，执行 unit 测试层"
  bash "${REPO_ROOT}/scripts/test/test.sh" --layer unit
  exit 0
fi

log "未命中更细粒度映射，执行保守 unit smoke"
bash "${REPO_ROOT}/scripts/test/test.sh" --layer unit

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
用法：
  scripts/check/classify-change-risk.sh [--format summary|level] [--path <path> ...] [path...]

说明：
  - 默认输出分级摘要
  - 若未提供路径，则读取当前 git 工作区改动
  - 当前 phase-1 采用路径驱动的保守分级：L1 / L2 / L3
EOF
}

collect_paths_from_git() {
  {
    git diff --name-only --relative HEAD
    git ls-files --others --exclude-standard
  } | sed '/^$/d' | awk '!seen[$0]++ { print }'
}

normalize_path() {
  local path="$1"

  path="${path#./}"
  if [[ "${path}" == "${REPO_ROOT}/"* ]]; then
    path="${path#${REPO_ROOT}/}"
  fi

  printf '%s\n' "${path}"
}

level_rank() {
  case "$1" in
    L1) printf '1\n' ;;
    L2) printf '2\n' ;;
    L3) printf '3\n' ;;
    *) die "未知等级：$1" ;;
  esac
}

classify_path() {
  local path="$1"

  if [[ "${path}" == "AGENTS.md" ]] \
    || [[ "${path}" == protocols/* ]] \
    || [[ "${path}" == config/* ]] \
    || [[ "${path}" == codex/* ]] \
    || [[ "${path}" == claude/* ]] \
    || [[ "${path}" == scripts/check/* ]] \
    || [[ "${path}" == scripts/install/* ]] \
    || [[ "${path}" == scripts/hooks/* ]] \
    || [[ "${path}" == scripts/config/* ]] \
    || [[ "${path}" == scripts/lib/* ]] \
    || [[ "${path}" == scripts/release/* ]]; then
    printf 'L3|host-or-runtime-surface\n'
    return 0
  fi

  if [[ "${path}" == docs/* ]] \
    || [[ "${path}" == README.md ]] \
    || [[ "${path}" == .planning/* ]] \
    || [[ "${path}" == artifacts/examples/* ]] \
    || [[ "${path}" =~ ^skills/.+/references/ ]]; then
    printf 'L1|docs-or-reference\n'
    return 0
  fi

  if [[ "${path}" =~ ^skills/.+/SKILL\.md$ ]] \
    || [[ "${path}" =~ ^skills/.+/(assets|scripts|agents)/ ]] \
    || [[ "${path}" == templates/* ]] \
    || [[ "${path}" == scripts/workflow/* ]] \
    || [[ "${path}" == scripts/smoke/* ]] \
    || [[ "${path}" == tests/* ]]; then
    printf 'L2|workflow-or-template-surface\n'
    return 0
  fi

  printf 'L2|conservative-default\n'
}

FORMAT="summary"
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      FORMAT="${2:-}"
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

case "${FORMAT}" in
  summary|level) ;;
  *) die "无效的 --format：${FORMAT}" ;;
esac

if [[ "${#INPUT_PATHS[@]}" -eq 0 ]]; then
  while IFS= read -r path; do
    INPUT_PATHS+=("${path}")
  done < <(collect_paths_from_git)
fi

normalized_paths=()
while IFS= read -r path; do
  normalized_paths+=("${path}")
done < <(
  printf '%s\n' "${INPUT_PATHS[@]}" \
    | sed '/^$/d' \
    | while IFS= read -r path; do
        normalize_path "${path}"
      done \
    | awk '!seen[$0]++ { print }'
)
INPUT_PATHS=("${normalized_paths[@]}")

[[ "${#INPUT_PATHS[@]}" -gt 0 ]] || die "未提供改动路径，且当前工作区没有可分类的改动"

highest_level="L1"
declare -a DETAILS=()

for path in "${INPUT_PATHS[@]}"; do
  classification="$(classify_path "${path}")"
  level="${classification%%|*}"
  reason="${classification#*|}"
  DETAILS+=("${level}|${reason}|${path}")

  if (( $(level_rank "${level}") > $(level_rank "${highest_level}") )); then
    highest_level="${level}"
  fi
done

if [[ "${FORMAT}" == "level" ]]; then
  printf '%s\n' "${highest_level}"
  exit 0
fi

printf 'risk_level=%s\n' "${highest_level}"
for detail in "${DETAILS[@]}"; do
  IFS='|' read -r level reason path <<< "${detail}"
  printf '%s\t%s\t%s\n' "${level}" "${reason}" "${path}"
done

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
用法：
  scripts/workflow/init-generated-project.sh [--root <path>]

说明：
  - 默认在当前目录初始化 target project 的 `docs/ + harness/`
  - 不会覆盖已有文件；已存在的路径会被保留
  - 若目标目录不存在，会先创建
EOF
}

ROOT="$(pwd)"
TEMPLATE_ROOT="${REPO_ROOT}/templates/generated-project"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
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

[[ -n "${ROOT}" ]] || die "目标根目录不能为空"
[[ -d "${TEMPLATE_ROOT}" ]] || die "模板目录不存在：${TEMPLATE_ROOT}"

ensure_dir "${ROOT}"

while IFS= read -r template_dir; do
  relative_path="${template_dir#${TEMPLATE_ROOT}/}"
  [[ "${relative_path}" != "${template_dir}" ]] || continue
  ensure_dir "${ROOT}/${relative_path}"
done < <(find "${TEMPLATE_ROOT}" -type d | sort)

created_count=0
skipped_count=0

while IFS= read -r template_file; do
  relative_path="${template_file#${TEMPLATE_ROOT}/}"
  target_file="${ROOT}/${relative_path}"

  if [[ -e "${target_file}" ]]; then
    skipped_count=$((skipped_count + 1))
    continue
  fi

  ensure_dir "$(dirname "${target_file}")"
  cp "${template_file}" "${target_file}"
  created_count=$((created_count + 1))
done < <(find "${TEMPLATE_ROOT}" -type f | sort)

log "已初始化 generated project：root=${ROOT} created=${created_count} skipped=${skipped_count}"

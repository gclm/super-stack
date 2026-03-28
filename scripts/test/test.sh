#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

usage() {
  cat <<'EOF'
用法：
  scripts/test/test.sh [--layer unit|integration|smoke|all]

说明：
  - 默认执行 unit + integration
  - smoke 依赖真实宿主/浏览器环境，建议按需单独执行

示例：
  scripts/test/test.sh
  scripts/test/test.sh --layer unit
  scripts/test/test.sh --layer integration
  scripts/test/test.sh --layer smoke
  scripts/test/test.sh --layer all
EOF
}

run_unit() {
  bash "${SCRIPT_DIR}/python.sh"
  bash "${SCRIPT_DIR}/skills.sh"
}

run_integration() {
  bash "${SCRIPT_DIR}/shell-integration.sh"
}

run_smoke() {
  bash "${SCRIPT_DIR}/../smoke/hooks/readonly-hook.sh"
}

LAYER="default"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --layer)
      LAYER="${2:-}"
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

case "$LAYER" in
  default)
    log "执行默认测试层：unit + integration"
    run_unit
    run_integration
    ;;
  unit)
    log "执行测试层：unit"
    run_unit
    ;;
  integration)
    log "执行测试层：integration"
    run_integration
    ;;
  smoke)
    log "执行测试层：smoke"
    run_smoke
    ;;
  all)
    log "执行测试层：unit + integration + smoke"
    run_unit
    run_integration
    run_smoke
    ;;
  *)
    die "无效的 --layer：${LAYER}"
    ;;
esac

log "测试执行完成"

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

TEST_DIR="${SCRIPT_DIR}/../../tests/shell"

log "开始执行 Shell 集成测试"

count=0
while IFS= read -r test_file; do
  count=$((count + 1))
  log "运行 ${test_file}"
  bash "$test_file"
done < <(find "${TEST_DIR}" -maxdepth 1 -type f -name 'test_*.sh' | sort)

if [[ "$count" -eq 0 ]]; then
  die "未找到任何 Shell 集成测试"
fi

log "Shell 集成测试完成，共执行 ${count} 个脚本"

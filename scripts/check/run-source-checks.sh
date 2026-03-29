#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

log "开始执行 source-side checks"

log "执行 skill 结构校验"
python3 "${SCRIPT_DIR}/validate-skills.py"

log "执行 runtime skill 一致性校验"
python3 "${SCRIPT_DIR}/check-skill-runtime-parity.py" --enforce-codex-system-only

log "执行关键 Python 单元测试"
python3 -m unittest \
  tests.python.test_managed_config_checks \
  tests.python.test_managed_config_rendering \
  tests.python.test_harness_scaffold \
  tests.python.test_skill_validation_exceptions \
  -v

log "执行 scripts/ Shell 语法检查"
while IFS= read -r shell_file; do
  bash -n "$shell_file"
done < <(find "${REPO_ROOT}/scripts" -type f -name '*.sh' | sort)

log "source-side checks 完成"

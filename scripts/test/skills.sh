#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

log "开始执行 skill 结构校验"
python3 "${SCRIPT_DIR}/../check/validate-skills.py"
log "skill 结构校验完成"

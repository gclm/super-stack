#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

log "开始执行 Python 单元测试"
python3 -m unittest discover -s "${SCRIPT_DIR}/../../tests/python" -p 'test_*.py' -v

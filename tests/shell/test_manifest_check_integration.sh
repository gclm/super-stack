#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

output="$(bash "${REPO_ROOT}/scripts/check/check-global-install.sh" 2>&1 || true)"

printf '%s\n' "$output" | grep -F '== Manifest ==' >/dev/null
printf '%s\n' "$output" | grep -F 'config/manifest.json' >/dev/null

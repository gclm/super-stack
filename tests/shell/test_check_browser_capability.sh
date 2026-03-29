#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

fail() {
  printf '[测试失败] %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local text="$1"
  local expected="$2"
  printf '%s' "$text" | rg -q --fixed-strings -- "$expected" || fail "未找到预期内容：${expected}"
}

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT

export HOME="${TMP_HOME}"
mkdir -p "${HOME}/.codex"

cat > "${HOME}/.codex/config.toml" <<'TOML'
#:schema https://developers.openai.com/codex/config-schema.json

[mcp_servers.chrome-devtools-mcp]
command = "chrome-devtools-mcp"
enabled = true
TOML

output="$(bash "${REPO_ROOT}/scripts/check/check-browser-capability.sh")"
assert_contains "$output" 'ACTIVE_MCP'
assert_contains "$output" 'codex:chrome-devtools-mcp'

printf '[测试通过] check browser capability\n'

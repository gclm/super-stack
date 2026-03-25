#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

fail() {
  printf '[测试失败] %s\n' "$*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "预期文件不存在：${path}"
}

assert_executable() {
  local path="$1"
  [[ -x "$path" ]] || fail "预期文件不可执行：${path}"
}

assert_same_content() {
  local left="$1"
  local right="$2"
  cmp -s "$left" "$right" || fail "文件内容不一致：${left} vs ${right}"
}

TMP_HOME="$(mktemp -d)"
TMP_BIN="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}" "${TMP_BIN}"' EXIT

export HOME="${TMP_HOME}"
export PATH="${TMP_BIN}:${PATH}"

cat > "${TMP_BIN}/agent-browser" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${TMP_BIN}/agent-browser"

mkdir -p "${HOME}/.codex"
printf '#:schema https://developers.openai.com/codex/config-schema.json\n\n' > "${HOME}/.codex/config.toml"

bash "${REPO_ROOT}/scripts/install/install.sh" --host codex >/dev/null

for name in super-stack-browser super-stack-browser-health super-stack-browser-reset; do
  target="${HOME}/.super-stack/runtime/bin/${name}"
  source_file="${REPO_ROOT}/bin/${name}"
  assert_file "${target}"
  assert_executable "${target}"
  assert_same_content "${source_file}" "${target}"
done

printf '[测试通过] install browser wrappers\n'

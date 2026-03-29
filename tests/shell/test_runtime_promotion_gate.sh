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

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT

export HOME="${TMP_HOME}"

l1="$(bash "${REPO_ROOT}/scripts/check/classify-change-risk.sh" --format level docs/architecture/decisions/harness-skill-design.md)"
[[ "${l1}" == "L1" ]] || fail "docs 改动应被分级为 L1，实际为：${l1}"

l2="$(bash "${REPO_ROOT}/scripts/check/classify-change-risk.sh" --format level templates/generated-project/docs/index.md)"
[[ "${l2}" == "L2" ]] || fail "模板改动应被分级为 L2，实际为：${l2}"

l3="$(bash "${REPO_ROOT}/scripts/check/classify-change-risk.sh" --format level scripts/install/install.sh)"
[[ "${l3}" == "L3" ]] || fail "install 改动应被分级为 L3，实际为：${l3}"

promote_output="$(bash "${REPO_ROOT}/scripts/release/promote-to-runtime.sh" docs/architecture/decisions/harness-skill-design.md)"
printf '%s\n' "${promote_output}" | rg -q 'promotion 完成：level=L1' || fail "promotion 输出缺少完成标记"

assert_file "${HOME}/.super-stack/runtime/AGENTS.md"
assert_file "${HOME}/.super-stack/runtime/scripts/hooks/readonly_command_guard.py"
assert_file "${HOME}/.super-stack/runtime/scripts/lib/common.sh"
assert_file "${HOME}/.super-stack/runtime/scripts/check/check-browser-capability.sh"
assert_file "${HOME}/.super-stack/runtime/scripts/check/check-codex-runtime.sh"
assert_file "${HOME}/.super-stack/runtime/scripts/check/validate-skills.py"
assert_file "${HOME}/.super-stack/runtime/scripts/workflow/init-generated-project.sh"
assert_file "${HOME}/.super-stack/runtime/templates/generated-project/docs/index.md"
[[ ! -d "${HOME}/.super-stack/runtime/scripts/install" ]] || fail "runtime 不应包含 scripts/install"
[[ ! -d "${HOME}/.super-stack/runtime/scripts/smoke" ]] || fail "runtime 不应包含 scripts/smoke"
[[ ! -d "${HOME}/.super-stack/runtime/scripts/test" ]] || fail "runtime 不应包含 scripts/test"
[[ ! -d "${HOME}/.super-stack/runtime/scripts/release" ]] || fail "runtime 不应包含 scripts/release"
[[ ! -f "${HOME}/.super-stack/runtime/scripts/lib/install-state.sh" ]] || fail "runtime 不应包含 scripts/lib/install-state.sh"

printf '[测试通过] runtime promotion gate\n'

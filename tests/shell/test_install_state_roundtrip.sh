#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=../../scripts/lib/install-state.sh
source "${REPO_ROOT}/scripts/lib/install-state.sh"

fail() {
  printf '[测试失败] %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local text="$2"
  rg -q --fixed-strings -- "$text" "$path" || fail "未在 ${path} 中找到：${text}"
}

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT
export HOME="${TMP_HOME}"

SUPER_STACK_STATE_ROOT="${HOME}/.super-stack/state"
SUPER_STACK_MANIFEST="${SUPER_STACK_STATE_ROOT}/install-manifest.tsv"
SUPER_STACK_RESTORE_BACKUP_ROOT="${HOME}/.super-stack/backup/install-state"

target_dir="${HOME}/sandbox"
mkdir -p "${target_dir}"

existing_file="${target_dir}/existing.txt"
new_file="${target_dir}/new.txt"

printf 'original\n' > "${existing_file}"

reset_install_state
record_target_state "${existing_file}" "existing"
record_target_state "${new_file}" "new"

printf 'changed\n' > "${existing_file}"
printf 'created\n' > "${new_file}"

restore_recorded_targets

assert_contains "${existing_file}" "original"
[[ ! -e "${new_file}" ]] || fail "new target 应被移除：${new_file}"
assert_contains "$(state_manifest)" $'restore\t'
assert_contains "$(state_manifest)" $'remove\t'
[[ -d "${HOME}/.super-stack/backup/install-state" ]] || fail "install-state 恢复快照目录缺失"

printf '[测试通过] install state roundtrip\n'

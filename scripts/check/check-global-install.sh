#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CODEX_HOME="${HOME}/.codex"
CLAUDE_HOME="${HOME}/.claude"
RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"
USER_AGENTS_HOME="${HOME}/.agents"
STATE_ROOT="${SUPER_STACK_STATE_BASE}"
STATE_MANIFEST="${STATE_ROOT}/install-manifest.tsv"
BACKUP_ROOT="${SUPER_STACK_BACKUP_ROOT}"

SOURCE_REPO_FILE="$(source_repo_path_file)"

RUNTIME_AGENTS="${RUNTIME_ROOT}/AGENTS.md"
RUNTIME_CODEX_AGENTS="${RUNTIME_ROOT}/codex/AGENTS.md"
RUNTIME_CODEX_CONFIG="${RUNTIME_ROOT}/codex/config.toml"
RUNTIME_CLAUDE_FILE="${RUNTIME_ROOT}/claude/CLAUDE.md"
CODEX_AGENTS_FILE="${CODEX_HOME}/AGENTS.md"
CODEX_CONFIG_FILE="${CODEX_HOME}/config.toml"
USER_SKILLS_DIR="${USER_AGENTS_HOME}/skills"
CLAUDE_FILE="${CLAUDE_HOME}/CLAUDE.md"
CLAUDE_SKILLS_DIR="${CLAUDE_HOME}/skills"
CLAUDE_SETTINGS_FILE="${CLAUDE_HOME}/settings.json"
REPO_AGENTS_FILE="${REPO_ROOT}/AGENTS.md"
REPO_CODEX_AGENTS_FILE="${REPO_ROOT}/codex/AGENTS.md"
REPO_CODEX_CONFIG_FILE="${REPO_ROOT}/codex/config.toml"
REPO_CLAUDE_FILE="${REPO_ROOT}/claude/CLAUDE.md"

WARNINGS=0
EXPECTED_SKILL_COUNT=""
EXPECTED_CODEX_BOOTSTRAP=""
EXPECTED_CLAUDE_BOOTSTRAP=""

check_exact_content() {
  local path="$1"
  local expected="$2"
  local label="$3"

  if [[ ! -f "$path" ]]; then
    warn "${label}: 文件缺失（${path}）"
    return
  fi

  local actual
  actual="$(cat "$path")"

  if [[ "$actual" == "$expected" ]]; then
    ok "${label}"
  else
    warn "${label}: 文件内容与预期不一致"
  fi
}

check_same_content() {
  local actual_path="$1"
  local expected_path="$2"
  local label="$3"

  if [[ ! -f "$actual_path" ]]; then
    warn "${label}: 文件缺失（${actual_path}）"
    return
  fi

  if [[ ! -f "$expected_path" ]]; then
    warn "${label}: 预期文件缺失（${expected_path}）"
    return
  fi

  if cmp -s "$actual_path" "$expected_path"; then
    ok "${label}"
  else
    warn "${label}: 文件内容与 ${expected_path} 不一致"
  fi
}

count_skill_entries() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    printf '0'
    return
  fi
  find "$path" -maxdepth 2 -type f -name 'SKILL.md' | wc -l | tr -d ' '
}

count_expected_skill_names() {
  iterate_managed_skill_dirs | while IFS= read -r skill_dir; do basename "$skill_dir"; done | sort -u | wc -l | tr -d ' '
}

count_matching_skill_names() {
  local dest_root="$1"
  local count=0
  local skill_dir

  if [[ ! -d "$dest_root" ]]; then
    printf '0'
    return
  fi

  while IFS= read -r skill_name; do
    if [[ -f "${dest_root}/${skill_name}/SKILL.md" ]]; then
      count=$((count + 1))
    fi
  done < <(iterate_managed_skill_dirs | while IFS= read -r skill_dir; do basename "$skill_dir"; done | sort -u)

  printf '%s' "$count"
}

managed_target_file() {
  managed_config_target_file "$1"
}

check_managed_block_presence() {
  local block="$1"
  local label="$2"
  local target_file
  target_file="$(managed_target_file "$block")"

  if [[ -z "$target_file" ]]; then
    warn "${label}: 未声明 target_file"
    return
  fi

  check_file "$target_file" "${label} 目标文件"

  while IFS= read -r marker; do
    [[ -n "$marker" ]] || continue
    check_contains "$target_file" "$marker" "${label} 受管标记：${marker}"
  done < <(managed_config_lines "$block" markers)
}

check_managed_contains() {
  local block="$1"
  local label="$2"
  local target_file
  target_file="$(managed_target_file "$block")"

  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    check_contains "$target_file" "$item" "${label} 关键字段：${item}"
  done < <(managed_config_lines "$block" contains)
}

check_managed_registered_entries() {
  local block="$1"
  local label="$2"
  local target_file
  target_file="$(managed_target_file "$block")"

  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    check_contains "$target_file" "$entry" "${label} 已注册：${entry}"
  done < <(managed_config_lines "$block" registered_entries)
}

check_managed_files_exist() {
  local block="$1"
  local label="$2"

  while IFS= read -r managed_file; do
    [[ -n "$managed_file" ]] || continue
    check_file "$managed_file" "${label} 受管文件：${managed_file}"
  done < <(managed_config_lines "$block" managed_files)
}

check_managed_commands() {
  local block="$1"
  local label="$2"
  local target_file
  target_file="$(managed_target_file "$block")"

  while IFS= read -r command; do
    [[ -n "$command" ]] || continue
    check_contains "$target_file" "$command" "${label} 已合并：${command}"
  done < <(managed_config_lines "$block" commands)
}

init_expected_values() {
  EXPECTED_SKILL_COUNT="$(count_expected_skill_names)"
  EXPECTED_CODEX_BOOTSTRAP="$(render_host_bootstrap_text "Codex adapter" "${RUNTIME_ROOT}/codex/AGENTS.md" "Global skills: \`${USER_SKILLS_DIR}\`")"
  EXPECTED_CLAUDE_BOOTSTRAP="$(render_host_bootstrap_text "Claude adapter" "${RUNTIME_ROOT}/claude/CLAUDE.md" "Global skills: \`${CLAUDE_SKILLS_DIR}\`")"
}

print_header() {
  printf '== super-stack 全局安装检查 ==\n'
  printf '仓库: %s\n' "${REPO_ROOT}"
  printf 'HOME: %s\n' "${HOME}"
  printf '\n'
}

check_manifest_section() {
  printf '== Manifest ==\n'
  if result="$(python3 "${REPO_ROOT}/scripts/config/validate_manifest.py" 2>&1)"; then
    ok "config/manifest.json 结构与语义校验通过"
    printf '%s\n' "$result"
  else
    warn "config/manifest.json 校验失败"
    printf '%s\n' "$result"
  fi
  printf '\n'
}

check_runtime_section() {
  printf '== Runtime ==\n'
  check_file "$SOURCE_REPO_FILE" "源仓路径记录文件"
  check_file "$RUNTIME_AGENTS" "共享运行仓库 AGENTS"
  check_same_content "$RUNTIME_AGENTS" "$REPO_AGENTS_FILE" "共享运行仓库 AGENTS 与仓库一致"
  check_file "$RUNTIME_CODEX_AGENTS" "运行仓库 Codex adapter"
  check_same_content "$RUNTIME_CODEX_AGENTS" "$REPO_CODEX_AGENTS_FILE" "运行仓库 Codex adapter 与仓库一致"
  check_file "$RUNTIME_CODEX_CONFIG" "运行仓库 Codex config"
  check_same_content "$RUNTIME_CODEX_CONFIG" "$REPO_CODEX_CONFIG_FILE" "运行仓库 Codex config 与仓库一致"
  check_file "$RUNTIME_CLAUDE_FILE" "运行仓库 Claude adapter"
  check_same_content "$RUNTIME_CLAUDE_FILE" "$REPO_CLAUDE_FILE" "运行仓库 Claude adapter 与仓库一致"
  check_dir "$STATE_ROOT" "安装状态目录"
  check_file "$STATE_MANIFEST" "安装状态清单"
  check_dir "$BACKUP_ROOT" "统一备份根目录"
  check_file "${RUNTIME_ROOT}/.codex/hooks/super_stack_state.py" "运行仓库 Codex hook 脚本"
  check_file "${RUNTIME_ROOT}/scripts/hooks/readonly_command_guard.py" "运行仓库 readonly hook 脚本"
  check_file "${RUNTIME_ROOT}/scripts/lib/common.sh" "运行仓库 workflow 公共库"
  check_file "${RUNTIME_ROOT}/scripts/check/check-browser-capability.sh" "运行仓库 browser capability 探针"
  check_same_content "${RUNTIME_ROOT}/scripts/check/check-browser-capability.sh" "${REPO_ROOT}/scripts/check/check-browser-capability.sh" "运行仓库 browser capability 探针与仓库一致"
  check_file "${RUNTIME_ROOT}/scripts/check/check-codex-runtime.sh" "运行仓库 Codex runtime 检查脚本"
  check_same_content "${RUNTIME_ROOT}/scripts/check/check-codex-runtime.sh" "${REPO_ROOT}/scripts/check/check-codex-runtime.sh" "运行仓库 Codex runtime 检查脚本与仓库一致"
  check_file "${RUNTIME_ROOT}/scripts/check/validate-skills.py" "运行仓库 skill 校验脚本"
  check_same_content "${RUNTIME_ROOT}/scripts/check/validate-skills.py" "${REPO_ROOT}/scripts/check/validate-skills.py" "运行仓库 skill 校验脚本与仓库一致"
  check_file "${RUNTIME_ROOT}/scripts/workflow/init-generated-project.sh" "运行仓库 workflow 初始化脚本"
  check_not_exists "${RUNTIME_ROOT}/.git" "运行仓库不包含 Git 元数据"
  check_not_exists "${RUNTIME_ROOT}/.github" "运行仓库不包含 GitHub 配置"
  check_not_exists "${RUNTIME_ROOT}/.idea" "运行仓库不包含 IDE 配置"
  check_not_exists "${RUNTIME_ROOT}/.planning" "运行仓库不包含 planning 状态"
  check_not_exists "${RUNTIME_ROOT}/harness" "运行仓库不包含 source harness 状态"
  check_not_exists "${RUNTIME_ROOT}/docs" "运行仓库不包含 source docs"
  check_not_exists "${RUNTIME_ROOT}/tests" "运行仓库不包含 source tests"
  check_not_exists "${RUNTIME_ROOT}/.agents" "运行仓库不包含 source skills 真源"
  check_not_exists "${RUNTIME_ROOT}/.claude" "运行仓库不包含隐藏 Claude runtime 目录"
  check_not_exists "${RUNTIME_ROOT}/.codex/agents" "运行仓库不包含隐藏 Codex agents 目录"
  check_not_exists "${RUNTIME_ROOT}/scripts/install" "运行仓库不包含 source install 脚本"
  check_not_exists "${RUNTIME_ROOT}/scripts/smoke" "运行仓库不包含 source smoke 脚本"
  check_not_exists "${RUNTIME_ROOT}/scripts/test" "运行仓库不包含 source test 脚本"
  check_not_exists "${RUNTIME_ROOT}/scripts/release" "运行仓库不包含 source release 脚本"
  check_not_exists "${RUNTIME_ROOT}/scripts/lib/install-state.sh" "运行仓库不包含 source install-state 库"
  printf '\n'
}

check_codex_section() {
  printf '== Codex ==\n'
  check_file "$CODEX_AGENTS_FILE" "Codex 全局 AGENTS"
  check_file "$CODEX_CONFIG_FILE" "Codex 配置文件"
  check_dir "$USER_SKILLS_DIR" "用户 skills 目录"
  check_exact_content "$CODEX_AGENTS_FILE" "$EXPECTED_CODEX_BOOTSTRAP" "Codex bootstrap 内容符合预期"
  check_managed_block_presence "codex_agents" "Codex agents"
  check_managed_contains "codex_agents" "Codex agents"
  check_managed_registered_entries "codex_agents" "Codex agent"
  check_managed_files_exist "codex_agents" "Codex agent"
  check_managed_block_presence "codex_hooks" "Codex hooks"
  check_managed_commands "codex_hooks" "Codex hook"
  check_managed_block_presence "codex_mcp" "Codex MCP"
  check_managed_contains "codex_mcp" "Codex MCP"
  printf 'Codex 用户可见 skills 总数: %s\n' "$(count_skill_entries "$USER_SKILLS_DIR")"
  printf 'Codex 受管 skill 匹配数: %s/%s\n' "$(count_matching_skill_names "$USER_SKILLS_DIR")" "$EXPECTED_SKILL_COUNT"
  printf '\n'
}

check_claude_section() {
  printf '== Claude ==\n'
  check_file "$CLAUDE_FILE" "Claude 全局 CLAUDE.md"
  check_dir "$CLAUDE_SKILLS_DIR" "Claude 全局 skills 目录"
  check_file "$CLAUDE_SETTINGS_FILE" "Claude settings"
  check_exact_content "$CLAUDE_FILE" "$EXPECTED_CLAUDE_BOOTSTRAP" "Claude bootstrap 内容符合预期"
  check_managed_block_presence "claude_hooks" "Claude hooks"
  check_managed_commands "claude_hooks" "Claude hook"
  check_managed_contains "claude_mcp" "Claude MCP"
  printf 'Claude 镜像 skills 总数: %s\n' "$(count_skill_entries "$CLAUDE_SKILLS_DIR")"
  printf 'Claude 受管 skill 匹配数: %s/%s\n' "$(count_matching_skill_names "$CLAUDE_SKILLS_DIR")" "$EXPECTED_SKILL_COUNT"
  printf '\n'
}

check_browser_section() {
  local result
  printf '== Browser ==\n'

  result="$("${SCRIPT_DIR}/check-browser-capability.sh")"
  case "$(printf '%s' "$result" | sed -n '1p')" in
    ACTIVE_LOCAL)
      printf '浏览器能力：检测到本地 browser provider（%s）\n' "$(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g')"
      ;;
    ACTIVE_MCP)
      printf '浏览器能力：检测到已激活的 browser MCP（%s）\n' "$(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g')"
      ;;
    ACTIVE_PLUGIN)
      printf '浏览器能力：检测到已激活的 browser plugin（%s）\n' "$(printf '%s' "$result" | tr '\n' ' ' | sed 's/  */ /g')"
      ;;
    INSTALLED_ONLY)
      printf '浏览器能力：browser plugin 已安装但未启用（%s）\n' "$(printf '%s' "$result" | sed -n '2p')"
      ;;
    *)
      printf '浏览器能力：未检测到受管 browser provider。当前 super-stack 不再安装 agent-browser wrapper；浏览器能力由宿主 MCP 或 browser plugin 自行提供。\n'
      ;;
  esac
  printf '\n'
}

check_policy_section() {
  printf '== 策略 ==\n'
  printf '当前记录的 source repo: %s\n' "$(cat "$SOURCE_REPO_FILE" 2>/dev/null || true)"
  check_contains "$CODEX_AGENTS_FILE" "${RUNTIME_ROOT}/codex/AGENTS.md" "Codex bootstrap 已指向 runtime adapter"
  check_contains "$CLAUDE_FILE" "${RUNTIME_ROOT}/claude/CLAUDE.md" "Claude bootstrap 已指向 runtime adapter"
  printf '\n'
}

print_result() {
  if [[ "$WARNINGS" -eq 0 ]]; then
    printf '结果：通过\n'
    printf 'super-stack 仅全局模式安装看起来正常。\n'
  else
    printf '结果：警告（%s 个问题）\n' "$WARNINGS"
    printf '请检查上面的警告；如有需要，重新执行 ./scripts/install/install.sh --host all。\n'
  fi
}

main() {
  init_expected_values
  print_header
  check_manifest_section
  check_runtime_section
  check_codex_section
  check_claude_section
  check_browser_section
  check_policy_section
  print_result
}

main "$@"

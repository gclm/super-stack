#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/checks.sh
source "${SCRIPT_DIR}/../lib/checks.sh"

CODEX_HOME="${HOME}/.codex"
CLAUDE_HOME="${HOME}/.claude"
USER_AGENTS_HOME="${HOME}/.agents"

CODEX_STACK_AGENTS="${CODEX_HOME}/super-stack/AGENTS.md"
CODEX_AGENTS_FILE="${CODEX_HOME}/AGENTS.md"
CODEX_CONFIG_FILE="${CODEX_HOME}/config.toml"
USER_SKILLS_DIR="${USER_AGENTS_HOME}/skills"
CLAUDE_STACK_AGENTS="${CLAUDE_HOME}/super-stack/AGENTS.md"
CLAUDE_FILE="${CLAUDE_HOME}/CLAUDE.md"
CLAUDE_SKILLS_DIR="${CLAUDE_HOME}/skills"
CLAUDE_SETTINGS_FILE="${CLAUDE_HOME}/settings.json"
REPO_AGENTS_FILE="${REPO_ROOT}/AGENTS.md"
REPO_SKILLS_DIR="${REPO_ROOT}/.agents/skills"

WARNINGS=0

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
  find "${REPO_SKILLS_DIR}" -maxdepth 2 -mindepth 2 -type d | wc -l | tr -d ' '
}

count_matching_skill_names() {
  local dest_root="$1"
  local count=0
  local skill_dir

  if [[ ! -d "$dest_root" ]]; then
    printf '0'
    return
  fi

  while IFS= read -r skill_dir; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    if [[ -f "${dest_root}/${skill_name}/SKILL.md" ]]; then
      count=$((count + 1))
    fi
  done < <(find "${REPO_SKILLS_DIR}" -maxdepth 2 -mindepth 2 -type d | sort)

  printf '%s' "$count"
}

printf '== super-stack 全局安装检查 ==\n'
printf '仓库: %s\n' "${REPO_ROOT}"
printf 'HOME: %s\n' "${HOME}"
printf '\n'

EXPECTED_SKILL_COUNT="$(count_expected_skill_names)"

EXPECTED_CODEX_AGENTS=$(cat <<EOF
# Super Stack Global Router

Use \`${CODEX_HOME}/super-stack/AGENTS.md\` as the global workflow source.

- This is the default global workflow router for Codex.
- This repository is the single global workflow source managed by super-stack.
- Global super-stack skills are installed to \`${USER_SKILLS_DIR}\`.
- Treat global super-stack as the canonical system configuration.
EOF
)

EXPECTED_CLAUDE_ROUTER=$(cat <<EOF
# Super Stack Global Router

Use \`${CLAUDE_HOME}/super-stack/AGENTS.md\` as the shared global workflow source.

- This is the default global workflow router for Claude.
- This repository is the single global workflow source managed by super-stack.
- Global Claude-facing skills are mirrored into \`${CLAUDE_SKILLS_DIR}\`.
- Treat global super-stack as the canonical system configuration.
EOF
)

printf '== Codex ==\n'
check_file "$CODEX_STACK_AGENTS" "Codex 共享栈 AGENTS"
check_file "$CODEX_AGENTS_FILE" "Codex 全局 AGENTS"
check_file "$CODEX_CONFIG_FILE" "Codex 配置文件"
check_dir "$USER_SKILLS_DIR" "用户 skills 目录"
check_same_content "$CODEX_STACK_AGENTS" "$REPO_AGENTS_FILE" "Codex 共享栈 AGENTS 与仓库一致"
check_exact_content "$CODEX_AGENTS_FILE" "$EXPECTED_CODEX_AGENTS" "Codex 全局路由内容符合预期"
check_contains "$CODEX_CONFIG_FILE" "super_stack_state.py" "Codex hooks 已合并"
check_contains "$CODEX_CONFIG_FILE" "readonly_command_guard.py" "Codex 只读自动放行 hook 已合并"
printf 'Codex 用户可见 skills 总数: %s\n' "$(count_skill_entries "$USER_SKILLS_DIR")"
printf 'Codex 受管 skill 匹配数: %s/%s\n' "$(count_matching_skill_names "$USER_SKILLS_DIR")" "$EXPECTED_SKILL_COUNT"
printf '\n'

printf '== Claude ==\n'
check_file "$CLAUDE_STACK_AGENTS" "Claude 共享栈 AGENTS"
check_file "$CLAUDE_FILE" "Claude 全局 CLAUDE.md"
check_dir "$CLAUDE_SKILLS_DIR" "Claude 全局 skills 目录"
check_file "$CLAUDE_SETTINGS_FILE" "Claude settings"
check_same_content "$CLAUDE_STACK_AGENTS" "$REPO_AGENTS_FILE" "Claude 共享栈 AGENTS 与仓库一致"
check_exact_content "$CLAUDE_FILE" "$EXPECTED_CLAUDE_ROUTER" "Claude 全局路由内容符合预期"
check_contains "$CLAUDE_SETTINGS_FILE" "[super-stack] resuming from .planning/STATE.md" "Claude SessionStart hook 已合并"
check_contains "$CLAUDE_SETTINGS_FILE" "readonly_command_guard.py" "Claude 只读自动放行 hook 已合并"
check_contains "$CLAUDE_SETTINGS_FILE" "[super-stack] remember to leave STATE.md current" "Claude Stop hook 已合并"
printf 'Claude 镜像 skills 总数: %s\n' "$(count_skill_entries "$CLAUDE_SKILLS_DIR")"
printf 'Claude 受管 skill 匹配数: %s/%s\n' "$(count_matching_skill_names "$CLAUDE_SKILLS_DIR")" "$EXPECTED_SKILL_COUNT"
printf '\n'

printf '== 策略 ==\n'
check_contains "$CODEX_AGENTS_FILE" "single global workflow source managed by super-stack" "Codex 已使用仅全局路由"
check_contains "$CLAUDE_FILE" "single global workflow source managed by super-stack" "Claude 已使用仅全局路由"
printf '\n'

if [[ "$WARNINGS" -eq 0 ]]; then
  printf '结果：通过\n'
  printf 'super-stack 仅全局模式安装看起来正常。\n'
else
  printf '结果：警告（%s 个问题）\n' "$WARNINGS"
  printf '请检查上面的警告；如有需要，重新执行 ./scripts/install/install.sh --host all。\n'
fi

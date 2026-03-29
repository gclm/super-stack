#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/install-state.sh
source "${SCRIPT_DIR}/../lib/install-state.sh"

CODEX_HOME="${HOME}/.codex"
RUNTIME_ROOT="${SUPER_STACK_RUNTIME_ROOT}"
AGENTS_DEST="${CODEX_HOME}/agents"
CODEX_SKILLS_DEST="${CODEX_HOME}/skills"
USER_AGENTS_HOME="${HOME}/.agents"
USER_SKILLS_DEST="${USER_AGENTS_HOME}/skills"
RENDER_SCRIPT="${SCRIPT_DIR}/../config/render_managed_config.py"

merge_managed_block() {
  local block="$1"
  local config_file="$2"
  local begin_marker="$3"
  local end_marker="$4"
  local rendered_block=""
  case "$block" in
    codex_agents)
      rendered_block="$(python3 "$RENDER_SCRIPT" --block "$block")"
      ;;
    codex_hooks)
      rendered_block="$(python3 "$RENDER_SCRIPT" --block "$block" --runtime-root "$RUNTIME_ROOT" --config-file "$config_file")"
      ;;
    codex_mcp)
      rendered_block="$(python3 "$RENDER_SCRIPT" --block "$block")"
      if [[ -z "$rendered_block" ]]; then
        log "未检测到可用的 Codex MCP server 定义，可先跳过 Codex MCP 受管块。后续如已安装相关 MCP，可重新执行 scripts/install/install.sh --host codex。"
        return 0
      fi
      ;;
    *)
      die "unsupported codex managed block: ${block}"
      ;;
  esac

  append_managed_block "$config_file" "$begin_marker" "$end_marker" "$rendered_block"
}

ensure_dir "$AGENTS_DEST"
ensure_dir "$CODEX_SKILLS_DEST"

record_target_state "${CODEX_HOME}/AGENTS.md" "codex_AGENTS.md"
record_target_state "${CODEX_HOME}/config.toml" "codex_config.toml"
record_target_state "$RUNTIME_ROOT" "runtime_super-stack"

copy_runtime_tree "$RUNTIME_ROOT"
mirror_repo_skills "$USER_SKILLS_DEST"

# Codex skills directory keeps only host/system-local skills.
# Global super-stack skills are provided via ~/.agents/skills.

for agent_file in "${REPO_ROOT}"/.codex/agents/*.toml; do
  cp "$agent_file" "${AGENTS_DEST}/$(basename "$agent_file")"
done

write_global_router_file "${CODEX_HOME}/AGENTS.md" "global workflow source" "Codex" "Global super-stack skills are installed to \`${USER_SKILLS_DEST}\`."

write_if_missing "${REPO_ROOT}/.codex/config.toml" "${CODEX_HOME}/config.toml"
merge_managed_block "codex_agents" "${CODEX_HOME}/config.toml" "# BEGIN SUPER-STACK AGENTS" "# END SUPER-STACK AGENTS"
merge_managed_block "codex_hooks" "${CODEX_HOME}/config.toml" "# BEGIN SUPER-STACK HOOKS" "# END SUPER-STACK HOOKS"
merge_managed_block "codex_mcp" "${CODEX_HOME}/config.toml" "# BEGIN SUPER-STACK CODEX MCP" "# END SUPER-STACK CODEX MCP"

log "已将纯运行仓库资产复制到 ${RUNTIME_ROOT}"
log "已将 Codex 全局资产复制到 ${CODEX_HOME}"
log "已将 skills 安装到 ${USER_SKILLS_DEST}"
log "已保留 Codex 本地 skills 目录（仅宿主/system 技能）: ${CODEX_SKILLS_DEST}"
log "已更新 ${CODEX_HOME}/AGENTS.md 中的全局路由"
log "已将 Codex agents 配置合并到 ${CODEX_HOME}/config.toml"
log "已将 Codex hooks 合并到 ${CODEX_HOME}/config.toml"
log "已按可用性处理 Codex MCP 受管块"
log "Codex 已启用仅全局模式。"
log "如果你已自定义 ~/.codex/config.toml，请在手动合并 super-stack 设置前先审阅。"

# Harness State

- status: cutover_complete
- active phase: maintenance
- current focus: source repo 已完成可见路径收敛（`skills/`、`codex/`、`claude/`）；当前重点是继续收紧 runtime，只保留 host adapter、运行态必需 `hooks + workflow` 与其最小依赖，避免把 source 运维脚本带进 runtime。
- active constraints:
  - OpenSpace 目前停在 Layer-A，不继续扩展到自动 source edit 或 runtime promotion。
- active decisions:
  - `docs/` 承担长期知识与设计说明，`harness/state.md` 仅保留当前执行态。
  - 稳定策略与流程变更必须在同一变更集追加到 `harness/history.md`。
  - `run-source-checks.sh` 已纳入 runtime parity 与 harness 状态治理检查。
  - source repo 使用可见路径 `skills/`、`codex/`、`claude/`；home/runtime 继续保留 `~/.agents/skills`、`~/.codex`、`~/.claude` 与 runtime `/.codex/hooks` 兼容路径。
  - home 侧 `~/.codex/AGENTS.md` 与 `~/.claude/CLAUDE.md` 只保留 bootstrap 职责；runtime 负责提供共享主路由与 host adapter 正文。
  - runtime `scripts/` 只保留运行态必需子集：`hooks/`、`workflow/` 与 `scripts/lib/common.sh` 保留，`install`、`smoke`、`test`、`release` 与 `scripts/lib/install-state.sh` 不进入 runtime。
- next actions:
  - 持续观测下游工具、提示词和文档是否仍假设 source repo 存在 `.agents`、`.codex`、`.claude`，或假设 home 入口文件承载完整正文、runtime 持有完整 scripts。
  - 如安装策略变化，确保 `install-*`、`check-*`、`history` 与 source/runtime 路径约定同步更新。

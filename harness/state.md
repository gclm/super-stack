# Harness State

- status: cutover_complete
- active phase: maintenance
- current focus: 运行时技能边界已收敛（`~/.codex/skills` 仅 `.system`）；当前重点是 `scripts/release + scripts/workflow` 目录重构落地与 source checks 持续防漂移。
- active constraints:
  - OpenSpace 目前停在 Layer-A，不继续扩展到自动 source edit 或 runtime promotion。
- active decisions:
  - `docs/` 承担长期知识与设计说明，`harness/state.md` 仅保留当前执行态。
  - 稳定策略与流程变更必须在同一变更集追加到 `harness/history.md`。
  - `run-source-checks.sh` 已纳入 runtime parity 与 harness 状态治理检查。
- next actions:
  - 持续观测 `check-harness-state.sh` 的阈值是否需要按项目规模微调。
  - 如安装策略变化，确保 `install-*`、`check-*`、`history` 同步更新。

# Harness State

- status: cutover_complete
- active phase: maintenance
- current focus: 活跃文档收口已完成；`docs/ + harness/` 单真源生效。当前重点转向 source checks 一致性验证与 routine 演进。
- active constraints:
  - OpenSpace 目前停在 Layer-A，不继续扩展到自动 source edit 或 runtime promotion。
- active decisions:
  - `docs/` 承担长期知识与设计说明。
  - `harness/state.md` 只承担当前执行态摘要；历史变更与已落地决策记入 `harness/history.md`。
  - `config/manifest.json` 是配置真源。
- next actions:
  - 持续用 source checks 验证 generated-project 与 source repo 结构一致。
  - 补一轮 `map-codebase` 演练，验证 `ContextWeaver` 可用时的检索路径与 `minimal` 产出契约。

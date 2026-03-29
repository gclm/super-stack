# Harness State

- status: cutover_in_progress
- active phase: legacy-state cutover phase 4
- current focus: 收口 source repo 自身到 `docs/ + harness/` 单真源，当前已将 source repo 文档重排到 `overview / architecture / guides / reference` 四层，并继续把已基本拍板的架构文档从 `architecture/proposals/` 压到 `decisions/` 或 `guides/`。
- active constraints:
  - 当前仓库仍处于迁移期，legacy `.planning/STATE.md` 仍需保持同步，直到 cutover 完成。
  - 不做长期兼容层，但允许短期迁移并行以完成消费者切换。
  - OpenSpace 目前停在 Layer-A，不继续扩展到自动 source edit 或 runtime promotion。
- current decision:
  - `docs/` 承担长期知识与设计说明。
  - `docs/` 内部统一按 `overview / architecture / guides / reference` 四层导航，`decisions` 与 `proposals` 归入 `architecture/`。
  - `harness/state.md` 承担执行态摘要。
  - 验证矩阵统一沉到 `docs/reference/validation/` 与 generated-project 镜像，不再保留独立模板目录。
  - host-generated hook/log 统一写入 `harness/.runtime/`。
- next actions:
  - 收口活跃文档中的 legacy 说明，只保留迁移/历史语境引用
  - 继续清理少量根级旧文件路径心智残留，避免后续新增文档再回到 `docs/*.md` 平铺模式
  - 继续评估何时停止同步 legacy `.planning/STATE.md`
  - 持续用 source checks 验证 generated-project 与 source repo 结构一致

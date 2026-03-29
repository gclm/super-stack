# 路线图

## 当前阶段
- legacy-state cutover phase 1-3 已完成：
  - 根路由、Codex adapter、hooks、managed config 与核心 stage skills 已切到 `docs/ + harness/`
  - `map-codebase` 输出契约已改为 `docs/reference/codebase/`
  - generated-project 模板已补 `docs/reference/codebase/README.md`
  - upstream OpenSpace skill 的薄入口 warning 已改为受管例外规则，而不是继续人工记忆
- legacy-state cutover phase 4 正在进行：
  - source repo 自身的验证参考已迁入 `docs/reference/validation/`
  - generated-project 模板已同步 `docs/reference/validation/`
  - `templates/planning` 与 `templates/validation` 已删除
- OpenSpace 当前只保留 Layer-A：
  - MCP server
  - `OPENSPACE_HOST_SKILL_DIRS`
  - `OPENSPACE_WORKSPACE`
  - upstream `delegate-task` / `skill-discovery` skills

## 后续阶段
- Phase 5：收口剩余 legacy 文案、repo-bootstrap 迁移说明与 `.planning/STATE.md` 同步策略
- Final cleanup：让活跃路径只剩 `docs/ + harness/`，legacy 引用仅保留在迁移/历史文档中

## 暂缓事项
- OpenSpace Layer-B / Layer-C
- runtime 自动推广增强层
- 重型 scheduler / worktree orchestration / observability 栈

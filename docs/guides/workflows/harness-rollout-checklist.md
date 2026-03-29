# harness / OpenSpace / runtime gate 落地清单

这份文档把当前已拍板的方案拆成可执行 workstreams。

当前已固定的前提：

- 当前 `super-stack` 仓库是 canonical source repo
- `~/.super-stack/runtime` 是受管运行副本
- OpenSpace 可以在受控范围内直接修改 source repo working tree
- runtime 只通过 promotion gate 接收变更
- target project 默认结构采用 `llmdoc-inspired docs/ + harness/`

本文不再重复讨论“要不要这样设计”，只讨论“按这个设计怎么落地”。

## 1. 实施目标

这一轮实施要交付 6 类结果：

1. target project 模板骨架
2. `harness` skill 组骨架
3. source-side check 与 runtime gate 的实现入口
4. OpenSpace 接线与权限边界
5. `.planning` 退场与迁移策略
6. 最小验证矩阵与 rollout 顺序

## 2. Workstream A：target project 模板

目标：把 `llmdoc-inspired docs/ + harness/` 变成真正可生成的模板，而不是只停留在方案文档里。

### 2.1 要新增的模板目录

推荐新增：

```text
templates/generated-project/
  docs/
    index.md
    overview/
      project-overview.md
      roadmap.md
    architecture/
      system-overview.md
      proposals/
      decisions/
    guides/
      workflows/
      runbooks/
    reference/
      conventions.md
  harness/
    state.md
    tasks/
      _task-template/
        brief.md
        progress.md
        decisions.md
        evidence-index.json
        verdict.json
```

### 2.2 这一组要解决什么

- 让 target project 初始化时有明确默认结构
- 避免每次靠 agent 临时拼目录
- 固定 `docs/` 和 `harness/` 的最小 contract

### 2.3 验证方式

- 模板目录可被生成脚本完整复制
- 生成后路径结构与方案文档一致
- `docs/index.md`、`harness/state.md`、`harness/history.md`、task 模板文件均存在

### 2.4 依赖

- 无前置代码依赖
- 但命名应与主提案文档保持一致

## 3. Workstream B：generated project 生成器

目标：把模板真正接入初始化命令，而不是只把模板放在仓库里。

### 3.1 需要补的能力

- 初始化 target project `docs/`
- 初始化 target project `harness/`
- 创建新 `task-id` 时生成 task skeleton
- 后续可选接一次性 `.planning` 迁移

### 3.2 可能新增路径

推荐新增：

```text
scripts/workflow/
  init-generated-project.sh
  init-harness-task.sh
  migrate-planning-to-harness.sh
```

如果脚本需要 Python：

```text
scripts/workflow/
  init_harness_task.py
  migrate_planning_to_harness.py
```

### 3.3 需要输出什么

- `init-generated-project`：落 target project 默认结构，由 `repo-bootstrap` 在 inspect repo 后按条件调用
- `init-harness-task`：创建 `harness/tasks/<task-id>/...`
- `migrate-planning-to-harness`：一次性迁移旧 `.planning` 信息

### 3.4 验证方式

- 新目录生成幂等
- 再次执行不会重复破坏已有内容
- task skeleton 生成字段齐全
- 迁移脚本至少能正确提炼 `STATE -> harness/state.md`、`HISTORY -> harness/history.md`、`ROADMAP -> docs/overview/roadmap.md`

## 4. Workstream C：`harness` skill 组骨架

目标：先把 skill 组目录和 concrete skill 自包含资源骨架搭起来，再逐步填充能力。

### 4.1 推荐目录

```text
skills/harness/
  task-harness/
    SKILL.md
    references/
    assets/
  closed-loop-testing/
    SKILL.md
    references/
    assets/
  architecture-guardrails/
    SKILL.md
    references/
  harness-marathon/
    SKILL.md
    references/
    assets/
```

### 4.2 phase-1 只做什么

- 先建目录和薄入口 `SKILL.md`
- 先把 references / assets 下沉到 concrete skill
- 不在第一步就把所有自动化脚本补满

### 4.3 验证方式

- `validate-skills.py` 可识别新 skill 组结构
- 每个 concrete skill 都能自带所需 references / assets
- 没有和现有 `core / planning / quality / ship` 分类发生触发冲突

## 5. Workstream D：runtime promotion gate 实装

目标：把当前门禁方案从设计文档变成可执行链路。

### 5.1 需要落地的能力

- 变更分级判定
- source-side check 聚合入口
- 按级别触发 smoke
- 通过后 sync 到 runtime
- runtime install/check/smoke 入口

### 5.2 推荐新增或改造点

优先考虑：

- 新增一个 gate orchestrator
- 或在现有 `scripts/check/`、`scripts/smoke/` 外层加一个 promotion wrapper

推荐路径：

```text
scripts/check/
  run-source-checks.sh
  classify-change-risk.sh

scripts/smoke/
  run-targeted-smoke.sh

scripts/release/
  promote-to-runtime.sh
```

当前建议使用 `scripts/release/` 承载 promotion orchestrator；`scripts/workflow/` 承载开发流程脚本（如初始化与 worktree 管理）。

### 5.3 phase-1 的最小实现

- L1 / L2 / L3 分类规则先表驱动或路径驱动
- 先支持人工触发的 promotion，不急着做全自动
- 先接最关键的 check/smoke，不要求一开始就全覆盖

### 5.4 验证方式

- 给一个 L1 样例改动，能跑 source-side check 并允许 promotion
- 给一个 L2 样例改动，能触发 targeted smoke
- 给一个 L3 样例改动，能要求人工 review 标志
- runtime 失败时能明确回退到 source repo 修复

## 6. Workstream E：OpenSpace 接线

目标：把 OpenSpace 从“概念 backend”变成真正可连通的宿主能力。

### 6.1 要接的层次

- MCP server 注册
- host skills 接入
- source repo draft edit 权限边界
- source-side checks 触发
- runtime promotion 对接点

### 6.2 需要新增或改造的点

推荐先补：

- OpenSpace 安装说明或安装脚本
- managed config 对 `openspace` server 的定义
- OpenSpace 可执行检查
- source repo direct edit 开关或受管配置

### 6.3 phase-1 的最小接法

- 先 local-only
- 先不开 cloud community
- 先允许低风险 source repo draft edit
- 先不把高风险路径交给 OpenSpace 自动改

### 6.4 验证方式

- `openspace-mcp` 命令可用
- 宿主可发现 `openspace` MCP server
- OpenSpace 可对 source repo 受控路径产出草稿改动
- 改动后可自动触发 source-side check

## 7. Workstream F：`codex-record-retrospective` 升级

目标：把 retrospective 从“报告生成器”推进为“lesson -> source repo edit / proposal -> runtime promotion”的前置适配层。

### 7.1 需要新增的职责

- lesson 到 change target 的映射
- 变更等级建议
- 直接改 source repo 或生成 patch proposal 的分流
- 输出 promotion 所需 evidence

### 7.2 可能新增的点

- lesson -> target map 扩展
- recommendation schema 增加 risk level / promotion hints
- retrospective post-processing 增加 source-side gate hooks

### 7.3 验证方式

- 给一个 retrospective 样例，可产出 target path 与风险等级
- 能区分“可直接改 source repo”和“必须人工 review”的候选项

## 8. Workstream G：`.planning` 退场迁移

目标：把旧 project database 的有价值信息迁到新模型，不做长期兼容层。

### 8.1 迁移口径

- `.planning/STATE.md` -> `harness/state.md`
- `.planning/HISTORY.md` -> `harness/history.md`
- `.planning/ROADMAP.md` -> `docs/overview/roadmap.md`
- `.planning/PROJECT.md` -> `docs/overview/project-overview.md` 或废弃
- `.planning/REQUIREMENTS.md` -> proposal / ADR / reference 或废弃
- `.planning/codebase/*` -> 默认废弃

### 8.2 决策点

- 是否给迁移脚本
- 哪些字段保留，哪些只做摘要提炼
- 是否保留 demo 迁移样例

### 8.3 验证方式

- 对一个旧 `.planning` 样例执行迁移
- 迁移后路径正确
- 迁移后不再依赖 `.planning` 才能继续工作

## 9. Workstream H：验证矩阵

目标：避免实现完成后没有统一验证口径。

### 9.1 source-side 验证

至少包括：

- `validate-skills.py`
- 相关脚本语法/单测
- managed config 校验
- 新模板/生成器的幂等性检查

### 9.2 runtime-side 验证

至少包括：

- sync 完整性
- install/check-global-install
- host wiring
- 关键 smoke

### 9.3 文档级验证

至少包括：

- 主提案、OpenSpace、harness skill 设计、runtime gate、实施清单之间互相引用正确
- `STATE.md` 与方案口径一致

## 10. phase-1 推荐顺序

推荐按下面顺序推进：

1. target project 模板
2. harness skill 组骨架
3. 生成器
4. source-side check 聚合
5. runtime promotion gate 最小实现
6. OpenSpace 最小接线
7. retrospective adapter 升级
8. `.planning` 一次性迁移

原因：

- 没模板和 skill 骨架，后面的接线没有稳定目标
- 没 source-side checks，就不该接 OpenSpace 直接改 source repo
- 没 promotion gate，就不该让 runtime 承接自动改动

## 11. phase-1 的 Done 定义

phase-1 结束时，至少应满足：

- 能生成 target project 的 `docs/ + harness/` 默认结构
- `skills/harness/` 已存在并通过结构校验
- 有最小的 source-side check 聚合入口
- 有最小的 runtime promotion gate
- OpenSpace 能在低风险范围内对 source repo 产出草稿改动
- runtime 仍然只通过 promotion 流更新

## 12. 建议的第一批具体改动

如果下一步进入真正代码实现，我建议第一批只做这几件事：

1. 建 `templates/generated-project/docs/` 和 `templates/generated-project/harness/`
2. 建 `skills/harness/` 骨架，并把入口 skill 命名为 `task-harness`
3. 建 `scripts/workflow/init-harness-task.*`
4. 建 source-side check 聚合入口
5. 建 runtime promotion wrapper 的空骨架

这五件事足够形成第一批可验证里程碑，而且不会一下子把 OpenSpace、迁移、运行态全混在一起。

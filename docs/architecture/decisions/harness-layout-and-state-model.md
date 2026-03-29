# harness 布局与状态模型决策

这份文档记录当前已经拍板的两件事：

- `super-stack` 作为 workflow source repo，应该为 target project 生成什么结构
- `super-stack` 作为当前 source repo 自身，如何让 OpenSpace 参与 skills 演进，同时仍保持 `source repo -> runtime repo` 的受管推广链

当前正式采用三层架构：

1. `source repo layout`
2. `generated project layout`
3. `OpenSpace backend`

但要补一个关键边界：

- `~/.super-stack/runtime` 不是第四层真源
- 它是 `source repo` 的受管运行副本和推广目标
- OpenSpace 如果参与自动修改，主要编辑面应是当前 source repo working tree，而不是 runtime

## 1. 决策结论

### 1.1 推荐方案

推荐采用下面这组边界：

- `source repo`：维护 workflow 真源、skills、templates、generators
- `generated project`：落地 repo-local `docs/ + harness/`
- `OpenSpace backend`：承接 host-level memory、lineage、skill evolution backend
- `runtime repo`：`source repo` 的受管运行副本，只通过 sync / promotion gate 更新

一句话概括：

- target project 的长期知识层用 `llmdoc-inspired docs/`
- target project 的执行态层用 `harness/`
- 当前 `super-stack` 仓库仍然是 canonical source repo
- OpenSpace 可以在受控范围内直接修改 source repo working tree
- runtime 只通过受管同步与检查链推广，不作为主要编辑对象

### 1.2 保留、移除、替代

保留：

- `plan` stage
- 4 个独立的 `harness` skills
- repo-local task state / evidence
- source repo first
- `source repo -> runtime repo` 的单向推广模型
- 分级 `check / smoke / review` gate

移除或退场：

- `.planning` 作为 target project 默认 project database
- `PROJECT / REQUIREMENTS / ROADMAP / STATE` 作为所有任务默认必填产物
- `artifacts/` 作为 target project 默认杂项输出桶
- `~/.super-stack/projects/<slug>/` 作为长期 host-level 目录方案
- 直接编辑 runtime 作为技能演进主路径

替代：

- target project 内：`llmdoc-inspired docs/ + harness/`
- host-level backend：OpenSpace
- runtime 变更控制：`source repo direct edit + runtime promotion gate`

### 1.3 当前仓库的语义

这一点需要明确写死：

- 当前仓库 `super-stack` 是 source repo / 原厂库 / canonical git truth
- `~/.super-stack/runtime` 是运行副本，不是研发真源
- OpenSpace 若参与改动，应优先修改当前 source repo working tree
- runtime 通过同步链接收推广后的变更

这意味着：

- “OpenSpace 不能直接改当前项目”这个说法不成立
- 正确说法是“OpenSpace 不应直接改 runtime”

## 2. 为什么这样选

## 2.1 不是继续沿用 `.planning`

`.planning` 借来了 GSD 风格的强状态模型，但默认成本过高：

- 日常任务被迫补齐一整套 project database
- 计划文档、长期知识、执行态证据混在一层
- 需要围绕 `.planning` 长期维护工具链和迁移逻辑

我们保留 `plan` stage，但不再把 `.planning` 当作 target project 的默认落盘模型。

## 2.2 也不是只靠 `llmdoc`

`llmdoc` 对 target project 的 `docs/` 很合适，但它解决的是长期知识组织，不是执行态管理。

如果只有 `docs/`，就会出现两个问题：

- 任务进度、证据、临时决策重新污染长期文档
- `review / verify / qa` 缺少稳定的 repo-local execution truth

因此 `llmdoc-inspired docs/` 只能覆盖知识层，不能替代 `harness/`。

## 2.3 也不是把所有长期记忆塞回宿主目录

`~/.super-stack/projects/<slug>/` 这种自建 host-level 目录方案可以工作，但会继续带来：

- schema 和采集链都要自己维护
- lineage / import / export / search 要重复造轮子
- 很容易把 source repo、target project、host state 混成一套系统

OpenSpace 更适合作为这一层的 backend。

## 2.4 也不是让 OpenSpace 直接改 runtime

如果让 OpenSpace 直接改 `~/.super-stack/runtime`，会有两个明显问题：

- runtime 不是完整研发面，很多 docs / tests / references / review 线索都不在那边
- `source repo -> runtime` 的单向关系会被破坏，回滚和审计都会变差

因此效率真正应该来自：

- OpenSpace 直接改 source repo
- 自动跑 source-side checks
- 通过后再同步到 runtime
- runtime 再做 install/check/smoke 验证

## 2.5 推荐结构的本质

推荐方案不是“换一个目录名”，而是把四类职责分开：

- source-of-truth workflow assets -> `source repo`
- project-local collaboration and execution truth -> `generated project`
- host-level long-term memory and skill evolution -> `OpenSpace`
- operational rollout target -> `runtime repo`

其中最后一类不是新真源，只是推广目标。

## 3. 三层架构总览

```text
+-------------------------------------------------------------+
| Layer 1: source repo                                        |
| super-stack                                                 |
| - skills                                                    |
| - protocols                                                 |
| - templates                                                 |
| - generators                                                |
| - install/check/smoke/test                                  |
+-------------------------------------------------------------+
          | generates / applies             | promote via sync gate
          v                                 v
+-------------------------------------------------------------+      +------------------------------+
| Layer 2: generated project layout                           |      | runtime repo                 |
| target project                                              |      | ~/.super-stack/runtime       |
| - docs/                                                     |      | managed runtime copy only    |
| - harness/                                                  |      +------------------------------+
| - code / tests                                              |
+-------------------------------------------------------------+
          ^
          | events / lessons / lineage
          |
+-------------------------------------------------------------+
| Layer 3: OpenSpace backend                                  |
| host-level memory + self-evolving skills + community sync   |
+-------------------------------------------------------------+
```

边界规则：

- OpenSpace 可以在受管范围内修改 source repo working tree
- OpenSpace 不直接把 runtime 当主要编辑面
- source repo 不承担 target project 的运行态真相
- target project 不承担 host-level 长期记忆
- runtime 不成为 source-of-truth

## 4. Layer 1：source repo layout

这一层是当前 `super-stack` 仓库。

它不需要长成 target project 的样子，但要能稳定生成 target project 结构、承接 OpenSpace 对 source repo 的受控修改，并管理自己的 runtime 推广链。

### 4.1 推荐长期结构

```text
.agents/skills/
  core/
  planning/
  quality/
  ship/
  harness/

protocols/

templates/
  generated-project/
    docs/
    harness/

scripts/
  generate/
  install/
  check/
  smoke/
  test/

docs/
  references/
  design-notes/
```

### 4.2 这一层负责什么

source repo 负责：

- 定义 stage 路由和 protocol
- 定义 `harness` skill 组
- 维护 generated project 的模板和生成器
- 接收 OpenSpace 在受管范围内对 skills / docs / templates / scripts 的修改
- 维护 runtime promotion gate
- 维护 retrospective -> recommendation -> patch / direct edit 的链路

source repo 不负责：

- 持有 target project 的任务执行态
- 代替 target project 保存业务知识
- 让 runtime 成为研发真源

### 4.3 `codex-record-retrospective` 在这一层的重定位

它应从“局部 retrospective skill”收敛为：

- ingestion adapter
- normalization adapter
- recommendation adapter
- promotion packet generator

它的职责是：

- 从 target project 的 `harness/`、宿主 session、`review / verify / qa` 结果中采集证据
- 做 path correlation、session slicing、lesson normalization
- 把 lesson 写入 OpenSpace
- 从 OpenSpace 拉回 candidate evolution
- 根据改动等级，选择：
  - 直接修改 source repo working tree
  - 或先生成 patch proposal
- 把通过 source-side gate 的改动再推广到 runtime

### 4.4 source repo direct edit + runtime promotion gate

这是当前 `super-stack` 自演进最关键的机制。

推荐模型：

1. OpenSpace 直接在 source repo working tree 产出改动
2. 先跑 source-side `check`
3. 根据改动级别决定是否需要 targeted `smoke` 和人工 `review`
4. 通过后，再同步到 `~/.super-stack/runtime`
5. runtime 再执行 install/check/smoke 验证

这个模型的好处是：

- OpenSpace 的技能进化能力没有被压死
- runtime 仍然保持受管副本语义
- 真源、验证、推广三层职责分开

详细 gate 设计见：

- [runtime-promotion-gates.md](/Users/gclm/workspace/lab/ai/super-stack/docs/architecture/decisions/runtime-promotion-gates.md)

## 5. Layer 2：generated project layout

这一层才是 `super-stack` 要在 target project 中生成的结构。

## 5.1 设计原则

- 项目内只保存协作所需的 repo-local 真相
- 长期知识和执行态要拆开
- 不再默认生成 `.planning`
- 不再默认生成宽泛的 `artifacts/`
- 文档按“回答什么问题”组织，执行态按“任务如何推进和结案”组织

## 5.2 推荐默认结构

```text
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
    api/
    data-models/

harness/
  state.md
  tasks/
    <task-id>/
      brief.md
      progress.md
      decisions.md
      evidence-index.json
      verdict.json
```

## 5.3 为什么 `docs/` 采用 `llmdoc-inspired` 结构

对 target project 来说，`llmdoc` 思路比传统“堆一堆架构文档目录”更合适。

原因是它天然按问题组织：

- `overview/`：这是什么项目
- `architecture/`：系统怎么工作、为什么这么拆
- `guides/`：如何执行常见动作
- `reference/`：约束、接口、模型、规范是什么

这比“把所有设计、运维、架构文档都平铺在 `docs/` 下”更适合 agent 检索和人工跳转。

### 5.3.1 ADR 的归位

`ADR` 不应该独立成为和 `architecture/` 并列的顶层模块。

更合理的结构是：

```text
docs/architecture/decisions/
  ADR-0001-runtime-boundary.md
  ADR-0002-harness-state-model.md
```

推荐规则：

- 目录名用 `decisions/`
- 文件名沿用 `ADR-xxxx-*.md`
- 只记录长期需要被引用的已拍板决策

### 5.3.2 为什么不生成 `docs/agent/`

原始 `llmdoc` 会包含偏 agent 报告式目录，但对于 `super-stack` 的 target project，这一层更应该被 `harness/` 吸收。

原因：

- 临时任务报告、进度、证据不应污染长期知识库
- 同一个任务的 brief / progress / evidence / verdict 需要天然聚合
- `review / verify / qa` 更容易围绕 `harness/tasks/<task-id>/` 工作

## 5.4 `harness/` 在 target project 里的角色

`harness/` 是 repo-local execution truth。

它保存：

- 当前仓库级状态
- 单任务的 brief / progress / decisions
- 证据索引与最终 verdict

### 5.4.1 `harness/state.md`

`harness/state.md` 只保留仓库当前态，例如：

- current focus
- active constraints
- current decision
- next actions

它不再承担：

- 项目百科全书
- requirements 总库
- roadmap 总库

### 5.4.2 `harness/tasks/<task-id>/`

每个长任务一个目录：

- `brief.md`
- `progress.md`
- `decisions.md`
- `evidence-index.json`
- `verdict.json`

这组文件是 `build / review / verify / qa` 的共用接口，而不是某个单一 skill 的私有实现。

## 5.5 `artifacts/` 还有没有必要

对 target project 默认没有必要。

原因：

- 语义过宽，最后通常会退化成杂物桶
- 任务证据已经归入 `harness/tasks/<task-id>/`
- 长期知识已经归入 `docs/`
- host-level 记忆已经归入 OpenSpace

唯一建议保留的例外是：

```text
artifacts/
  examples/
```

仅当项目明确需要版本化示例产物时再生成，但它不再是默认结构。

## 5.6 生成规则

### 5.6.1 `plan` stage 的默认落盘

进入 `plan` 时，默认只要求生成：

- `harness/tasks/<task-id>/brief.md`

不是每次都强制生成：

- proposal
- ADR
- runbook
- project-wide roadmap 文档

### 5.6.2 升级写 `docs/architecture/proposals/` 的条件

仅当满足以下至少一项：

- 架构调整
- API / 数据迁移
- service boundary 变化
- 安全 / 权限边界变化
- 需要多人 review 的设计方案
- 用户明确要求方案文档

### 5.6.3 升级写 `docs/architecture/decisions/` 的条件

仅当：

- 方案已经拍板
- 为什么这么做需要长期保留
- 后续实现或 review 会反复依赖这个决策

### 5.6.4 升级写 `docs/guides/runbooks/` 的条件

仅当：

- 该操作会被反复执行
- 它需要明确步骤、前置条件和故障处理
- 例如安装、恢复、发布、浏览器调试、QA / smoke 执行流程

## 6. Layer 3：OpenSpace backend

这一层负责 host-level long-term memory 和 skill evolution backend。

它用于替代上一版方案中的：

- `~/.super-stack/projects/<slug>/`

但它不替代 target project 的 `harness/`，也不替代 source repo 的 git truth。

### 6.1 OpenSpace 的职责

OpenSpace 负责：

- host-level memory persistence
- skill lineage
- local / cloud search
- import / export
- self-evolving skill backend
- dashboard / inspection
- 在允许的改动等级内直接修改 source repo working tree

OpenSpace 不负责：

- 让 runtime 成为研发真源
- 直接把 runtime 当主要编辑对象
- 自动绕过分级 `check / smoke / review`

### 6.2 详细方案

OpenSpace 的安装、MCP 接线、workspace 规划、权限模型、与 `codex-record-retrospective` 的关系，单独写在：

- [openspace.md](/Users/gclm/workspace/lab/ai/super-stack/docs/architecture/proposals/openspace.md)

runtime 推广门禁单独写在：

- [runtime-promotion-gates.md](/Users/gclm/workspace/lab/ai/super-stack/docs/architecture/decisions/runtime-promotion-gates.md)

实施拆解单独写在：

- [harness-rollout-checklist.md](/Users/gclm/workspace/lab/ai/super-stack/docs/guides/workflows/harness-rollout-checklist.md)

## 7. harness 技能组

4 个新能力作为独立 `harness` skill 组管理，而不是分散塞回现有 `core / planning / quality` 分类中。

详细设计见：

- [harness-skill-design.md](/Users/gclm/workspace/lab/ai/super-stack/docs/architecture/decisions/harness-skill-design.md)

## 8. `.planning` 的 cutover

### 8.1 原则

- 不做长期兼容层
- 允许做一次性迁移
- 迁移完成后统一更新路由、skills、templates、hooks、tests

### 8.2 一次性迁移口径

推荐迁移策略：

- `.planning/STATE.md` -> 提炼到 `harness/state.md`
- `.planning/ROADMAP.md` -> 提炼到 `docs/overview/roadmap.md`
- `.planning/PROJECT.md` -> 视价值迁到 `docs/overview/project-overview.md` 或废弃
- `.planning/REQUIREMENTS.md` -> 提炼到 proposal / ADR / reference，低价值内容直接废弃
- `.planning/codebase/*` -> 默认废弃，不再当长期真源

### 8.3 实施顺序

1. 先拍板 target project 的默认模板
2. 再定义 `harness/` artifact contract
3. 再落 4 个 `harness` skills
4. 再补 `source repo direct edit + runtime promotion gate`
5. 最后再接 OpenSpace 的受管安装、MCP、retrospective adapter

## 9. 最终建议

我的最终建议是：

- 对 target project，`llmdoc-inspired docs/` 比旧 `.planning` 体系更适合作为长期知识层
- 但 `docs/` 不能替代 `harness/`，执行态仍必须有独立 repo-local 目录
- 对 `super-stack` 自身，OpenSpace 可以直接参与 source repo 的 skills 演进
- 但 runtime 仍然必须通过受管 sync / promotion gate 推广，不应直接编辑
- `super-stack` 继续做 source repo，不把 runtime 混成研发真源

下一步评审重点不是再争论目录名，而是尽快拍板四件事：

1. target project 默认 `docs/` 模板是否按本文采用
2. `harness/tasks/<task-id>/` 的最小 artifact contract 是否按本文推进
3. OpenSpace 是否正式按“source repo direct edit + runtime promotion gate”模式接入
4. runtime 变更分级与 gate 规则是否按独立方案推进

如果进入实施阶段，直接按下面这份清单推进：

- [harness-rollout-checklist.md](/Users/gclm/workspace/lab/ai/super-stack/docs/guides/workflows/harness-rollout-checklist.md)

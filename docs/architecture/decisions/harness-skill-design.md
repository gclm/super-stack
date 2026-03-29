# harness 技能组设计

这份文档定义 `super-stack-native harness` 的 4 个技能边界。

目标不是复制一套重编排平台，而是在现有 `discuss -> plan -> build -> review -> verify -> qa -> ship` 工作流上，补一层可恢复、可验证、可复盘的长任务执行能力。

## 1. 设计目标

这组 skills 要解决四件事：

- 任务能被打包成 durable task pack，而不是只存在聊天上下文里
- 任务在执行中持续产出 progress / decisions / evidence，而不是靠最后一次总结
- 任务在结束前必须经过闭环验证，而不是主观感觉“差不多好了”
- 长任务可以跨轮次、跨 session 持续推进，并且在需要时明确升级给人

## 2. 不解决什么

phase-1 不解决这些事：

- 不做重型编排平台
- 不做默认 `worktree-per-task`
- 不做默认阻断式 stop hook
- 不做全自动 merge
- 不做强依赖云端的任务调度
- 不把 runtime promotion 直接塞进 harness 主职责

也就是说，这是一层“薄 harness”，不是新平台。

## 3. 为什么要单独做 `harness` skill 组

这 4 个能力不适合继续分散塞进已有的 `core / planning / quality` 分类。

原因是它们共同描述的是一层新的执行协议：

- 如何初始化长任务
- 如何保持任务可恢复
- 如何做持续验证
- 如何防止长任务越跑越偏

因此更合适的归属是：

```text
.agents/skills/harness/
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

## 4. 它和现有 stage 的关系

这 4 个 skills 不是替代现有 stage，而是覆盖长任务执行层。

关系如下：

- `repo-bootstrap`：inspect repo，并决定是否先初始化 `docs/ + harness/`
- `discuss / plan`：定义目标与约束
- `task-harness`：把目标落成 durable task pack
- `build`：实施代码或文档变更
- `architecture-guardrails`：约束边界、防止方案漂移
- `closed-loop-testing`：保证 evidence loop 真正闭合
- `harness-marathon`：负责长任务的持续推进、恢复和升级
- `review / verify / qa / ship`：提供风险审查、结果证明和交付收口

一句话：stage 决定“现在该做哪类工作”，harness skill 组决定“这类工作如何稳定跑下去”。

## 5. shared artifact contract

这组 skills 默认围绕 target project 的 `harness/` 目录工作：

```text
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

### 5.1 文件职责

- `harness/state.md`：仓库当前态，不记录每个任务的细节
- `harness/history.md`: append-first change history and completed milestones
- `brief.md`：任务目标、范围、约束、成功标准
- `progress.md`：阶段进展、当前状态、下一步
- `decisions.md`：任务内关键决策、取舍、未决问题
- `evidence-index.json`：测试、日志、截图、链接、命令结果等证据索引
- `verdict.json`：最终结论，明确已完成 / 已验证 / 未验证 / 剩余风险

### 5.2 设计原则

- 每个 task-id 一组完整产物
- 任务内产物聚合，避免临时内容污染 `docs/`
- 证据优先索引化，而不是散落在聊天或宿主本地记录里
- 每个 skill 都可以读写同一组产物，避免私有状态孤岛

## 6. Skill 1：`task-harness`

`task-harness` 是入口 skill，负责把一个复杂任务包装成 durable task pack。

### 6.1 触发条件

适合触发的场景：

- 任务明显跨多轮次
- 任务涉及多个模块或多步验证
- 用户明确希望“自动持续推进”
- 需要给后续 `review / verify / qa` 留稳定证据

### 6.2 核心职责

- 生成或选择 `task-id`
- 初始化 `harness/tasks/<task-id>/`
- 写入 `brief.md`
- 约定 progress / evidence / verdict 的输出节奏
- 将工作路由到 `build`、`review`、`verify`、`qa` 等后续阶段

### 6.3 输入

- 用户目标
- 作用域边界
- repo 当前上下文
- 成功标准
- 是否允许长任务持续执行

### 6.4 输出

最小输出：

- `brief.md`
- `progress.md` 初始骨架
- 当前任务的 task-id 和执行策略

### 6.5 非目标

- 不负责长时间持续运行
- 不负责深度架构约束
- 不代替验证闭环
- 不负责 target project 的首次 `docs/ + harness/` 骨架初始化；这一步归 `repo-bootstrap`
- 不直接负责 runtime promotion

## 7. Skill 2：`closed-loop-testing`

`closed-loop-testing` 负责把“实现了”变成“被证据证明了”。

### 7.1 触发条件

适合触发的场景：

- 任务结束前需要 fresh evidence
- 需要结合测试、日志、浏览器、API、CLI 多种证据
- 用户核心诉求是“别过早宣布完成”
- bugfix、复杂改动、用户流验证需要闭环

### 7.2 核心职责

- 定义当前任务最强可用验证路径
- 收集自动化测试、日志、屏幕、网络、API 响应等证据
- 更新 `evidence-index.json`
- 产出结构化 `verdict.json`
- 明确“已完成 / 已验证 / 未验证 / 缺口”

### 7.3 输入

- 当前任务 brief
- 已实现改动
- 可用验证手段
- 需要覆盖的风险点

### 7.4 输出

- 证据索引
- 最终验证口径
- 剩余验证缺口

### 7.5 和现有 skills 的关系

- 它不是替代 `verify`
- 它更像是 `verify / qa / bugfix-verification / browse` 的长任务适配层
- 这些技能仍然存在，但 `closed-loop-testing` 负责把它们产出的证据沉到统一 artifact contract

## 8. Skill 3：`architecture-guardrails`

`architecture-guardrails` 负责在长任务中持续守边界，防止任务边跑边变形。

### 8.1 触发条件

适合触发的场景：

- 架构、边界、迁移、接口形状正在变化
- 大型重构容易越界
- 用户明确要求先做方案守边界
- 中途出现 scope drift、模块职责漂移、设计口径摇摆

### 8.2 核心职责

- 显式记录当前边界和非目标
- 识别何时必须从 `build` 回退到 `plan`
- 识别何时需要升级为 proposal / ADR / runbook
- 维护任务内的 decisions 与 guardrail checklist
- 防止为了赶进度跳过必要设计动作

### 8.3 输入

- 当前任务范围
- 模块边界与系统约束
- 是否触及 API / 数据 / 权限 / service boundary

### 8.4 输出

- guardrail 清单
- 决策记录
- 是否要升级写 `docs/architecture/proposals/` 或 `docs/architecture/decisions/`

### 8.5 非目标

- 不替代真正的 architecture doc
- 不直接做长任务调度
- 不接管验证链路
- 不直接决定 runtime 同步策略

## 9. Skill 4：`harness-marathon`

`harness-marathon` 负责长时间运行协议，而不是普通任务入口。

### 9.1 触发条件

适合触发的场景：

- 任务可能跨很多轮次或长时间运行
- 需要周期性 checkpoint 和 resume
- 存在 doom loop、过早完成、反复返工风险
- 需要在一定规则下持续自动推进

### 9.2 核心职责

- 维护 checkpoint 节奏
- 定义 resume contract
- 检测 doom loop / scope drift / low-signal repetition
- 在需要时触发 human-escalation gate
- 持续更新 `progress.md`

### 9.3 输入

- task-id
- 当前进度
- 待执行子任务序列
- checkpoint 规则
- 升级门槛

### 9.4 输出

- 结构化进度快照
- 中断后恢复所需上下文
- 人工升级点
- 最终结案前的状态判断

### 9.5 非目标

- 不意味着默认 multi-agent
- 不意味着默认后台 daemon
- 不意味着自动 merge
- 不意味着自动同步 runtime

## 10. 四个 skills 的分工矩阵

### 10.1 谁负责什么

- `task-harness`：起任务、建 task pack、定协议
- `closed-loop-testing`：收证据、闭环验证、产 verdict
- `architecture-guardrails`：控边界、控升级条件、控设计漂移
- `harness-marathon`：跑长任务、做 checkpoint、管 resume / escalation

### 10.2 谁不应该越界

- `task-harness` 不替代 marathon
- `closed-loop-testing` 不替代 architecture 决策
- `architecture-guardrails` 不替代 evidence collection
- `harness-marathon` 不直接决定架构或最终验证结论
- 这 4 个 skills 都不直接把 runtime 当主要编辑对象

## 11. Concrete Skill Resources

`harness` 作为能力组保留，但 concrete skill 的运行时资源应尽量自包含，而不是继续在组根挂共享 `references/`、`templates/`。

### 11.1 `task-harness`

建议在 skill 内自带：

- `references/task-artifact-contract.md`
- `references/progress-and-checkpoint-rules.md`
- `assets/harness-state.md`
- `assets/task-brief.md`
- `assets/task-progress.md`
- `assets/task-decisions.md`
- `assets/evidence-index.json`
- `assets/verdict.json`

### 11.2 `closed-loop-testing`

建议在 skill 内自带：

- `references/evidence-pack-format.md`
- `assets/evidence-index.json`
- `assets/verdict.json`

### 11.3 `architecture-guardrails`

建议在 skill 内自带：

- `references/scope-drift-signals.md`
- `references/human-escalation-gates.md`

### 11.4 `harness-marathon`

建议在 skill 内自带：

- `references/progress-and-checkpoint-rules.md`
- `references/human-escalation-gates.md`
- `assets/task-progress.md`

### 11.5 scripts

后续若落地自动化，可以考虑：

- `init_harness_task.py`
- `append_progress.py`
- `update_evidence_index.py`
- `render_verdict.py`

phase-1 不必一次补全脚本，但资源边界最好先定成“组负责组织、skill 负责自带运行资源”。

## 12. 和 OpenSpace、source repo、runtime 的关系

这 4 个 harness skills 默认只操作 target project 内的 `harness/`。

它们与 OpenSpace 的关系应该是：

- `task-harness` 和配套 harness skills 先生成高质量 repo-local artifact
- `codex-record-retrospective` 再从这些 artifact 提取 lesson
- OpenSpace 再负责长期记忆、lineage 和 source repo 演进建议

它们与当前 `super-stack` source repo 的关系是：

- 当 target project 本身就是 `super-stack` 自己时，这些 artifact 可以直接为 source repo skills 演进服务
- 但修改主编辑面仍是 source repo working tree，不是 runtime

它们与 runtime 的关系是：

- harness 技能组可以提供 runtime promotion 所需 evidence
- 但 runtime promotion 本身属于独立 gate，不是 harness skill 组直接接管的职责

不要让 harness skills 直接把 OpenSpace 当成唯一状态来源，也不要让它们直接跳过 source repo 把改动推到 runtime。

## 13. 和 runtime promotion gate 的衔接

推荐分工是：

- harness skills：产出 task pack、progress、evidence、verdict
- OpenSpace / retrospective adapter：把 lesson 变成 source repo 改动
- runtime promotion gate：决定 source repo 改动是否可以同步到 runtime

这三层要分开，否则很容易再次把“执行态、技能演进、发布推广”混成一层。

详细 gate 规则见：

- [runtime-promotion-gates.md](/Users/gclm/workspace/lab/ai/super-stack/docs/architecture/decisions/runtime-promotion-gates.md)

## 14. 实施顺序建议

推荐分三步走：

1. phase-1：先落 `task-harness` + `closed-loop-testing`
2. phase-2：再落 `architecture-guardrails`
3. phase-3：最后落 `harness-marathon`

原因：

- 没有 durable task pack，marathon 没东西可跑
- 没有 evidence contract，marathon 只会把错误结论跑得更久
- 没有 guardrails，大任务越自动越容易跑偏
- 没有 gate，source repo 改动也不应该直接推广到 runtime

## 15. 最终建议

这 4 个 skills 的正确理解不是“4 个功能插件”，而是：

- `task-harness`：定义任务容器
- `closed-loop-testing`：定义结案证据
- `architecture-guardrails`：定义边界纪律
- `harness-marathon`：定义长时间运行协议

它们合在一起，才是你想要的那种“能持续跑、能恢复、能复盘、不会太早宣布完成”的工作流基础。

但要把这套能力真正接到 `super-stack` 自身演进上，还需要再加一层：

- source repo direct edit
- runtime promotion gate

这层不是 harness 的替代物，而是 harness 产物进入生产运行面的最后控制面。

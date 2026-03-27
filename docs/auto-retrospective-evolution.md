# super-stack 自动复盘与可进化方案

这份文档用于把 `super-stack` 的“自动复盘 -> 自动建议 -> 人工确认 -> 自动落地”方向固定下来，避免后续讨论不断在浏览器能力、技能扩展、宿主接线和复盘演进之间来回切换。

它回答 4 个问题：

1. 当前为什么需要自动复盘
2. 自动复盘系统应该长成什么样
3. 它和现有 `AGENTS.md`、`.planning/`、`skills`、`protocols` 的关系是什么
4. 这条线应该按什么阶段推进

注意：

- 这份文档描述的是自动复盘与 skill/protocol 演进主线
- 当前窗口后续只聚焦浏览器能力改造
- 自动复盘方案先作为独立文档固定，不在当前回合继续扩散到多条实现分支

## 1. 背景

`super-stack` 当前已经有较强的工作流治理能力：

- 根 `AGENTS.md` 负责阶段路由
- `.agents/skills/` 负责阶段和专项技能手册
- `protocols/` 负责共享工程规则
- `.planning/STATE.md` 负责共享状态连续性
- `codex-record-retrospective` 已经可以从本地记录里提取项目相关证据

但当前仍有一个明显缺口：

- 复盘主要还是手动触发
- 复盘结果主要还是人工阅读、人工归纳、人工决定改哪里
- 还没有一条稳定的“自动收集 -> 自动总结 -> 自动建议 -> 人工确认 -> 自动变更”链路

这导致几个问题：

- 高价值 lessons 会重复出现，但不能稳定沉淀
- 真实项目里的失误模式经常要靠记忆回放
- skill 和 protocol 的优化节奏依赖“人有没有想起来复盘”
- 工作流演进容易被临场讨论牵着走，而不是被持续证据驱动

## 2. 目标

自动复盘主线的目标不是“让系统自己偷偷修改规则”，而是建立一套证据驱动、带审批门的演进机制。

目标状态是：

1. 系统自动发现值得复盘的真实使用记录
2. 系统自动生成结构化复盘报告
3. 系统自动生成建议修改的目标文件和理由
4. 系统在必要时生成候选 patch 或变更草案
5. 用户只需要审核
6. 用户确认后，系统再把变更落到 source repo
7. 变更后保留验证和状态回写

一句话概括：

`super-stack` 需要从“会被人工复盘的工作流底座”升级成“会被证据驱动、可审批进化的工作流 runtime”。

## 3. 设计边界

这条线要解决的是“自动复盘”和“可控进化”，不是无边界自动改仓库。

明确边界如下：

- 可以自动收集记录
- 可以自动生成报告
- 可以自动生成建议
- 可以自动生成 patch 草案
- 不应默认自动修改核心规则
- 对 `AGENTS.md`、`protocols/`、核心 skill 的变更必须保留人工确认门

不应该做成：

- 根据单次项目噪音自动改全局规则
- 在没有明确证据等级说明时就改 skill
- 把 fallback 来源当成原始证据
- 让 source repo 在无人确认的情况下持续漂移

## 4. 当前基础

当前仓库里已经具备自动复盘主线的 4 块基础能力。

### 4.1 路由与治理基础

- [AGENTS.md](/Users/gclm/workspace/lab/ai/super-stack/AGENTS.md)
- [protocols/workflow-governance.md](/Users/gclm/workspace/lab/ai/super-stack/protocols/workflow-governance.md)

这两层已经定义了：

- 阶段路由
- backtrack 规则
- 状态连续性
- 文档与 commit 约定
- review / verify / qa 的边界

### 4.2 共享状态基础

- [.planning/STATE.md](/Users/gclm/workspace/lab/ai/super-stack/.planning/STATE.md)

当前 `STATE.md` 已经承担：

- 当前方向记录
- 最近架构变化
- 最近 scope 变化
- 验证状态
- 后续动作

这说明 `super-stack` 已经不是“只靠聊天记住状态”的系统。

### 4.3 复盘技能基础

- [.agents/skills/planning/codex-record-retrospective/SKILL.md](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/SKILL.md)
- [.agents/skills/planning/codex-record-retrospective/scripts/find_codex_project_records.py](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/scripts/find_codex_project_records.py)
- [.agents/skills/planning/codex-record-retrospective/scripts/extract_codex_session_timeline.py](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/scripts/extract_codex_session_timeline.py)

当前已经能做的事：

- 基于项目路径做记录扫描
- 支持历史路径 alias
- 将原始 session JSONL 转成可读时间线
- 区分强证据与弱证据

### 4.4 技能演进信号基础

当前已有经验表明，真实项目会稳定暴露出可泛化的信号，例如：

- 多模块仓库默认全仓深读的问题
- verify 容易把“已实现”说成“已验证”的问题
- 记录扫描在仓库迁移后容易漏历史路径的问题

这说明“自动复盘可进化”不是理论需求，而是已经存在真实驱动力。

## 5. 目标架构

自动复盘与可进化主线建议拆成 6 层：

1. 记录收集层
2. 证据提炼层
3. lesson 分类层
4. 变更建议层
5. 人工确认层
6. 自动落地层

### 5.1 架构图

```text
Codex local records / session index / history
                    |
                    v
        +---------------------------+
        | Record Collection Layer   |
        | find project-correlated   |
        | sessions and sources      |
        +---------------------------+
                    |
                    v
        +---------------------------+
        | Evidence Extraction       |
        | timeline / snippets /     |
        | source-strength summary   |
        +---------------------------+
                    |
                    v
        +---------------------------+
        | Lesson Classification     |
        | routing / planning /      |
        | verify / host / noise     |
        +---------------------------+
                    |
                    v
        +---------------------------+
        | Recommendation Mapping    |
        | lesson -> target files    |
        | lesson -> change type     |
        +---------------------------+
                    |
                    v
        +---------------------------+
        | Human Approval Gate       |
        | review report / patch /   |
        | accept or reject          |
        +---------------------------+
                    |
                    v
        +---------------------------+
        | Apply + Validate + State  |
        | source repo update /      |
        | minimal checks / state    |
        +---------------------------+
```

## 6. 核心流程

建议标准流程如下：

### 6.1 Collect

自动扫描最近时间窗口内与项目路径相关的记录：

- `session_index`
- `sessions`
- `archived_sessions`
- `history.jsonl`

目标：

- 先按项目路径强相关收集
- 不直接依赖宽泛全局 history 总结器

### 6.2 Extract

对高价值 session 提取：

- 时间线
- 用户意图
- 路由选择
- 中途 backtrack
- 验证路径
- 卡点与 friction

目标：

- 将原始 JSONL 转成可读、可比较的 evidence

### 6.3 Classify

对问题进行分类：

- routing problem
- planning problem
- implementation discipline problem
- verification problem
- host/runtime limitation
- project-specific noise

目标：

- 区分“系统问题”和“项目噪音”

### 6.4 Map

将 lesson 映射到变更目标：

- `AGENTS.md`
- `protocols/`
- 某个现有 skill
- 某个 reference
- 某个脚本
- 不修改仓库，只记录 caution

目标：

- 让建议变得可执行，而不是停留在抽象总结

### 6.5 Report

生成用户可审阅的复盘报告。

建议至少输出：

- 扫描范围
- 记录来源
- strongest evidence
- evidence gaps
- reconstructed workflow summary
- repeated friction patterns
- generalized lessons
- recommended targets
- confidence

### 6.6 Propose

在报告基础上生成变更建议：

- 修改哪个文件
- 为什么改
- 改的是边界、规则、reference 还是脚本
- 置信度
- 是否建议生成 patch

### 6.7 Approve

用户只需要做审批：

- 接受
- 部分接受
- 拒绝
- 仅记录，不修改

### 6.8 Apply

只有确认后，系统才执行：

- 修改 source repo
- 最小验证
- 更新 `STATE.md`
- 产出变更摘要

## 7. 数据产物设计

自动复盘要想稳定，不能只生成自然语言总结，必须有结构化产物。

建议引入两类产物：

### 7.1 Retrospective Report

建议同时输出：

- Markdown 报告
- JSON 报告

建议路径：

- `artifacts/retrospectives/YYYY-MM-DD-<topic>.md`
- `artifacts/retrospectives/YYYY-MM-DD-<topic>.json`

JSON 建议字段：

- `project_path`
- `project_aliases`
- `records_reviewed`
- `checked_sources`
- `evidence_strength`
- `evidence_gaps`
- `workflow_summary`
- `patterns`
- `classifications`
- `generalized_lessons`
- `recommended_targets`
- `confidence`

### 7.2 Change Recommendation

建议同时输出：

- Markdown 建议
- JSON 建议
- 可选 patch 草案

建议路径：

- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.md`
- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.json`
- `artifacts/evolution/YYYY-MM-DD-<topic>.patch`

JSON 建议字段：

- `lesson_id`
- `problem_type`
- `target_files`
- `change_kind`
- `reason`
- `evidence_refs`
- `confidence`
- `requires_human_approval`
- `suggested_patch_available`

## 8. lesson 到目标文件的映射

这层是“自动复盘”走向“自动进化”的关键桥梁。

建议维护一份稳定的 lesson -> target mapping 规则，例如：

- `module_scope_ambiguity`
  - -> `map-codebase/SKILL.md`
- `verify_overclaim`
  - -> `verify/SKILL.md`
  - -> `protocols/verify.md`
- `route_not_explicit`
  - -> `AGENTS.md`
  - -> `workflow-governance.md`
- `record_path_migration_gap`
  - -> `codex-record-retrospective` scripts / references
- `host_limitation_not_explained`
  - -> `.codex/AGENTS.md`

这层建议最开始可以是简单表驱动，不必一开始就做复杂推理。

## 9. 与现有仓库结构的关系

自动复盘系统不应重新发明一套状态体系，而应尽量复用当前结构。

### 9.1 与 `.planning/` 的关系

- `.planning/` 继续负责共享状态、项目方向和阶段记忆
- 自动复盘报告不直接塞进 `.planning/`
- 复盘改变主线方向时，再把结论回写 `STATE.md`

### 9.2 与 `skills/` 的关系

- `codex-record-retrospective` 继续作为人工和自动模式共用的复盘手册
- 新增的自动化脚本应服务 skill，而不是绕开 skill

### 9.3 与 `protocols/` 的关系

- 复盘系统自身不应该散落一堆新的口头规则
- 稳定结论应下沉到 `protocols/` 或 skill/reference

### 9.4 与 source/runtime 边界的关系

- 所有可复用规则变更都必须先改 source repo
- runtime copy 继续只是运行态，不是变更真源

## 10. 分阶段实施路线

建议分 4 个阶段推进，而不是一次做成“全自动进化系统”。

### Phase 1：自动复盘报告

目标：

- 自动扫描记录
- 自动生成复盘报告
- 不自动改任何文件

完成标志：

- 可以稳定输出用户可读报告
- 可以区分 evidence strength 和 evidence gaps

### Phase 2：自动生成变更建议

目标：

- 在报告基础上自动生成推荐改动目标
- 说明为什么改、改哪里、置信度多少

完成标志：

- 可以生成 recommendation artifact
- 用户只需 review，而不是从零思考改哪里

### Phase 3：审批后自动应用

目标：

- 用户确认后自动生成 patch 或直接修改 source repo
- 保留最小验证与 `STATE.md` 更新

完成标志：

- 审批链路闭合
- source repo 变更仍然可控

### Phase 4：受控的持续进化

目标：

- 定期或按事件触发自动复盘
- 积累演进 ledger
- 持续校准 skills / protocols / routing

完成标志：

- 自动复盘成为常规能力
- skill/protocol 演进不再只靠人工记忆

## 11. 当前不建议优先做的事

为了避免主线发散，下面这些不建议现在优先做：

### 11.1 无确认自动修改核心规则

原因：

- 风险太高
- 容易把项目噪音写成全局规范

### 11.2 一开始就做复杂多 agent 编排

原因：

- 当前更大的收益来自稳定 artifact、mapping 和 approval gate
- orchestration 不是当前第一收益点

### 11.3 把自动复盘逻辑散落到多个无关脚本

原因：

- 容易破坏后续维护性
- 建议围绕 retrospective skill 形成收口

## 12. 推荐的近期落地顺序

如果只按“下一步最值”排序，我建议是：

1. 固定这份文档，明确自动复盘主线边界
2. 先处理浏览器主线改造，避免当前窗口继续发散
3. 浏览器主线稳定后，再回到自动复盘 Phase 1
4. 先把 report artifact 做出来，再做 recommendation
5. 最后再做审批后的自动应用

## 13. 一句话结论

`super-stack` 的自动复盘与可进化方向，不是“让系统自己偷偷改规则”，而是建立一条“证据驱动、可审阅、可审批、可验证”的持续演进主线。

当前这条主线已经值得固定成文档，但不应在本窗口继续和浏览器改造并行展开。

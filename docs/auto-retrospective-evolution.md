# super-stack 技能自动更新机制设计

这份文档用于把 `super-stack` 的“自动复盘 -> 自动建议 -> 人工确认 -> 自动落地”能力从概念描述升级成可执行机制，重点回答三件事：

1. 当前文档已经解决了什么，缺什么
2. 自动更新机制应该怎样接入现有 `skills / protocols / .planning / source repo` 体系
3. `codex-record-retrospective` 这个现有技能应如何进化成自动演进链路的入口

这份文档现在聚焦的是 `skills` 与 workflow 规则的自动进化，不扩散到浏览器抽取、宿主插件安装、或无边界自修改问题。

## 1. 当前文档分析

现有方案已经有 4 个明显优点：

- 已经明确边界：强调“证据驱动、可审批、可验证”，而不是静默自改规则。
- 已经明确主链路：`collect -> extract -> classify -> map -> report -> propose -> approve -> apply`。
- 已经明确仓库边界：规则真源必须回到 source repo，而不是 runtime copy。
- 已经明确分阶段推进：先报告，再建议，再审批后落地，而不是直接追求全自动。

但当前版本仍有 5 个缺口：

### 1.1 缺少更新触发机制

现在文档说明了“怎么复盘”，但没有定义“什么时候触发自动更新候选生成”。

如果没有触发机制，复盘仍然会退回成手工行为。

### 1.2 缺少结构化 lesson ledger

当前定义了 report artifact 和 recommendation artifact，但没有定义长期累计的演进账本：

- 哪类 lesson 出现了多少次
- 曾经被接受还是被拒绝
- 哪些建议已经被吸收进 skill / protocol
- 哪些问题被证明只是项目噪音

没有 ledger，系统就很难区分“偶发问题”和“值得改全局规则的重复信号”。

### 1.3 缺少稳定的 lesson -> target 映射真源

当前文档提到可以做 lesson mapping，但还停留在文档示例，没有形成：

- 可维护的表驱动规则
- 能被脚本复用的映射文件
- 明确的 change kind 分类

这会导致 recommendation 很难稳定复现。

### 1.4 缺少最小验证闭环

文档提到了 apply 后要验证，但还没有明确：

- 文本型 skill/doc 变更用什么检查
- recommendation 脚本本身如何验证
- 什么情况下只生成 patch，不直接写文件

### 1.5 缺少对“技能不应越写越胖”的保护

自动更新机制如果只会不断往 `SKILL.md` 塞规则，很快就会把技能入口写成一大坨，不再 triggerable。

因此自动更新必须内建一个原则：

- 优先修改 `references/`
- 其次修改脚本或 mapping
- 最后才扩 `SKILL.md`
- 当 `SKILL.md` 变胖时优先拆细，不继续堆文字

## 2. 外部参考带来的设计启发

### 2.1 来自 `MiniMax-AI/skills` 的可借鉴点

参考仓库：[MiniMax-AI/skills](https://github.com/MiniMax-AI/skills)

从其公开仓库结构里，可以直接借鉴 4 个机制：

- 目录即契约：skill 目录结构稳定，便于脚本扫描、校验和索引。
- 元信息显式化：skill 名称、描述、适用场景都能被校验和发现。
- 自动校验入口：通过脚本检查 skill 结构和内容一致性，而不是只靠人工读文档。
- PR 治理入口：skill 更新不是随手改文本，而是通过固定的 review/验证路径进入仓库。

这些点对 `super-stack` 的启发不是“照搬它的 skill 格式”，而是：

- 自动更新机制必须输出稳定 artifact，而不是一次性聊天建议。
- skill 更新要有脚本可消费的中间层，而不是只有自然语言。
- 自动更新结果必须进入现有 review / verify / ship 治理链，而不是另起一套流程。

进一步对本地 clone 结果细看后，MiniMax 还有 6 个更值得直接借鉴的治理点：

- skill 仓库是“产品化目录”，不是松散文档集合。
  - `README.md` / `README_zh.md` 负责统一发现面。
  - `CONTRIBUTING.md` 负责贡献约束。
  - 宿主插件清单负责安装发现。
  - 这意味着 skill 自动更新机制不能只改技能正文，还应考虑索引、发现面和贡献规则是否同步。
- 把硬规则和软规则分开。
  - `validate_skills.py` 只做硬检查：结构、frontmatter、name 对齐、secret scan。
  - `pr-review` skill 再处理边界、触发质量、README sync 等软规则。
  - 对 `super-stack` 的启发是：自动更新也应拆成“自动验证”和“人工 review”两层，而不是让 recommendation 一步到位。
- skill entry 的触发面是第一等公民。
  - 他们反复强调 `description` 要描述 trigger conditions。
  - 这说明我们的自动更新如果要修改 `SKILL.md`，首先应该检查有没有伤到 trigger surface，而不是只看内容是否更全。
- 把结构校验做成脚本，而不是写成口头规范。
  - MiniMax 用校验脚本保证技能目录、frontmatter、secret 规则。
  - `super-stack` 下一步也应该考虑为 `.agents/skills/` 增加一类轻量 validator，而不只靠人工阅读。
- README 索引同步是治理的一部分。
  - 新 skill 不只是多一个目录，还要进入 README 表。
  - 对 `super-stack` 来说，对应的是：当新增 skill/reference/mapping 影响发现面时，应同步路由文档或技能列表来源。
- 贡献入口清晰，降低长期维护成本。
  - MiniMax 的做法使“外部贡献 -> 自动校验 -> 人工 review”链路稳定。
  - 对 `super-stack` 的启发是：自动更新机制最终不只是给当前会话用，也应能给后续维护者提供可复核的 artifact 和验证入口。

### 2.2 来自公众号文章的可借鉴点

原文链接：[从 OpenAI Harness Engineering 蒸馏出四个 Skill，Agent 跑了 25 小时](https://mp.weixin.qq.com/s/nI3i6kJIak7-p3VLsYTgNA?scene=1)

这次已通过浏览器原始页读取拿到正文。结合文章里的具体内容，对 `super-stack` 有 5 个直接可复用启发：

- `AGENTS.md` 应该是目录，不该是百科全书。
  - 文章明确强调“大而全 AGENTS.md”会挤占有效 context、增加过期规则混入概率。
  - 这与 `super-stack` 当前把细则下沉到 `protocols/` 与 `references/` 的方向一致，说明“技能自动更新”不能默认把新规则继续堆回入口文件。
- 进度文件即上下文。
  - 文章把 execution plans 和 decision logs 存回仓库，用来解决长任务恢复状态问题。
  - 对 `super-stack` 的启发是：自动复盘不仅要生成报告，还应保留稳定 artifact 和 ledger，让后续 skill 维护不是重新读聊天记录。
- 架构规则应尽量机械执行。
  - 文中用结构测试和 lint 错误去约束分层，而不是期待 agent 自觉记住全部规则。
  - 这支持我们把 lesson 映射成表驱动 recommendation，再落到脚本、mapping、reference，而不是继续增强隐式 prompt。
- 验证结论要基于证据包，而不是“脚本跑完了”。
  - 文中把 verdict、请求响应、快照、过滤日志打成 evidence package。
  - 这与我们在 `verify` 和 retrospective 里强调 evidence strength、evidence gaps 是同一个方向，也支持 recommendation artifact 的结构化设计。
- 长时运行要靠运行策略，而不是一次性长 prompt。
  - 文中把长任务运行拆成恢复、闭环、约束、马拉松策略几层。
  - 对 `super-stack` 的启发是：自动更新机制更适合作为“定时/事件触发的维护流程”，而不是期待单轮对话一次做完复盘、建议、审批、落地所有事。

这些启发共同支持一个判断：

- 自动更新应优先建设 artifact、mapping、ledger、approval gate
- 不应把经验总结重新堆回一份越来越胖的主提示
- 定时自动化是合理方向，但第一阶段只应输出 retrospective 和 recommendation，不自动 apply

### 2.3 来自 `stellarlinkco/skills` 的可借鉴点

参考仓库：[stellarlinkco/skills](https://github.com/stellarlinkco/skills)

这次本地 clone 之后，可以确认这个仓库与 `MiniMax-AI/skills` 的价值不一样：

- `MiniMax-AI/skills` 更像“技能目录产品化治理”
- `stellarlinkco/skills` 更像“长任务运行协议与 hooks 设计”

其中最值得 `super-stack` 吸收的不是整套 hook 行为，而是 5 个运行层启发：

- 进度产物必须可恢复，而不只是聊天上下文。
  - `harness-progress.txt` 与 `harness-tasks.json` 体现了“进度文件即上下文”。
  - 对我们来说，这强化了 retrospective artifact、recommendation artifact、evolution ledger 的必要性。
- 长任务的失败模式和普通任务不同。
  - 核心问题往往不是“不会做”，而是“过早停下”“中断后恢复错误”“没有客观完成标准”。
  - 所以 retrospective 应增加一类 `long-running execution gap`。
- 停止前的反思门很有价值。
  - `reflect-on-stop.py` 并不一定要直接照搬成 hook，但它证明了“结束前回看原始请求”能显著减少过早完成。
  - 对我们来说，这更适合沉淀到 `verify / ship / 自动复盘总结`，而不是直接做阻断式 hook。
- 结构化任务依赖和恢复规则值得借鉴，但不能机械复制。
  - `harness` 适合超长、多阶段、可分解任务。
  - `super-stack` 不应把所有日常任务都重型化成任务账本；应该只在明显长任务、多 session 场景里吸收这些模式。
- 有些运行时行为不适合作为共享默认。
  - 例如阻断 stop、无限循环、自动 `git reset --hard` 这类强行为，不适合直接进入 `super-stack` 的共享工作流底座。

因此，这个仓库对我们的正确集成方式应是：

- 集成其“模式”
- 不直接集成其“强 hook 行为”
- 把它转成 retrospective 分类维度、planning 协议启发、verify/ship 的完成门强化

## 3. 设计目标

技能自动更新机制的目标不是“自动修改任何东西”，而是建立一条受控的演进流水线：

1. 自动发现值得沉淀的重复 lesson
2. 自动输出结构化 retrospective artifact
3. 自动将 lesson 映射为候选 skill/protocol/doc/script 变更
4. 自动给出 patch 草案或最小修改建议
5. 保留人工审批门
6. 审批后执行最小落地与验证
7. 将接受/拒绝结果回写到演进账本

一句话：

`super-stack` 需要一个“证据驱动的技能维护助手”，而不是“匿名自更新黑盒”。

在吸收公众号文章与 MiniMax 仓库之后，这个目标还应再补一层：

8. 让技能更新具备“可发现、可校验、可审查、可定时运行”的维护属性

## 4. 设计原则

自动更新机制应固定遵守以下原则：

### 4.1 Source Repo First

- 任何可复用 skill/protocol 变更都先作用于 source repo。
- `~/.super-stack/runtime`、`~/.agents/skills`、`~/.codex/skills` 只视为运行副本或镜像，不是唯一真源。

### 4.2 Report First, Patch Later

- 没有 retrospective report，就不生成 recommendation。
- 没有 recommendation，就不进入 patch 草案。
- 没有人工批准，就不自动写核心规则文件。

### 4.3 Table-Driven Before Freeform

- 先用稳定的 `lesson -> target -> change kind` 映射表驱动建议生成。
- 只有表驱动无法覆盖时，才允许人工总结自由发挥。

### 4.4 Thin Skill Entry

- 自动机制优先修改 `references/`、脚本、mapping 文件。
- `SKILL.md` 只保留触发面、规则边界、核心流程、输出约定。

### 4.5 Repeated Signal Only

- 单次噪音默认只进 retrospective report，不直接升级成共享规则。
- 推荐升级阈值应结合重复次数、证据强度、影响范围共同判断。

## 5. 目标机制

建议把自动更新机制拆成 7 个模块。

### 5.1 Signal Capture

负责发现“哪些 session 值得复盘”。

触发来源建议分 3 类：

- 手动触发：用户显式使用 `codex-record-retrospective`
- 事件触发：复杂任务结束、明确 backtrack、用户多次纠正、verify 失败、review 发现重复问题
- 定时触发：按周或按固定窗口扫描近期高价值 session
- 长任务触发：多 session 恢复、明显过早完成、反复 `continue`、复杂任务无稳定进度产物

建议先做保守触发策略：

- 仅在满足以下任一条件时生成候选复盘任务
- 出现显式 backtrack：如 `build -> debug`、`build -> plan`、`build -> verify`
- 用户在一次任务中至少两次纠正同类问题
- `review / verify / qa` 发现与历史同型的缺口
- 完成一个高复杂度、多阶段任务

### 5.1.1 单个 session 包含多个回话时怎么处理

这类情况必须明确升级口径：

- 不再默认 `1 个 session = 1 个复盘单元`
- 默认优先按“与目标项目路径相关的 task slice / conversation slice”复盘
- 只有当整个 session 都围绕同一任务持续推进时，才把整个 session 当成一个复盘单元

推荐处理顺序：

1. 先做 `project path correlation`
2. 再做 `session timeline extraction`
3. 发现一个 session 里混有多个 ask、明显时间间隔、cwd 切换、主题跳转时，再做 `session slicing`
4. 只从相关 slice 提炼 patterns / lessons / recommendation

这样做的目的，是避免把“同一 session 里不相干的几个 ask”错误混成一个 lesson，导致 recommendation 偏离真实问题。

### 5.1.2 每日晨检型 inbox 输出模板

如果把自动复盘作为工作日上班后的晨检自动化，最重要的不是“把推理过程全倒给用户”，而是让用户一眼知道自己今天要不要拍板、拍什么板。

所以晨检输出应该遵守金字塔原则：

1. 先给结论
2. 再给需要用户做的决策
3. 再给修改范围
4. 最后才补原因和证据

不要让用户看完一堆证据之后，仍然不知道：

- 今天到底要不要改技能
- 要改哪个技能或文档
- 修改范围是小修还是扩规则
- 为什么这次建议值得做

建议默认输出顺序：

1. 今日结论
2. 你的决策项
3. 建议修改范围
4. 修改原因
5. 不修改的后果
6. 证据摘要
7. 证据边界
8. next action

建议模板：

```md
# 每日技能复盘晨检

- 日期: <YYYY-MM-DD>
- 扫描范围: <project/path or session window>
- 今日结论: <今天是否建议改技能；如果建议，改动级别是小修、中修，还是先记账不动>

## 你的决策项

- 是否建议修改: <是 / 否>
- 建议你今天批准的动作:
  - <动作 1>
  - <动作 2>
- 暂不建议动的部分:
  - <动作 3>

## 建议修改范围

- 目标文件:
  - `<file>`
  - `<file>`
- 修改类型: <补规则 / 收紧边界 / 补 reference / 补脚本 / 仅记账>
- 影响范围: <只影响 retrospective / 影响 planning / 影响全局路由>

## 修改原因

- 原因 1: <用业务语言说明，而不是只写 lesson id>
- 原因 2: <为什么这次值得改>
- 为什么不是改别处:
  - <例如为什么不改 AGENTS.md，而是改 skill reference>

## 不修改的后果

- <下次最可能重复踩到的坑>
- <对自动化或技能维护的直接影响>

## 证据摘要

- strongest session: <session-id>
- 处理方式: <整段复盘 / 按 slice 复盘>
- 关键观察:
  - <观察 1>
  - <观察 2>
- 排除的项目噪音:
  - <噪音 1>
  - <噪音 2>

## 证据边界

- <还有哪些没看>
- <结论里哪些是确定的，哪些仍带推断>

## Next Action

- <如果值得继续，建议下一步做什么；如果不值得，写明暂不动作>
```

这个模板的核心目标是：

- 让用户先做决定，再决定是否下钻看证据
- 让“改不改、改哪里、为什么改”一眼可见
- 让证据服务于决策，而不是让用户自己从证据里倒推出决策

### 5.2 Evidence Extraction

沿用现有 retrospective skill 的路径相关证据策略：

- `session_index`
- `sessions`
- `archived_sessions`
- `history.jsonl`

产出统一 retrospective JSON，最少包含：

- `project_path`
- `project_aliases`
- `records_reviewed`
- `checked_sources`
- `workflow_summary`
- `patterns`
- `classifications`
- `generalized_lessons`
- `recommended_targets`
- `confidence`
- `execution_shape`
- `completion_gap_signals`

如果一个 session 中混有多个独立任务，不应直接把整段 session 当成单个 retrospective 单元。

默认应采用：

1. 先做项目路径相关性筛选
2. 再提取 session timeline
3. 必要时按 `task slice / conversation slice` 切分长 session
4. 从相关 slice 中提炼 lesson，而不是从整个 session blob 直接归因

### 5.3 Lesson Normalization

这是当前文档最缺的一层。

它负责把自然语言 lesson 归一成稳定 lesson id，例如：

- `module_scope_ambiguity`
- `verify_overclaim`
- `route_not_explicit`
- `record_path_migration_gap`
- `host_limitation_not_explained`
- `skill_entry_bloat`
- `evidence_gap_not_called_out`
- `premature_completion`
- `missing_progress_artifacts`

只有完成归一，后面的统计、映射、去重、审批才会稳定。

### 5.4 Recommendation Engine

Recommendation engine 不直接写文档，而是先读取一份表驱动 mapping：

- `lesson_id`
- `target_files`
- `change_kind`
- `default_confidence`
- `approval_level`
- `validation_hint`

然后生成 recommendation artifact：

- 哪个 lesson 命中了哪个映射
- 推荐改哪些文件
- 建议改 `SKILL.md`、`references/`、`protocols/` 还是脚本
- 是否建议只记 caution 而不改仓库

### 5.5 Evolution Ledger

建议新增长期账本，例如：

- `artifacts/evolution/evolution-ledger.jsonl`

每次 retrospective 或 recommendation 都追加一条记录，最少包含：

- `timestamp`
- `project_path`
- `lesson_id`
- `evidence_strength`
- `recommendation_status`
- `accepted_targets`
- `rejected_reason`
- `applied_commit_or_note`

它的作用是：

- 给“重复出现”提供证据
- 防止同一问题反复建议、反复驳回
- 为后续 skill-maintenance 提供长期依据

### 5.6 Human Approval Gate

审批门建议至少分三级：

- `record-only`
  - 只写 artifact 与 ledger，不改仓库
- `patch-proposed`
  - 允许生成 patch 草案，但不自动 apply
- `apply-approved`
  - 人工确认后，允许修改 source repo 并执行最小验证

其中以下目标默认至少需要 `patch-proposed` 或更高：

- `AGENTS.md`
- `protocols/`
- 核心共享 skill 的 `SKILL.md`

### 5.7 Apply And Verify

apply 后的最小闭环建议是：

1. 写入 source repo
2. 运行文本级自检
3. 更新 `.planning/STATE.md`
4. 记录到 evolution ledger
5. 输出 apply summary

文本型变更的最小自检建议包括：

- 引用路径是否存在
- `SKILL.md` 是否仍保持薄入口
- mapping 文件是否可被 recommendation 脚本解析
- 文档与状态文件是否同步更新

### 5.8 Governance And Discovery Sync

这是结合 MiniMax 对标后新增的一层。

自动更新如果影响 skill 发现面，不应只改目标 skill 文件，还应检查：

- 是否需要同步技能索引或路由入口
- 是否需要补 contribution / review 规则
- 是否需要更新安装或宿主发现说明
- 是否需要新增自动校验脚本或扩展现有校验

否则系统会出现“规则已经改了，但维护者不知道、宿主发现不到、校验也不覆盖”的半失效状态。

### 5.9 Validator Gate

自动更新机制在进入人工 review 前，应该先过一层轻量 validator。

当前 `super-stack` 已经落下第一版：

- `scripts/check/validate-skills.py`

这层先覆盖最基础、最稳定、最适合自动化的约束：

- `SKILL.md` 是否存在
- frontmatter 是否合法
- `name` 是否与目录名一致
- `description` 是否存在
- skill 内部引用路径是否有效
- `references/`、`scripts/` 是否为正确目录
- `SKILL.md` 是否逼近“薄入口”警戒线

它的定位不是替代人工 review，而是：

- 尽早拦住结构错误
- 尽早暴露失效引用
- 为 skill 自动更新提供最小静态门

## 6. 产物设计

建议把产物拆成 4 类，而不仅是 report 与 recommendation。

### 6.1 Retrospective Report

建议路径：

- `artifacts/retrospectives/YYYY-MM-DD-<topic>.md`
- `artifacts/retrospectives/YYYY-MM-DD-<topic>.json`

当前仓库样例：

- [sample-retrospective.json](/Users/gclm/workspace/lab/ai/super-stack/artifacts/retrospectives/examples/sample-retrospective.json)

默认渲染入口：

- [.agents/skills/planning/codex-record-retrospective/scripts/render_retrospective_report.py](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/scripts/render_retrospective_report.py)

### 6.2 Recommendation Artifact

建议路径：

- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.md`
- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.json`

当前仓库样例：

- [sample-recommendations.json](/Users/gclm/workspace/lab/ai/super-stack/artifacts/evolution/examples/sample-recommendations.json)

默认后处理入口：

- [.agents/skills/planning/codex-record-retrospective/scripts/process_retrospective.py](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/scripts/process_retrospective.py)

### 6.3 Optional Patch Draft

建议路径：

- `artifacts/evolution/YYYY-MM-DD-<topic>.patch`

### 6.4 Evolution Ledger

建议路径：

- `artifacts/evolution/evolution-ledger.jsonl`

当前已补第一版 ledger 写入工具：

- [.agents/skills/planning/codex-record-retrospective/scripts/append_evolution_ledger.py](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/scripts/append_evolution_ledger.py)

字段参考与样例说明：

- [.agents/skills/planning/codex-record-retrospective/references/artifact-schemas.md](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/references/artifact-schemas.md)

## 7. lesson 到目标文件的映射真源

建议不要把映射只写在文档里，而是维护一份仓库内可复用真源，例如：

- [.agents/skills/planning/codex-record-retrospective/references/lesson-target-map.json](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/references/lesson-target-map.json)

示例映射方向：

- `module_scope_ambiguity`
  - -> `map-codebase/SKILL.md`
  - -> `map-codebase` 的 reference
- `verify_overclaim`
  - -> `verify/SKILL.md`
  - -> `protocols/verify.md`
- `route_not_explicit`
  - -> `AGENTS.md`
  - -> `protocols/workflow-governance.md`
- `record_path_migration_gap`
  - -> `codex-record-retrospective` scripts / references
- `skill_entry_bloat`
  - -> 某 skill 的 `references/`
  - -> `skill-maintenance` reference
- `host_limitation_not_explained`
  - -> `.codex/AGENTS.md`

初期建议保持简单：

- 单条 lesson 可以映射多个 target
- 每个 target 明确 `change_kind`
- 默认置信度写在映射里
- recommendation 只负责组合，不自己发明目标文件

## 8. 推荐的自动更新判定策略

是否建议升级成共享规则，建议至少看 4 个维度：

- `repeat_count`
- `evidence_strength`
- `blast_radius`
- `fix_cost`

可以先用轻量规则：

- 若 `repeat_count < 2` 且 `evidence_strength` 不是 `strong`，默认 `record-only`
- 若 lesson 已在 2 个以上项目中重复出现，优先生成 recommendation
- 若命中的是核心治理文件，则默认只出 patch 草案
- 若 lesson 只影响单一 skill reference，则可在人工确认后直接 apply

再补一条治理型判断：

- 若建议变更会影响 skill 的发现面、触发面或维护规则，则必须同时评估索引同步与校验同步
- 若 lesson 属于长任务执行缺口，则优先考虑 `plan / verify / ship / retrospective reference`，而不是直接引入阻断式 hook

## 9. 当前技能应该如何演进

当前不建议新建一个完全独立的“skill-auto-updater”技能。

更好的路径是：以 `codex-record-retrospective` 为入口，把自动更新链路分层吸收到已有 skill 里。

### 9.1 为什么不新建独立技能

因为当前问题的主入口仍然是“复盘真实记录”。

如果单独再建一个自动更新技能，会带来两个问题：

- 触发面重复，用户不容易判断该用哪个
- recommendation engine 会脱离原始证据上下文，容易变成空转规则生成器

### 9.2 建议对当前技能做的增强

建议增强 `codex-record-retrospective` 的 4 个能力：

- 明确支持输出 retrospective artifact
- 明确支持读取 lesson-target mapping 生成 recommendation artifact
- 明确支持区分 `record-only / patch-proposed / apply-approved`
- 明确要求把适合长期沉淀的结论写入 evolution ledger

### 9.3 当前技能的职责边界

增强后它仍然不是“自动修改器”，而是：

- 证据扫描入口
- lesson 归一入口
- recommendation 生成入口
- 审批前的候选变更入口

真正修改仓库时，仍然应回到 `skill-maintenance` 或对应 `build` 流程。

## 10. 推荐的近期实现顺序

### Phase 1：把机制接点补齐

目标：

- 补 reference：自动进化闭环说明
- 补 mapping：`lesson-target-map.json`
- 补脚本：从 retrospective JSON 生成 recommendation artifact
- 补 skill：把这些入口接入 `codex-record-retrospective`

### Phase 2：让 artifact 稳定输出

目标：

- retrospective 结果默认支持 JSON + Markdown
- recommendation 默认支持 JSON，Markdown 可选
- ledger 有稳定 append 规则
- recommendation 输出中显式标记是否需要 discovery / governance sync
- validator 输出能作为 recommendation 落地前的最小结构证据

### Phase 3：打通审批后 apply

目标：

- recommendation 被接受后，可进入 `skill-maintenance` 或普通 `build`
- 自动补 `STATE.md`
- 做最小文本级验证
- 若影响发现面，补齐相关索引或校验同步
- skill 相关变更默认跑 `validate-skills.py`

### Phase 4：考虑自动触发

目标：

- 按事件或按周触发 retrospective
- 只自动生成候选，不绕过审批门

### 10.1 适合 Codex 自动化的默认形态

如果采用 Codex 自动化，建议第一版固定为：

- 工作日每天上午执行一次
- 默认回顾“昨天”的使用记录
- 输出 retrospective summary
- 命中稳定 lesson 时输出 recommendation
- 结果进入 inbox
- 默认不改仓库

这样可以把“每天上班先看昨天经验总结”变成低风险、可持续的 routine，而不是高风险自更新任务。

### 10.2 推荐的每日自动化输出结构

如果每天定时运行，建议 inbox 中的结果固定包含：

1. 昨天扫描了哪些项目或会话
2. strongest evidence 和 evidence gaps
3. 重复出现的 lesson
4. 哪些只是项目噪音
5. 命中的 `lesson-target-map`
6. 建议级别：`record-only` 或 `patch-proposed`
7. 是否需要 discovery / governance sync
8. 是否建议进入下一步 `skill-maintenance`

这样每天早上读起来会很稳定，也方便长期比较。

### 10.3 默认验证门

当自动复盘的结果要推进为 skill/protocol 变更时，建议默认走这条验证链：

1. recommendation artifact
2. `validate-skills.py` 这类轻量静态校验
3. 人工 review
4. 必要时再进入更强的 verify / smoke / release-check

这样可以把“结构错了、引用坏了、入口过胖了”这类问题前移，而不是等到 review 或 merge 后才发现。

### 10.4 默认账本写入

当 retrospective 或 recommendation 已经形成结构化 JSON 时，建议默认追加到 evolution ledger：

1. recommendation JSON 生成完成
2. `append_evolution_ledger.py` 追加账本
3. 再进入人工 review 或后续 apply

这样能确保：

- 重复 lesson 有累计记录
- 被接受和被拒绝的建议都能留下痕迹
- 后续不需要重新扫描整段会话才能知道某类问题是否重复出现

### 10.5 默认后处理入口

当 daily automation 或人工 retrospective 已经生成 retrospective JSON 后，建议默认调用：

- `process_retrospective.py`

它负责：

1. 渲染 retrospective Markdown
2. 生成 recommendation JSON
3. 生成 recommendation Markdown
4. 追加 evolution ledger

这样可以避免每日自动化自己分别拼 recommendation 和 ledger 的调用链。

### 10.6 关于“一个 session 里多个回话”的处理

真实使用里，一个长 session 往往会连续承载多个独立小任务。\n如果直接按 session 维度复盘，会出现两个问题：

- lesson 被串味
- recommendation 误把后半段任务的问题归到前半段上下文里

因此当前建议口径已经升级为：

- `session` 不是默认最小复盘单位
- `task slice / conversation slice` 才是更可靠的 lesson 提炼单位

当前仓库已补第一版切片工具：

- [.agents/skills/planning/codex-record-retrospective/scripts/slice_codex_session.py](/Users/gclm/workspace/lab/ai/super-stack/.agents/skills/planning/codex-record-retrospective/scripts/slice_codex_session.py)

第一版切片启发主要看：

- 明显时间间隔
- 用户新一轮请求的边界提示词
- `cwd` 变化
- 一个 assistant 段结束后出现新的用户任务请求

这层是启发式支持，不是绝对真相，但已经比“整 session 一锅复盘”可靠得多。

### 10.7 对 `.planning` 方案的升级建议

结合公众号文章与 `stellarlinkco/skills`，我建议把 `.planning` 方案在原则上再升级一层：

- `.planning/` 不只是“阶段状态记录”
- 在长任务场景里，它还应承担“可恢复上下文”的角色

这不意味着把 `.planning` 变成 `harness-tasks.json` 的替代品，而是意味着：

- 对明显跨 session 的复杂任务，`ROADMAP.md` 和 `STATE.md` 应更明确记录当前阶段、下一步、验证口径、未决决策
- 自动复盘产物与 evolution ledger 不放进 `.planning/`，但它们应与 `.planning` 形成稳定互补
- 当 retrospective 发现“过早完成、缺少进度产物、恢复失败”这类问题时，应回头升级 planning 约定，而不是只改回答措辞

## 11. 对标后的完整机制建议

把我们当前初版方案、公众号文章、MiniMax 仓库三者合起来，我建议 `super-stack` 的技能自动更新机制采用下面这条完整链路：

### 11.1 输入层

- Codex 本地 records
- 项目路径与历史 alias
- review / verify / qa 暴露出的重复问题
- 日常定时自动化触发
- 长任务 / 多 session 执行信号

### 11.2 提炼层

- retrospective artifact
- lesson normalization
- evidence strength / evidence gaps
- repeated signal detection
- execution-shape analysis（普通任务 vs 长任务）

### 11.3 映射层

- `lesson-target-map.json`
- recommendation generation script
- approval level
- governance / discovery sync check

### 11.4 治理层

- `record-only / patch-proposed / apply-approved`
- validator gate
- 文本级验证
- skill-maintenance 或 build 落地
- `STATE.md` 回写
- evolution ledger 追加
- 长任务模式只吸收协议，不默认吸收强 hook 语义

### 11.5 运行层

- 手动触发：针对某项目复盘
- 事件触发：高复杂度任务结束、反复 backtrack、重复纠正
- 定时触发：工作日自动复盘昨天经验

### 11.6 核心原则

- 薄入口，不堆主文件
- 结构化 artifact 优先
- 表驱动 recommendation 优先
- 自动验证与人工 review 分层
- source repo 真源优先
- 不绕过审批门
- 发现面和治理面同步维护

## 12. 当前不建议优先做的事

### 12.1 不建议先做无监督自动 apply

原因：

- 核心治理文件风险高
- 项目噪音很容易误伤共享规则

### 12.2 不建议先做复杂多 agent 编排

原因：

- 当前最大收益不在 orchestration
- 更大的收益来自稳定产物、映射、审批和 ledger

### 12.3 不建议让 recommendation engine 直接自由生成目标文件

原因：

- 会让建议不可复现
- 会让 review 成本反而上升

## 13. 一句话结论

`super-stack` 的技能自动更新机制，最合理的落点不是“新增一个会自己改自己的 agent”，而是让 `codex-record-retrospective` 升级成“证据扫描 + lesson 归一 + recommendation 生成”的入口，再通过 mapping、ledger、审批门和最小验证，把经验稳态地沉淀回 source repo。

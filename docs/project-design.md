# super-stack 项目架构设计

这份文档用于说明 `super-stack` 的长期架构，而不是只描述当前仓库里有哪些文件。

目标是回答 4 个问题：

1. `super-stack` 到底是什么
2. 它为什么要这么分层
3. 当前已经落地到什么程度
4. 后续演进时哪些边界不能轻易打破

## 1. 项目定义

`super-stack` 是一套面向 `Claude Code` 与 `Codex` 的共享 agent workflow runtime。

它不是：

- 某一个项目的提示词包
- 某一个宿主专用插件
- 单纯的 skills 仓库
- 只负责安装、不负责验证的配置集合

它是：

- 一套跨宿主共享的工作流核心
- 一套把阶段路由、技能、状态文件、hooks、安装、验证串起来的系统
- 一套以“全局默认工作流底座”为目标的长期可演进方案

一句话概括：

`super-stack = 可安装、可验证、可扩展的跨宿主 agent workflow 基础设施`

## 2. 设计背景

这个项目的形成，不是从抽象架构设计开始的，而是从一系列真实使用痛点倒逼出来的。

### 2.1 宿主能力不一致

Claude Code 和 Codex 虽然都能做 agent workflow，但差异很大：

- skills 的发现方式不同
- hooks 的接线方式不同
- 全局配置入口不同
- 浏览器能力、MCP、插件能力成熟度不同

如果分别维护两套：

- 成本高
- 规则容易漂移
- 验证重复
- 经验难沉淀

所以必须做“共享核心 + 薄适配层”。

### 2.2 工作流漂移

如果阶段路由只靠模型上下文记住，很容易出现：

- 该 `discuss` 时直接 `build`
- 该 `verify` 时提前宣称完成
- 该 `map-codebase` 时直接猜

这会让工作流看起来“会动”，但不稳定。

所以 `super-stack` 明确把“阶段路由”前置成核心能力。

### 2.3 历史生态噪音

你本地已有的 `~/.claude`、`~/.agents`、`gclm-flow` 等历史资产非常有价值，但也带来了现实问题：

- 技能很多
- hooks 很多
- 路径很多
- 不是所有内容都还适合继续沿用

所以 `super-stack` 不是简单迁移旧生态，而是抽取出：

- 高价值经验
- 真实噪音模式
- 最稳定的工作流骨架

## 3. 总体架构

从架构视角看，`super-stack` 分成 5 层：

1. 共享路由层
2. 共享技能层
3. 共享协议与模板层
4. 宿主适配层
5. 安装与验证层

### 3.1 架构图

```text
                +------------------------------+
                |         super-stack          |
                +------------------------------+
                             |
      +----------------------+----------------------+
      |                                             |
      v                                             v
+--------------+                         +------------------+
| Shared Route |                         | Shared Skills    |
| AGENTS.md    |                         | .agents/skills/  |
+--------------+                         +------------------+
      |                                             |
      +----------------------+----------------------+
                             |
                             v
                  +------------------------+
                  | Shared Protocols       |
                  | protocols/ templates/  |
                  +------------------------+
                             |
          +------------------+------------------+
          |                                     |
          v                                     v
 +---------------------+             +----------------------+
 | Claude Adapter      |             | Codex Adapter        |
 | .claude/            |             | .codex/              |
 | hooks/settings sync |             | config/hooks sync    |
 +---------------------+             +----------------------+
          |                                     |
          +------------------+------------------+
                             |
                             v
                  +------------------------+
                  | Install / Check / QA   |
                  | scripts/ + validation  |
                  +------------------------+
```

## 4. 共享核心设计

共享核心的目标是：

- 尽量不依赖宿主特性
- 尽量不依赖历史对话
- 尽量能在不同宿主上复用

### 4.1 路由层：`AGENTS.md`

这是系统的第一入口。

它负责：

- 定义主流程
- 决定阶段切换
- 约束阶段前置条件
- 定义默认工程约定
- 规定 supporting skills 何时使用

它解决的问题是：

- “现在该进入哪个阶段”

而不是：

- “这个阶段内的具体步骤怎么做”

这点非常关键。

### 4.2 技能层：`.agents/skills/`

技能层负责：

- 阶段手册
- 专项问题处理方式
- supporting skills 的使用流程

它解决的问题是：

- “进入这个阶段或这个专项技能后，具体怎么执行”

当前高价值技能可分为 4 组：

#### 4.2.1 核心交付链

- `discuss`
- `plan`
- `build`
- `review`
- `verify`
- `ship`

#### 4.2.2 结构与探索

- `brainstorm`
- `map-codebase`
- `architecture-design`
- `service-boundary-review`

#### 4.2.3 工程专项

- `frontend-refactor`
- `backend-refactor`
- `api-design`
- `database-design`
- `migration-design`
- `integration-design`

#### 4.2.4 质量与运行态

- `qa`
- `debug`
- `bugfix-verification`
- `release-check`
- `security-review`
- `performance-investigation`
- `browse`

### 4.3 协议层：`protocols/`

协议层承载的是“尽量不随宿主变化”的工程约束，例如：

- review 关注什么
- verify 要如何证明完成
- tdd 的基本节奏

协议层存在的价值是：

- 避免把这些通用规则散落到每个 skill 里

### 4.4 模板层：`templates/`

模板层主要服务两件事：

1. planning 状态落地
2. validation 证据记录

这层的核心价值是：

- 把“项目状态”和“验证结果”从对话转成文件

## 5. 宿主适配设计

### 5.1 Claude 适配层

Claude 当前真正依赖的是：

- `~/.claude/CLAUDE.md`
- `~/.claude/skills/`
- `~/.claude/settings.json`

其中最关键的一点是：

- hooks 真正生效的位置是 `settings.json`

所以 Claude 适配层的目标不是简单复制文件，而是：

1. 同步共享核心副本
2. 镜像 skills
3. 将 super-stack hooks 非破坏式合并进 `settings.json`

当前已接入的 hooks 包括：

- `SessionStart`
- `PreToolUse`
- `Stop`

### 5.2 Codex 适配层

Codex 当前真正依赖的是：

- `~/.codex/AGENTS.md`
- `~/.agents/skills/`
- `~/.codex/skills/`
- `~/.codex/config.toml`

Codex 与 Claude 最大的不同在于：

- 它不适合假设“每次都能稳定自动展开 skill 全文”

因此当前设计采用：

- `AGENTS.md` 负责阶段路由
- `skills` 作为详细手册
- `config.toml` 负责 hooks

Codex 当前已接入的 hooks 包括：

- `session_start`
- `pre_tool_use`
- `stop`

## 6. 全局优先策略

目前 `super-stack` 的明确策略是：

- 全局 super-stack 优先
- 项目级 super-stack 作为薄覆盖层

这不是临时选择，而是当前架构中的核心策略。

### 6.1 为什么选择全局优先

原因很现实：

- 你的真实使用方式是“全局默认工作流”
- 项目级复制会放大维护成本
- 共享经验更适合沉淀在全局层

### 6.2 项目级覆盖的定位

项目级存在的价值不是再复制一套 super-stack，而是：

- 增补项目特有规则
- 覆盖少量项目专属行为
- 提供团队协作可见性

所以项目级应该尽量薄。

## 7. 工作流设计

当前主链路是：

`discuss -> plan -> build -> review -> verify -> ship`

### 7.1 这条主链解决什么问题

它的作用不是“看起来完整”，而是为了强制回答 6 个不同问题：

- `discuss`
  - 需求到底是什么
- `plan`
  - 任务如何拆解
- `build`
  - 实现怎么落地
- `review`
  - 改动有没有风险
- `verify`
  - 到底有没有真的达成目标
- `ship`
  - 如何准备交付和后续动作

### 7.2 为什么不是纯 skills-first

因为纯 skills-first 在双宿主环境里存在风险：

- Claude 和 Codex 的触发稳定性不同
- 只靠 skill 名称容易漂移
- supporting skill 很容易“喧宾夺主”

所以当前采用：

- 路由先行
- 技能后置

## 8. Hooks 设计

当前 hooks 已经不是概念，而是已经有真实运行态验证的能力。

### 8.1 状态恢复 hooks

目标：

- 跨轮恢复 `.planning/STATE.md`
- 降低上下文漂移

当前已在 Claude 和 Codex 两侧接通。

### 8.2 readonly auto-allow hooks

目标：

- 自动放行高频只读 shell 命令
- 降低确认噪音
- 保守而不是激进

当前共享脚本：

- [readonly_command_guard.py](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/hooks/readonly_command_guard.py)

当前策略：

- 白名单只读命令放行
- 写入迹象一律不自动放行
- 复杂无法稳定判断的命令透传

当前已经验证：

- Claude 运行态生效
- Codex 运行态生效

### 8.3 hooks 设计原则

当前明确坚持三条原则：

1. 先解决高频噪音
2. 不把 hooks 一步做成重型规则引擎
3. 优先跨宿主共用判定逻辑

## 9. 安装与验证体系

这是 `super-stack` 与很多参考项目最大的差异之一。

当前系统不仅关心“文件装没装上”，更关心“功能是否真的生效”。

### 9.1 安装层

核心脚本：

- [install.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/install.sh)
- [sync-to-claude.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/sync-to-claude.sh)
- [sync-to-codex.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/sync-to-codex.sh)

### 9.2 检查层

核心脚本：

- [check-global-install.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/check-global-install.sh)

当前检查内容包括：

- 路由文件存在
- 路由内容一致
- skills 镜像匹配
- hooks 已接入

### 9.3 smoke test 层

核心脚本：

- [smoke-test-claude-global.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/smoke-test-claude-global.sh)
- [smoke-test-codex-global.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/smoke-test-codex-global.sh)

### 9.4 回归层

核心脚本：

- [smoke-test-codex-regression-suite.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/smoke-test-codex-regression-suite.sh)
- [smoke-test-readonly-hook.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/smoke-test-readonly-hook.sh)

## 10. 当前落地状态

基于目前仓库与运行态验证，可以把当前状态归纳为：

### 10.1 已经稳定的部分

1. 共享路由架构
2. skills 分层结构
3. 全局优先安装策略
4. Claude / Codex 双宿主全局接线
5. 状态恢复 hooks
6. readonly auto-allow hooks
7. 安装检查与回归脚本
8. 中文文档与中文 Angular commit 约定

### 10.2 已经验证过但仍需增强的部分

1. `browse` 路由
2. 运行时体检与环境噪音识别
3. 参考项目吸收与经验回写

### 10.3 还没有完全补齐的部分

1. 浏览器真实自动化能力
2. hooks 风险分级
3. 更体系化的经验回写机制
4. 历史生态清理策略

## 11. 架构边界

后续演进时，这些边界建议不要轻易破坏。

### 11.1 不要把共享核心重新塞回宿主目录

原因：

- 会重新造成分裂维护

### 11.2 不要让项目级覆盖反客为主

原因：

- 当前主策略是全局默认底座

### 11.3 不要让 hooks 先于验证体系疯狂扩张

原因：

- hooks 一旦变复杂，没有验证会非常难维护

### 11.4 不要把参考项目直接当模板复制

原因：

- 参考项目提供的是思路
- super-stack 需要形成自己的跨宿主主线

## 12. 当前最重要的下一步

如果只看架构层面，后续最值得优先补齐的是三件事：

1. 浏览器真实能力接入
2. hooks 从“降噪”升级到“风险分级”
3. 经验回写与参考吸收流程结构化

## 13. 文档索引

当前建议配套阅读：

- [reference-projects.md](/Users/gclm/Codes/ai/claude-stack-plugin/docs/reference-projects.md)
- [readonly-command-hook.md](/Users/gclm/Codes/ai/claude-stack-plugin/docs/readonly-command-hook.md)
- [evolution-roadmap.md](/Users/gclm/Codes/ai/claude-stack-plugin/docs/evolution-roadmap.md)

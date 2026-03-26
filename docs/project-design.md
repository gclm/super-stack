# super-stack 项目架构设计

这份文档用于说明 `super-stack` 的长期架构，而不是只描述当前仓库里有哪些文件。

目标是回答 3 个问题：

1. `super-stack` 到底是什么
2. 它为什么要这么分层
3. 后续演进时哪些边界不能轻易打破

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
- 浏览器能力接线方式不同

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
- `frontend-design`
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
- `~/.codex/config.toml`

Codex 与 Claude 最大的不同在于：

- 它不适合假设“每次都能稳定自动展开 skill 全文”

因此当前设计采用：

- `AGENTS.md` 负责阶段路由
- `skills` 作为详细手册
- `config.toml` 负责 hooks

说明：

- 上游 Codex 目前仍会向后兼容扫描 `~/.codex/skills/`
- 但当前正式的用户级 skills 路径已经是 `~/.agents/skills/`
- 因此 `super-stack` 不再继续维护 `~/.codex/skills/` 的旧兼容副本

Codex 当前已接入的 hooks 包括：

- `session_start`
- `pre_tool_use`
- `stop`

### 5.3 source repo / runtime repo 边界

后续维护采用更清晰的 source/runtime 模型：

1. 当前仓库是 `source repo`
2. `~/.super-stack/runtime` 是 `runtime repo`
3. `~/.super-stack/state` 存安装状态
4. `~/.super-stack/backup` 存安装与卸载备份

这里不再继续细分更多抽象层。最重要的是把“开发仓库”和“运行仓库”这两个对象彻底区分开。

约束是：

- source repo 负责源码、文档、测试、脚本与安装输入
- runtime repo 负责宿主真实运行时使用的资产
- runtime repo 采用纯运行仓库模型，不承担完整安装源材料角色
- 宿主入口应该只引用 runtime repo
- 不再让 `~/.claude/super-stack` 与 `~/.codex/super-stack` 分别承担独立运行仓库角色

当前一个关键现实是：

- `~/.super-stack/runtime` 已经作为统一运行仓库承载共享运行时资产
- 宿主入口已经统一接到 `~/.super-stack/runtime`
- skills 仍按宿主发现机制镜像到 `~/.agents/skills` 与 `~/.claude/skills`

所以后续要做的不是再发明概念，而是围绕这套 source/runtime + state/backup 结构保持安装、检查、卸载与文档同步。
其中安装动作始终从 source repo 发起，runtime 只保留运行所需最小资产。

完整说明见 [source/runtime 边界设计](source-runtime-boundary.md)。

### 5.4 浏览器接线

当前浏览器能力已经收敛为单方案：

- 底层方案：`agent-browser`
- 稳定入口：`super-stack-browser`
- 安装方式：全局 `npm install -g agent-browser`

这里的设计目标不是“支持尽可能多的浏览器技术选项”，而是：

- 保持一条稳定主链路
- 降低重复授权
- 降低会话漂移
- 让 `browse` 技能有明确、可验证的默认入口

浏览器技术调研与历史取舍不再放在本设计文档中展开，统一见：

- [浏览器技术选型记录](browser-technology-options.md)

## 6. 全局安装主线

目前 `super-stack` 的明确策略是：

- super-stack 作为唯一维护的全局配置底座
- 不再继续维护项目级安装分支与项目级覆盖安装链路

这不是临时选择，而是当前架构中的核心策略。

### 6.1 为什么收敛为全局安装主线

原因很现实：

- 你的真实使用方式是“全局默认工作流”
- 项目级复制会放大维护成本
- 共享经验更适合沉淀在全局层

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

- [readonly_command_guard.py](../scripts/hooks/readonly_command_guard.py)

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

## 9. 架构边界

后续演进时，这些边界建议不要轻易破坏。

### 9.1 不要把共享核心重新塞回宿主目录

原因：

- 会重新造成分裂维护

### 9.2 不要重新引入项目级安装分支

原因：

- 当前主策略是全局默认底座

### 9.3 不要让 hooks 先于验证体系疯狂扩张

原因：

- hooks 一旦变复杂，没有验证会非常难维护

### 9.4 不要把参考项目直接当模板复制

原因：

- 参考项目提供的是思路
- super-stack 需要形成自己的跨宿主主线

# super-stack

面向 `Claude Code` 与 `Codex` 的共享工作流底座。

`super-stack` 不是某一个项目里的提示词集合，也不是只给单一宿主使用的插件配置。它更接近一套可安装、可验证、可演进的 agent workflow runtime，用来把下面这些东西统一起来：

- 用 `AGENTS.md` 做稳定阶段路由
- 用 `.agents/skills/` 承载可复用技能
- 用 `.planning/` 和模板沉淀跨轮状态
- 用 `.claude/` 与 `.codex/` 适配不同宿主
- 用 `scripts/` 串起安装、同步、检查与回归验证
- 用 `docs/` 记录设计、参考来源和演进路线

## 这个项目解决什么问题

`super-stack` 主要想解决 4 类现实问题：

1. `Claude Code` 和 `Codex` 的工作流不要分裂维护。
2. 阶段路由不要只靠模型“临场发挥”，而要有稳定骨架。
3. 项目状态不要只存在聊天记录里，要尽量落到文件和模板。
4. 安装成功不等于真正生效，需要有可重复的检查和 smoke test。

当前已经明确的主策略是：

- 全局 `super-stack` 优先
- 项目级配置作为薄覆盖层

当前浏览器能力的默认策略也已经明确：

- 主方案使用 `agent-browser`
- 默认入口使用稳定包装命令 `super-stack-browser`
- 不再把其他浏览器技术选项作为当前默认集成方案

更具体一点：

- 本地前端调试、DOM / console / network 验证，默认优先 `super-stack-browser`
- `super-stack-browser` 会固定走 `agent-browser --auto-connect --session-name super-stack-browser`
- 这样做的目标是减少重复授权、减少会话漂移、降低使用噪音
- `agent-browser` 本体通过 `npm install -g agent-browser` 维护

也就是说，平时优先把 `super-stack` 作为你的默认全局工作流底座，只有在某个仓库确实需要项目特化时，再加项目级覆盖。

## 快速开始

推荐先做全局安装。

同时安装 `Claude` 与 `Codex`：

```bash
./scripts/install.sh --host all --mode global
```

只安装 `Codex`：

```bash
./scripts/install.sh --host codex --mode global
```

只安装 `Claude`：

```bash
./scripts/install.sh --host claude --mode global
```

安装完成后，先做一轮健康检查：

```bash
./scripts/check-global-install.sh
```

说明：

- `./scripts/install.sh` 现在会自动一并安装浏览器主链路
- 也就是会自动准备 `super-stack-browser`

如果你之后想移除全局安装：

```bash
./scripts/uninstall-global.sh
```

如果你只想单独重装浏览器能力：

```bash
./scripts/setup-browser.sh
./scripts/check-browser-capability.sh
```

安装完成后，日常建议直接用：

```bash
~/.claude-stack/bin/super-stack-browser open https://example.com
```

如果你遇到会话卡住或授权状态异常，可以先重置稳定会话：

```bash
./scripts/reset-browser-session.sh
```

## 3 分钟上手示例

如果你是第一次接触 `super-stack`，可以直接按下面这组命令走一遍。目标不是一次性理解全部设计，而是先确认“安装成功，并且宿主真的识别到了这套全局工作流”。

### 第 1 步：安装到本机全局

```bash
cd /Users/gclm/Codes/ai/claude-stack-plugin
./scripts/install.sh --host all --mode global
```

预期结果：

- `~/.codex/AGENTS.md` 中出现 `super-stack` 托管块
- `~/.claude/CLAUDE.md` 中出现 `super-stack` 托管块
- `~/.agents/skills/`、`~/.codex/skills/`、`~/.claude/skills/` 被同步
- `~/.claude-stack/bin/super-stack-browser` 被自动准备

### 第 2 步：做一轮安装检查

```bash
./scripts/check-global-install.sh
```

预期结果：

- 脚本输出整体 `PASS`
- 不再只是“文件复制过去了”，而是共享技能、托管块和关键宿主入口都被检查到

### 第 3 步：验证 Codex 侧的阶段路由

```bash
./scripts/smoke-test-codex-regression-suite.sh
```

预期结果：

- `Codex` 可以稳定命中 `discuss`、`brainstorm`、`review`、`verify` 等关键阶段
- 说明全局 `AGENTS.md + skills + hooks` 主链路已经接通

### 第 4 步：验证 Claude 侧全局链路

```bash
./scripts/smoke-test-claude-global.sh
```

预期结果：

- `Claude` 侧能识别全局托管内容
- hooks 合并、技能入口和基础运行能力检查通过
- 如果本地 browse binary、browser MCP、browser plugin 都还没接通，可能出现 browser 相关 warning，这属于当前已知待补齐项

### 第 5 步：单独验证 readonly Hook

```bash
./scripts/smoke-test-readonly-hook.sh
```

预期结果：

- `pwd`、`git status`、`rg` 这类只读命令能被自动放行
- 日志中能看到 `allow` 记录，说明 hook 不是“装上了但没触发”

### 一次验证通过后，你就得到了什么

如果上面 5 步都通过，可以先认为这套全局底座已经具备了：

- `Claude Code` / `Codex` 双宿主共享路由
- 高价值技能的基础识别能力
- 安装可检查、行为可验证的最小闭环
- 只读命令降噪 hook 的真实运行证据

接下来你再进入 `docs/` 阅读设计和路线图，会更容易把抽象结构和真实行为对上。

## 推荐验证链路

不要只看文件是否存在，建议按下面这条最小证据链验证：

1. 安装完成后运行：

```bash
./scripts/check-global-install.sh
```

2. 验证 `Codex` 全局路由与技能回归：

```bash
./scripts/smoke-test-codex-regression-suite.sh
```

3. 验证 `Claude` 全局链路：

```bash
./scripts/smoke-test-claude-global.sh
```

4. 单独验证只读命令自动放行 Hook：

```bash
./scripts/smoke-test-readonly-hook.sh
```

目前这条链路已经覆盖：

- 全局托管块是否正确写入
- 共享技能是否同步到宿主可发现目录
- `Codex` 阶段路由与技能识别是否正常
- `Claude` hooks 合并与基础能力探测是否正常
- readonly hook 是否真的在运行态放行只读命令

如果你想单独复查浏览器主链路，可以再跑：

```bash
./scripts/setup-browser.sh
./scripts/check-browser-capability.sh
```

当前默认结论：

- `super-stack-browser` 是推荐日常入口，优先解决重复授权和会话不稳定
- `agent-browser` 是底层主方案，由全局 npm 包提供
- 当前仓库不再把其他浏览器技术选项作为默认保留方案

## 文档导航

首页只保留“是什么、怎么装、怎么验”的核心信息，更细的设计和调研都放在 `docs/`：

- [项目架构设计](/Users/gclm/Codes/ai/claude-stack-plugin/docs/project-design.md)
  - 解释 `super-stack` 是什么、为什么这样分层、哪些边界不能轻易打破
- [参考项目调研与吸收映射](/Users/gclm/Codes/ai/claude-stack-plugin/docs/reference-projects.md)
  - 汇总 `GSD`、`Superpowers`、`gstack`、`ECC`、`bdarbaz/claude-stack-plugin` 等参考来源
- [浏览器技术选型记录](/Users/gclm/Codes/ai/claude-stack-plugin/docs/browser-technology-options.md)
  - 汇总浏览器方案测试记录、保留理由与当前正确入口
- [只读命令 Hook 方案](/Users/gclm/Codes/ai/claude-stack-plugin/docs/readonly-command-hook.md)
  - 说明 readonly auto-allow 的设计、边界和后续演进方向
- [演进路线图](/Users/gclm/Codes/ai/claude-stack-plugin/docs/evolution-roadmap.md)
  - 记录当前阶段判断和下一步优先级

如果你想在真实项目里做验证，也可以直接使用这些模板：

- [真实项目验证模板](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/REAL_PROJECT_VALIDATION.md)
- [技能回归矩阵](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/SKILL_REGRESSION_MATRIX.md)
- [工作流体验验证](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/WORKFLOW_EXPERIENCE_VALIDATION.md)

## 核心工作流

默认阶段链路是：

```text
discuss -> plan -> build -> review -> verify -> ship
```

当前仓库已经补齐的高价值技能包括：

- `discuss`
- `brainstorm`
- `map-codebase`
- `plan`
- `build`
- `review`
- `verify`
- `qa`
- `ship`
- `debug`
- `browse`
- `tdd-execution`
- `release-check`
- `frontend-refactor`
- `backend-refactor`
- `bugfix-verification`
- `api-change-check`
- `api-design`
- `database-design`
- `architecture-design`
- `migration-design`
- `integration-design`
- `query-optimization`
- `service-boundary-review`
- `scalability-check`
- `observability-design`
- `incident-debug`
- `security-review`
- `performance-investigation`

## 默认工程约定

如果目标项目没有明确声明自己的规则，`super-stack` 当前默认采用以下约定：

- 需要用户阅读、确认、评审的文档默认使用中文
- 代码、命令、配置键、路径、协议名保持英文
- Git commit 采用 Angular 结构，但摘要使用中文

默认提交格式：

```text
type(scope): 中文摘要
```

例如：

```text
feat(runtime): 增加本地运行态探测
docs(validation): 补充真实项目验证记录
refactor(frontend): 拆分运行时页面结构
```

如果某个项目已有更高优先级的团队约定，以项目约定为准。

## 全局安装后会写入什么

### Codex

全局安装后会写入或更新这些内容：

- `~/.codex/super-stack/`
  - 保存共享核心副本
- `~/.codex/AGENTS.md`
  - 追加 `super-stack` 全局托管块
- `~/.agents/skills/`
  - 安装全局共享技能
- `~/.codex/skills/`
  - 安装兼容镜像，便于兼容旧路径
- `~/.codex/agents/`
  - 安装 namespaced agent 配置
- `~/.codex/config.toml`
  - 非破坏式合并 `session_start` / `pre_tool_use` / `stop` hooks

### Claude

全局安装后会写入或更新这些内容：

- `~/.claude/super-stack/`
  - 保存共享核心副本
- `~/.claude/CLAUDE.md`
  - 追加 `super-stack` 全局托管块
- `~/.claude/skills/`
  - 镜像 Claude 侧可发现的技能入口
- `~/.claude/settings.json`
  - 非破坏式合并 `SessionStart` / `PreToolUse` / `Stop` hooks

说明：

- `Claude` hooks 的真实生效入口以 `~/.claude/settings.json` 为准
- `super-stack` 安装不会粗暴清空你已有的 hooks，而是做合并接入

## 项目级安装什么时候用

当某个仓库需要项目专属覆盖层时，再使用项目级安装：

```bash
./scripts/install.sh --host all --mode project --target /path/to/project
```

项目级安装完成后，可以检查：

```bash
./scripts/check-project-install.sh --target /path/to/project --host all
```

项目级模式会：

- 创建 `target/.super-stack/`
- 在这些文件中追加托管块：
  - `target/AGENTS.md`
  - `target/.codex/AGENTS.md`
  - `target/.claude/CLAUDE.md`
- 镜像技能到：
  - `target/.agents/skills/`
  - `target/.claude/skills/`

当前推荐仍然是：

- 全局作为默认底座
- 项目级只做必要覆盖

## 仓库结构

- `AGENTS.md`
  - 共享主路由，决定阶段与执行边界
- `.agents/skills/`
  - 共享技能定义，按 `core / planning / quality / ship` 分组
- `.claude/`
  - Claude 适配层与 hooks 配置
- `.codex/`
  - Codex 适配层、agent 配置与 hooks
- `templates/`
  - 规划、验证、状态记录模板
- `scripts/`
  - 安装、同步、检查、回归验证脚本
- `docs/`
  - 设计文档、参考项目调研、路线图与专项方案

## 参考项目复用边界

当用户说“参考某个项目”时，`super-stack` 默认优先吸收的是：

- 信息架构
- 页面或交互结构
- 模块边界
- workflow 组织方式
- hooks 与验证思路

而不是默认直接复制对方实现。

这样做是为了避免把“适合作为灵感的产品结构”误当成“适合直接继承的实现质量”。只有在用户明确要求直接复用实现，或者参考项目本身实现质量足够好时，才进入代码级继承路径。

## 当前状态

当前这套仓库已经完成了这些主线能力：

- 共享根路由与宿主适配层
- 全局优先安装与项目级覆盖
- Claude / Codex 双宿主 hooks 接线
- readonly auto-allow hook 骨架
- 高价值技能集与验证模板
- 安装检查、smoke test、真实运行态验证
- 中文文档优先与中文 Angular commit 约定

已知还在持续补齐的重点方向：

- 浏览器能力接通与真实前端排查链路
- hooks 从“降噪”走向更稳妥的风险分级
- 更多工程类技能与宿主一致性验证

## 下一步建议

如果你刚接手这个仓库，推荐按这个顺序继续：

1. 先阅读 [项目架构设计](/Users/gclm/Codes/ai/claude-stack-plugin/docs/project-design.md) 和 [参考项目调研与吸收映射](/Users/gclm/Codes/ai/claude-stack-plugin/docs/reference-projects.md)。
2. 在本机执行 `./scripts/install.sh --host all --mode global` 和 `./scripts/check-global-install.sh`。
3. 跑一轮 `Codex` / `Claude` smoke test，确认宿主接线与 hooks 正常。
4. 选一个真实项目，用验证模板记录一次技能命中与体验回归。
5. 再决定是继续补技能、补 hooks 风险治理，还是接通浏览器能力。

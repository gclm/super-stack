# super-stack

面向 Claude Code 与 Codex 的共享工作流底座。

这套仓库的目标不是做“某一个项目里的提示词集合”，而是提供一套可复用、可验证、可同步的全局工作流内核：

- 用统一的 `AGENTS.md` 做阶段路由
- 用 `.agents/skills/` 做可复用阶段手册
- 用 `protocols/` 放稳定工程规则
- 用 `.claude/` 与 `.codex/` 适配不同宿主

## 设计目标

`super-stack` 希望解决的是这几个问题：

1. Claude Code 和 Codex 的工作流不要分裂维护。
2. 项目状态不要只存在对话里，要尽量落到文件。
3. 阶段路由要稳定，不依赖某个宿主对 `SKILL.md` 的自动注入是否足够可靠。
4. 技能既要能复用，又不要把根提示词写成巨石。

## 当前推荐策略

经过真实项目验证后，当前推荐模式是：

- **全局 super-stack 优先**
- **项目级 super-stack 作为薄覆盖层**

也就是说：

- 平时主要依赖全局 `super-stack` 作为默认工作流底座
- 项目里如果有特殊需求，再额外同步项目级 `.super-stack/`、`.agents/skills/`、`.codex/AGENTS.md`、`.claude/CLAUDE.md`
- 对 Codex 来说，优先相信：
  - 根 `AGENTS.md` 负责阶段路由
  - `.codex/AGENTS.md` 负责宿主执行约束
  - `.agents/skills/` 负责阶段细节

这套策略已经在真实项目 `/Users/gclm/projects/coc` 上做过验证。

## 仓库结构

- `AGENTS.md`
  - 共享工作流主路由
- `.agents/skills/`
  - 可复用技能，按领域分组组织
- `templates/planning/`
  - 项目状态模板
- `protocols/`
  - 稳定工程协议，比如 `review`、`verify`、`tdd`
- `.claude/`
  - Claude Code 适配层
- `.codex/`
  - Codex 适配层
- `scripts/`
  - 安装与同步脚本

## 核心工作流

默认阶段链路是：

`discuss -> plan -> build -> review -> verify -> ship`

当前已内置的高价值技能包括：

- `discuss`
- `brainstorm`
- `map-codebase`
- `plan`
- `build`
- `review`
- `verify`
- `qa`
- `ship`

## Codex 适配思路

Codex 在这套方案里不是“纯 skills-first”，而是：

- `AGENTS.md` 负责主路由
- `.codex/AGENTS.md` 负责 Codex 宿主规则
- `.agents/skills/` 作为详细阶段手册
- `.planning/` 负责跨轮状态持久化

这是有意为之。

在真实实验中，Codex 可以识别项目级和全局技能，但**不能假设每次都会可靠自动展开完整 `SKILL.md`**。因此更稳的做法是：

- 先让 `AGENTS.md` 决定当前阶段
- 再按需读取对应 skill 的细节

## 安装方式

### 1. 全局安装

推荐优先使用全局安装，把 `super-stack` 作为你的默认底座。

同时安装 Claude 与 Codex：

```bash
./scripts/install.sh --host all --mode global
```

只安装 Codex：

```bash
./scripts/install.sh --host codex --mode global
```

只安装 Claude：

```bash
./scripts/install.sh --host claude --mode global
```

安装完成后，可用下面的命令做一键健康检查：

```bash
./scripts/check-global-install.sh
```

如果你想验证“全局 super-stack 不是只装上了，而是真的还能稳定做阶段路由”，可以运行：

```bash
./scripts/smoke-test-codex-global.sh
```

如果以后需要移除全局 super-stack，可使用：

```bash
./scripts/uninstall-global.sh
```

### 全局安装后会发生什么

#### Codex

全局安装后会写入或更新这些内容：

- `~/.codex/super-stack/`
  - 保存共享核心副本
- `~/.codex/AGENTS.md`
  - 追加 super-stack 全局托管块
- `~/.agents/skills/`
  - 安装全局 super-stack 技能
- `~/.codex/skills/`
  - 安装兼容镜像，便于兼容旧路径
- `~/.codex/agents/`
  - 安装 namespaced agent 配置

#### Claude

全局安装后会写入或更新这些内容：

- `~/.claude/super-stack/`
  - 保存共享核心副本
- `~/.claude/CLAUDE.md`
  - 追加 super-stack 全局托管块
- `~/.claude/skills/`
  - 镜像 Claude 侧可发现的技能入口

## 2. 项目级安装

当某个仓库需要项目专属覆盖层时，再使用项目级同步：

```bash
./scripts/install.sh --host all --mode project --target /path/to/project
```

项目级安装完成后，可用下面的命令做一键检查：

```bash
./scripts/check-project-install.sh --target /path/to/project --host all
```

项目级同步会：

- 创建 `target/.super-stack/`
- 在这些文件中追加托管块：
  - `target/AGENTS.md`
  - `target/.codex/AGENTS.md`
  - `target/.claude/CLAUDE.md`
- 镜像技能到：
  - `target/.agents/skills/`
  - `target/.claude/skills/`

注意：

- canonical 共享技能副本保存在 `target/.super-stack/.agents/skills/`
- 它可能按分组目录组织，例如 `core/`、`planning/`、`quality/`
- 项目镜像入口保持扁平，比如 `target/.agents/skills/review/`

## 如何验证是否加载成功

不要假设“安装完就一定生效”，建议每次用最小证据链验证。

### A. 文件层检查

如果是项目级安装，至少应存在：

- 根 `AGENTS.md` 中的 super-stack 托管块
- `.super-stack/AGENTS.md`
- `.agents/skills/`
- 对 Codex：`.codex/AGENTS.md`
- 对 Claude：`.claude/CLAUDE.md`

如果是全局安装，至少应存在：

- `~/.codex/super-stack/AGENTS.md`
- `~/.codex/AGENTS.md` 中的 super-stack 托管块
- `~/.agents/skills/`
- `~/.claude/super-stack/AGENTS.md`
- `~/.claude/CLAUDE.md` 中的 super-stack 托管块

也可以直接运行：

```bash
./scripts/check-global-install.sh
```

这个脚本会检查：

- Codex 全局托管块
- Claude 全局托管块
- `~/.agents/skills`
- `~/.codex/skills`
- `~/.claude/skills`
- 当前是否处于“global-first + project override”模式

如果想做行为级验证，还可以运行：

```bash
./scripts/smoke-test-codex-global.sh
```

这个脚本会验证 Codex 在空目录下是否还能稳定命中：

- `discuss`
- `brainstorm`
- `review`
- `verify`

如果是项目级健康检查，可以运行：

```bash
./scripts/check-project-install.sh --target /path/to/project --host all
```

这个脚本会检查：

- 项目根 `AGENTS.md` 托管块
- `.super-stack/AGENTS.md`
- `.agents/skills/`
- `.codex/AGENTS.md`
- `.claude/CLAUDE.md`
- 关键技能镜像与 canonical 内容是否一致

### B. Codex 最小验证

在目标目录下执行：

```bash
codex exec --skip-git-repo-check "用户说：我刚刚把项目级 super-stack 同步进这个项目了。请先验证 Codex 是否真的识别到了项目级 super-stack 配置，再判断这件事是否完成。优先使用最小且直接的证据，不要做无关的全仓扫描。"
```

如果是验证全局 super-stack，可以在一个空目录执行类似命令，例如：

```bash
codex exec --skip-git-repo-check "Do not read any repository-specific files. Based only on globally loaded instructions and available global skills, choose the single best-fit stage for this request and reply with exactly one line in the format STAGE=<name>: 我想先比较两三种实现路线，再决定采用哪一个。"
```

健康信号包括：

- Codex 明确进入正确阶段，例如 `brainstorm`
- 它能识别 `discuss / brainstorm / review / verify` 等 super-stack 技能
- 它会引用根 `AGENTS.md` 或项目/全局 skills 作为工作依据

### C. 阶段路由验证

可以用下面这些短提示做路由检查：

- `我想先把需求范围、约束和成功标准梳理清楚，再决定下一步。`
  - 期望命中：`discuss`
- `这个功能有两三种实现路线，我想先比较方案、权衡取舍，再决定采用哪一个。`
  - 期望命中：`brainstorm`
- `代码已经差不多写完了，请你重点检查正确性、回归风险和缺失测试。`
  - 期望命中：`review`
- `改动我觉得做完了，但请先根据最新证据确认它是否真的达成目标，再决定能不能宣称完成。`
  - 期望命中：`verify`

### D. 关键技能一致性检查

高价值的小范围一致性检查建议至少覆盖：

- `discuss`
- `brainstorm`
- `review`
- `verify`

预期关系是：

- canonical 内容位于 `.super-stack/.agents/skills/<group>/<skill>/SKILL.md`
- 项目入口镜像位于 `.agents/skills/<skill>/SKILL.md`
- 内容应一致，目录结构可以不同

## 全局模式下的注意事项

### 1. Codex 全局层尽量简单

为了让 super-stack 更稳定地主导行为，建议：

- `~/.codex/config.toml` 保持尽量小
- 复杂 hooks、agents、MCP、自定义路由不要堆回全局主配置

推荐最小配置通常只保留：

- `model_provider`
- `model`
- `model_reasoning_effort`
- `model_verbosity`
- `[model_providers.local]`

### 2. `~/.agents/skills` 会影响 Codex

这个 Codex 分支支持从 `~/.agents/skills` 加载用户技能。

因此：

- 如果你想验证项目级是否生效，最好先隔离全局 skills
- 如果你想让 super-stack 成为全局默认，就让 `~/.agents/skills` 直接由 super-stack 接管

当前这套仓库已经按后一种方式接好了。

### 3. 项目级优先于全局级

当前建议的优先级是：

1. 项目级 `AGENTS.md`
2. 项目级 `.codex/AGENTS.md` / `.claude/CLAUDE.md`
3. 项目级 `.agents/skills/`
4. 全局 super-stack

也就是说，全局 super-stack 是默认底座，但项目仍然可以有自己的薄覆盖。

## 当前状态

这套仓库目前已经完成了：

- 共享 root `AGENTS.md`
- 规划模板
- 9 个核心技能
- Claude 适配层
- Codex 适配层
- 项目级同步脚本
- 全局安装脚本
- 真实项目验证闭环
- 全局 super-stack 接管验证

## 下一步建议

如果继续往工程化方向走，最值得补的是：

1. 补更多可复用阶段技能
2. 增加行为级 smoke tests
3. 继续收敛 Claude 与 Codex 的宿主差异
4. 增加更细粒度的全局/项目覆盖策略

# super-stack

[![Status](https://img.shields.io/badge/status-active-2ea44f)](https://github.com/gclm/super-stack)
[![License: MIT](https://img.shields.io/badge/license-MIT-f5c542)](LICENSE)
[![Hosts](https://img.shields.io/badge/hosts-Claude%20Code%20%7C%20Codex-1f6feb)](AGENTS.md)
[![Legacy Repo](https://img.shields.io/badge/legacy-gclm--flow-8a8a8a)](https://github.com/gclm/gclm-flow)

面向 `Claude Code` 与 `Codex` 的共享全局 workflow runtime。

`super-stack` 的目标很明确：

- 用根 [AGENTS.md](AGENTS.md) 提供稳定阶段路由
- 用 [`.agents/skills/`](.agents/skills) 承载可复用技能
- 用 [`docs/`](docs) + [`harness/`](harness) 与 [`templates/generated-project/`](templates/generated-project) 沉淀目标项目骨架与状态约定
- 用 [`.claude/`](.claude) / [`.codex/`](.codex) 做宿主适配
- 用 [`scripts/`](scripts) 提供安装、检查、回归与测试闭环

当前边界也很明确：

- 只维护全局配置底座
- 不再维护项目级安装分支
- 浏览器默认主链路改为宿主侧 browser MCP / browser plugin；对 Codex 当前优先 `chrome-devtools-mcp`
- 宿主 MCP 受管配置按 `codex_mcp` / `claude_mcp` 两个 host block 维护；后续新增 MCP server 默认只改 `config/managed-config.json` 里的共享 `server_defs`
- `~/.super-stack/runtime` 是纯运行仓库，不是重新安装用的完整 source repo 副本

## 仓库关系

- 当前主仓库：`super-stack`
- 历史参考仓库：[`gclm-flow`](https://github.com/gclm/gclm-flow)
- 后续公开更新、结构演进与发布统一在当前仓库进行
- `gclm-flow` 仅保留为历史配置、旧技能与演进路径参考，不再作为主发布源

## 快速开始

安装 `Claude` 与 `Codex`：

```bash
./scripts/install/install.sh --host all
```

安装约束：

- 安装、重装、卸载都应从当前 source repo 执行
- `~/.super-stack/runtime` 只承载运行所需最小资产，不承载完整安装源材料

只安装 `Codex`：

```bash
./scripts/install/install.sh --host codex
```

只安装 `Claude`：

```bash
./scripts/install/install.sh --host claude
```

安装后先做健康检查：

```bash
./scripts/check/check-global-install.sh
```

如需卸载：

```bash
./scripts/install/uninstall-global.sh
```

浏览器能力检查：

```bash
./scripts/check/check-browser-capability.sh
```

当前约束：

- `super-stack` 不再安装或维护 `agent-browser` wrapper
- 浏览器能力由宿主配置决定
- `config/managed-config.json` 的顶层 `server_defs` 是当前受管 MCP server 真源
- Codex 当前应优先使用已配置的 `chrome-devtools-mcp`
- OpenSpace 当前已纳入 `codex_mcp` 的受管 server 列表；当宿主存在 `openspace-mcp` 或设置 `OPENSPACE_MCP_BIN` 时会自动写入 Codex 配置
- Claude Code 当前应优先使用已配置的 browser MCP 或 browser plugin

## 推荐验证链路

如果你想确认“不是装上了而是真的生效了”，建议按这条最小证据链执行：

1. 安装检查

```bash
./scripts/check/check-global-install.sh
```

2. Codex 路由回归

```bash
./scripts/smoke/host/codex-regression-suite.sh
```

3. Claude 全局链路回归

```bash
./scripts/smoke/host/claude-global.sh
```

4. readonly hook 回归

```bash
./scripts/smoke/hooks/readonly-hook.sh
```

这条链路当前覆盖：

- 全局托管块是否正确写入
- 共享 skills 是否同步到宿主可发现目录
- `Codex` 阶段路由与 supporting skills 是否正常
- `Claude` hooks、skills、browser 能力探测是否接通
- readonly hook 是否真的在运行态生效

## 工程测试入口

统一测试入口：

```bash
./scripts/test/test.sh
```

分层执行：

```bash
./scripts/test/test.sh --layer unit
./scripts/test/test.sh --layer integration
./scripts/test/test.sh --layer smoke
```

也可以直接运行子入口：

```bash
./scripts/test/python.sh
./scripts/test/shell-integration.sh
```

当前约定是：

- `unit`: Python hooks 与轻量静态逻辑回归
- `integration`: install / check / uninstall roundtrip、hook merge、安装状态恢复
- `smoke`: 真实 Claude / Codex / 浏览器环境验证
- `artifacts`: 运行产物输出目录，不承载自动化测试代码

详细说明见 [验证策略](docs/guides/workflows/validation-strategy.md)。

注意：

- GitHub CI 当前只运行 `unit + integration`，不验证真实 `Codex`、`Claude Code` 与浏览器登录态。
- 宿主级验证仍应通过本机 `scripts/smoke/*` 或未来的自托管 runner 执行。

## 脚本入口约定

当前仓库只认可这一套单一入口结构：

- [`scripts/install/`](scripts/install): 安装、卸载、同步、hook merge
- [`scripts/check/`](scripts/check): 全局安装检查、浏览器能力检查、Codex 运行态检查
- [`scripts/smoke/`](scripts/smoke): Claude / Codex / readonly hook 的真实环境回归
- [`scripts/test/`](scripts/test): 自动化测试统一入口
- [`scripts/lib/`](scripts/lib): shell 公共库
- [`scripts/hooks/`](scripts/hooks): 运行态 hook
- `artifacts/`: 运行产物目录

其中：

- source repo 负责安装输入、宿主适配源文件、文档与测试
- `~/.super-stack/runtime` 只负责宿主运行时直接引用的最小资产

不再保留根目录旧 shell 入口作为第二套官方方式。

## 文档导航

首页只保留“是什么、怎么装、怎么验”。更细的设计与规则统一看这些文档：

- [文档索引](docs/index.md)
- [项目架构设计](docs/architecture/project-design.md)
- [source / runtime 边界设计](docs/architecture/source-runtime-boundary.md)
- [脚本架构](docs/architecture/script-architecture.md)
- [验证策略](docs/guides/workflows/validation-strategy.md)
- [浏览器技术选型记录](docs/architecture/decisions/browser-technology-options.md)
- [只读命令 Hook 方案](docs/architecture/decisions/readonly-command-hook.md)
- [参考项目调研与吸收映射](docs/reference/research/reference-projects.md)
- [演进路线图](docs/overview/evolution-roadmap.md)
- [Codex 运行时检查](scripts/check/check-codex-runtime.sh)

## 验证参考

如果你想在真实项目里复用验证过程，可以直接使用这些 `docs/` 参考文档：

- [验证参考索引](docs/reference/validation/README.md)
- [真实项目验证模板](docs/reference/validation/real-project-validation.md)
- [技能回归矩阵](docs/reference/validation/skill-regression-matrix.md)
- [工作流体验验证](docs/reference/validation/workflow-experience-validation.md)
- [浏览器专项回归矩阵](docs/reference/validation/browser-regression-matrix.md)
- [Hook 风险分级回归矩阵](docs/reference/validation/hook-risk-regression-matrix.md)

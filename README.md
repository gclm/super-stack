# super-stack

面向 `Claude Code` 与 `Codex` 的共享全局 workflow runtime。

`super-stack` 的目标很明确：

- 用根 [AGENTS.md](/Users/gclm/Codes/ai/claude-stack-plugin/AGENTS.md) 提供稳定阶段路由
- 用 [`.agents/skills/`](/Users/gclm/Codes/ai/claude-stack-plugin/.agents/skills) 承载可复用技能
- 用 [`.planning/`](/Users/gclm/Codes/ai/claude-stack-plugin/.planning) 与模板沉淀项目状态
- 用 [`.claude/`](/Users/gclm/Codes/ai/claude-stack-plugin/.claude) / [`.codex/`](/Users/gclm/Codes/ai/claude-stack-plugin/.codex) 做宿主适配
- 用 [`scripts/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts) 提供安装、检查、回归与测试闭环

当前边界也很明确：

- 只维护全局配置底座
- 不再维护项目级安装分支
- 浏览器默认主链路是 `agent-browser` + `super-stack-browser`

## 快速开始

安装 `Claude` 与 `Codex`：

```bash
./scripts/install/install.sh --host all
```

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

如需单独重装浏览器链路：

```bash
./scripts/install/setup-browser.sh
./scripts/check/check-browser-capability.sh
```

稳定浏览器入口：

```bash
~/.claude-stack/bin/super-stack-browser open https://example.com
```

如果会话卡住或授权状态异常：

```bash
./scripts/install/reset-browser-session.sh
```

## 推荐验证链路

如果你想确认“不是装上了而是真的生效了”，建议按这条最小证据链执行：

1. 安装检查

```bash
./scripts/check/check-global-install.sh
```

2. Codex 路由回归

```bash
./scripts/smoke/codex-regression-suite.sh
```

3. Claude 全局链路回归

```bash
./scripts/smoke/claude-global.sh
```

4. readonly hook 回归

```bash
./scripts/smoke/readonly-hook.sh
```

这条链路当前覆盖：

- 全局托管块是否正确写入
- 共享 skills 是否同步到宿主可发现目录
- `Codex` 阶段路由与 supporting skills 是否正常
- `Claude` hooks、skills、browser 能力探测是否接通
- readonly hook 是否真的在运行态生效

如果你只想复查浏览器抽取链路，可以再跑：

```bash
./scripts/smoke/browser-extraction.sh --url "https://example.com/page" --adapter generic-page --output test/browser-smoke.md
```

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

- `unit`: Python hooks 与 browser renderer 的纯逻辑回归
- `integration`: install / check / uninstall roundtrip、hook merge、安装状态恢复
- `smoke`: 真实 Claude / Codex / 浏览器环境验证

详细说明见 [验证策略](/Users/gclm/Codes/ai/claude-stack-plugin/docs/validation-strategy.md)。

注意：

- GitHub CI 当前只运行 `unit + integration`，不验证真实 `Codex`、`Claude Code` 与浏览器登录态。
- 宿主级验证仍应通过本机 `scripts/smoke/*` 或未来的自托管 runner 执行。

## 脚本入口约定

当前仓库只认可这一套单一入口结构：

- [`scripts/install/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/install): 安装、卸载、同步、hook merge、浏览器安装与会话重置
- [`scripts/check/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/check): 全局安装检查、浏览器能力检查、Codex 运行态检查
- [`scripts/smoke/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/smoke): Claude / Codex / browser / readonly hook 的真实环境回归
- [`scripts/test/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/test): 自动化测试统一入口
- [`scripts/lib/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/lib): shell 公共库
- [`scripts/hooks/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/hooks): 运行态 hook
- [`scripts/browser/`](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/browser): 浏览器提取器与渲染器

不再保留根目录旧 shell 入口作为第二套官方方式。

## 文档导航

首页只保留“是什么、怎么装、怎么验”。更细的设计与规则统一看这些文档：

- [项目架构设计](/Users/gclm/Codes/ai/claude-stack-plugin/docs/project-design.md)
- [脚本架构](/Users/gclm/Codes/ai/claude-stack-plugin/docs/script-architecture.md)
- [验证策略](/Users/gclm/Codes/ai/claude-stack-plugin/docs/validation-strategy.md)
- [浏览器技术选型记录](/Users/gclm/Codes/ai/claude-stack-plugin/docs/browser-technology-options.md)
- [只读命令 Hook 方案](/Users/gclm/Codes/ai/claude-stack-plugin/docs/readonly-command-hook.md)
- [参考项目调研与吸收映射](/Users/gclm/Codes/ai/claude-stack-plugin/docs/reference-projects.md)
- [演进路线图](/Users/gclm/Codes/ai/claude-stack-plugin/docs/evolution-roadmap.md)
- [Codex 运行时检查](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/check/check-codex-runtime.sh)

## 验证模板

如果你想在真实项目里复用验证过程，可以直接使用：

- [真实项目验证模板](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/REAL_PROJECT_VALIDATION.md)
- [技能回归矩阵](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/SKILL_REGRESSION_MATRIX.md)
- [工作流体验验证](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/WORKFLOW_EXPERIENCE_VALIDATION.md)
- [浏览器专项回归矩阵](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/BROWSER_REGRESSION_MATRIX.md)
- [Hook 风险分级回归矩阵](/Users/gclm/Codes/ai/claude-stack-plugin/templates/validation/HOOK_RISK_REGRESSION_MATRIX.md)

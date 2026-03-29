# 浏览器技术选型记录

这份文档记录 `super-stack` 当前浏览器能力的正式口径，以及为什么不再继续维护 `agent-browser` 包装链。

## 1. 当前结论

当前正式保留的方案：

- 浏览器主链路：宿主侧 browser MCP 或 browser plugin
- Codex 当前优先：`chrome-devtools-mcp`
- Claude Code 当前优先：已配置的 browser MCP 或 browser plugin

当前明确退场的方案：

- `agent-browser`
- `super-stack-browser`
- 依赖这些 wrapper 的 repo-local browser smoke / extract / reset 脚本

## 2. 为什么改口径

这轮真实使用里，最重要的变化不是“换了个名字”，而是浏览器能力的归属发生了变化：

- 浏览器不再是 `super-stack` 自己安装和维护的一套 CLI wrapper
- 浏览器现在是宿主侧能力，`super-stack` 只负责 workflow、skills、检查和验证约束

继续保留 `agent-browser + super-stack-browser` 这条链会带来几个问题：

- 文档和真实能力不一致
- 安装链会继续偷偷维护一个已经不是主链路的 provider
- `browse` skill 会继续把 repo-local wrapper 当默认前提
- `chrome-devtools-mcp` 已经在真实宿主里可用，但仓库规则还在逼用户绕回旧链路

## 3. 当前正确做法

### 3.1 安装

`super-stack` 不再安装浏览器 wrapper。

安装动作只负责全局 router、skills、hooks 和 runtime：

```bash
./scripts/install/install.sh --host all
```

浏览器能力应由宿主自行配置。

### 3.2 检查

统一用：

```bash
./scripts/check/check-browser-capability.sh
```

当前更合理的预期输出是：

```text
ACTIVE_MCP
mcps=codex:chrome-devtools-mcp
```

如果没有检测到 MCP，但宿主侧已有 browser plugin，也会按 plugin 路径报告。

### 3.3 使用

在 `browse`、`qa`、URL 内容分析、前端验证这类任务里：

- Codex 优先使用 `chrome-devtools-mcp`
- Claude Code 优先使用配置好的 browser MCP 或 browser plugin
- 若浏览器能力不可用，必须显式说明，再退回截图、日志、静态抓取或代码推断

## 4. 现在删掉了什么

这次收口会删掉这些已经不应再作为正式链路存在的资产：

- `bin/super-stack-browser`
- `bin/super-stack-browser-health`
- `bin/super-stack-browser-reset`
- `scripts/check/check-browser-health.sh`
- `scripts/install/reset-browser-session.sh`
- `scripts/smoke/browser/*`
- 旧的 wrapper 安装测试和渲染测试

原因很直接：它们都默认建立在 `agent-browser` 仍然是主 provider 这个前提上。

## 5. 还保留什么

浏览器能力并没有被削弱，只是收口到了更正确的边界：

- `browse` skill 继续保留，而且更明确依赖真实 browser tooling
- `check-browser-capability.sh` 继续保留，但改成识别宿主 MCP / plugin，而不是 repo-local wrapper
- `protocols/workflow-governance.md`、`.codex/AGENTS.md`、`browse` references 继续强调 original-page browser evidence 优先

## 6. 后续优化方向

后续浏览器方向只继续做这几类事：

- 让 `browse` skill 更明确地区分 Codex / Claude 的 browser-tool path
- 继续加强 URL 内容分析时的 browser-first 路由
- 必要时补 host-specific browser verification playbook
- 让 browser evidence 更稳定落到 task artifact、QA 记录或 verify 结论里

后续不再做的事：

- 再把 `agent-browser` 包装链接回主线
- 再维护 repo-local 的浏览器 reset / health / open wrapper
- 再把浏览器能力伪装成 `super-stack` 安装出来的内建 CLI

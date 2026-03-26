# 只读命令自动放行 Hook 方案

这份方案来自一次真实工作流痛点：

- `git status`
- `git log`
- `ls -la`
- `pwd`
- `rg`

这类命令本身是只读的，但在日常 Claude Code / Codex 使用中，经常仍然会触发权限确认，导致交互噪音很重。

super-stack 当前将这类需求收敛为一套统一的 Hook 骨架，目标不是“让所有命令都更激进”，而是：

1. 只对白名单只读命令自动放行
2. 对不确定命令保持默认确认流
3. 不把复杂风险判断塞进根提示词

## 当前策略

当前版本采用分级保守策略：

- `allow`：白名单只读命令自动放行
- `ask`：含写入迹象或无法稳定判断的命令，回到宿主默认确认流
- `deny`：第一批高风险命令直接拒绝

这意味着它仍然是“以降噪为主、带少量硬拦截”的策略，而不是一个万能安全网关。

## 三层判定思路

### 1. 命令是否属于 shell / bash

只有 shell 命令才进入这条判断链。

- Claude：`PreToolUse` + `matcher = "Bash"`
- Codex：`pre_tool_use`

非 shell 工具直接透传，不处理。

### 2. 是否命中只读白名单

当前默认白名单包括：

- 文件和目录查看：`ls`、`cat`、`head`、`tail`、`find`、`stat`、`du`、`df`
- 搜索和过滤：`grep`、`rg`、`jq`、`yq`
- Git 只读命令：`git status`、`git log`、`git diff`、`git show`、`git branch`、`git fetch`
- 环境查看：`pwd`、`env`、`printenv`、`whoami`、`date`
- 常见包管理器只读命令：`npm list`、`npm info`、`pnpm list`、`brew info`、`pip list`

同时允许由这些只读命令组成的简单链路，例如：

```bash
git status | head -5
pwd && rg TODO README.md
```

### 3. 是否出现写入或高风险迹象

出现以下特征时，会进入 `ask` 或 `deny`：

- 输出重定向：`>`、`>>`、`1>`、`2>`、`&>`
- `tee`
- 明显写操作前缀：`rm`、`mv`、`cp`、`chmod`、`chown`
- 命令替换或子 shell：`` `...` ``、`$(...)`
- 解析失败或无法稳定判断

其中：

- 中风险写入命令进入 `ask`
- 高风险命令进入 `deny`

当前第一批直接拒绝的命令包括：

- `rm -rf`
- `git reset --hard`
- `git clean -fd` / `git clean -fdx`
- `truncate`
- `dd`
- `mkfs`

## 为什么不直接做“危险命令自动 deny”

因为当前 super-stack 的目标是先解决高频噪音，而不是一次性把完整风险治理做成巨石。

如果直接把所有“看起来危险”的命令改成硬拦截，会立刻带来两个问题：

1. 误伤正常操作
2. Claude / Codex 两侧兼容和验证成本显著上升

所以当前更稳的顺序是：

1. 先做只读自动放行
2. 保留默认确认流
3. 再逐步加风险分级和拦截策略

## 当前落地位置

共享判定脚本：

- [readonly_command_guard.py](../scripts/hooks/readonly_command_guard.py)

Claude 接线：

- [.claude/hooks/hooks.json](../.claude/hooks/hooks.json)
- 安装后会合并进 `~/.claude/settings.json`

Codex 接线：

- [merge-codex-hooks.sh](../scripts/install/merge-codex-hooks.sh)
- 安装后会合并进 `~/.codex/config.toml`

## 当前验证方式

基础回归脚本：

- [readonly-hook.sh](../scripts/smoke/readonly-hook.sh)

它当前验证：

- Claude 只读命令会返回 allow
- Codex 只读命令会返回 allow
- 带写入重定向的命令会回到 `ask`
- 高风险命令会命中 `deny`
- `.planning/.super-stack-readonly-hook.log` 会留下判定证据

专项矩阵模板：

- [HOOK_RISK_REGRESSION_MATRIX.md](../templates/validation/HOOK_RISK_REGRESSION_MATRIX.md)

## 下一步建议

下一阶段可以继续补三块：

1. 风险命令分级
   - `warn`
   - `ask`
   - `deny`
2. 与项目约定联动
   - 某些仓库禁止直接改 lockfile
   - 某些仓库要求 dev server 必须进 `tmux`
3. 浏览器 / 前端联动
   - 浏览器调试命令默认走只读自动放行
   - 但真正写文件、改代码仍保留确认

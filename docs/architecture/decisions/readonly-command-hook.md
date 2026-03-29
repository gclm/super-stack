# 只读命令自动放行 Hook 方案

这份方案来自一次真实工作流痛点：

- `git status`
- `git log`
- `ls -la`
- `pwd`
- `rg`

这类命令本身是只读的，但在日常 Claude Code / Codex 使用中，经常仍然会触发权限确认，导致交互噪音很重。

super-stack 当前将这类需求收敛为一套统一的 Hook 骨架，目标不是"让所有命令都更激进"，而是：

1. 只对白名单只读命令自动放行
2. 对其他所有命令（含写入、高风险、未知）统一回到宿主默认确认流，由用户自己决定
3. 不把复杂风险判断塞进根提示词

## 当前策略

当前版本采用两级策略：

- `allow`：白名单只读命令自动放行，跳过确认
- `ask`：其他一切命令回到宿主默认确认流，由用户决定是否执行

**不使用 `deny`。** Hook 的职责是降低只读命令的交互噪音，不是替用户拒绝命令。即使是 `rm -rf` 或 `git reset --hard` 这类高风险命令，正确做法也是让用户在确认流中看到命令后自己判断，而不是由 hook 硬拦截。硬拦截的唯一效果是增加绕路成本——用户最终还是会手动执行。

## 判定流程

### 1. 是否属于 shell 命令

只有 shell 命令才进入这条判断链。

- Claude：`PreToolUse` + `matcher = "Bash"`
- Codex：`pre_tool_use`

非 shell 工具直接透传，不处理。

### 2. 是否命中只读白名单

当前默认白名单包括：

- 文件和目录查看：`ls`、`cat`、`head`、`tail`、`find`、`stat`、`du`、`df`、`wc`、`nl`
- 搜索和过滤：`grep`、`rg`、`jq`、`yq`、`sort`、`uniq`、`diff`、`cmp`
- Git 只读命令：`git status`、`git log`、`git diff`、`git show`、`git branch`、`git fetch`、`git rev-parse`、`git blame`、`git tag`、`git remote`、`git reflog`
- 环境查看：`pwd`、`env`、`printenv`、`whoami`、`date`、`hostname`、`uname`
- 包管理器只读子命令：`npm list`、`npm info`、`pnpm list`、`brew info`、`pip list`
- 纯显示命令：`echo`、`printf`、`type`、`which`、`whereis`

同时允许由这些只读命令组成的简单链路，例如：

```bash
git status | head -5
pwd && rg TODO README.md
sed -n '1,100p' file.txt && printf '\n---\n' && sed -n '1,100p' other.txt
cat file.txt 2>/dev/null || echo NOT_FOUND
rg --files docs | sort
```

### 3. 所有其他命令 -> `ask`

只要命令不完全由白名单只读段组成，就进入 `ask`：

- 输出重定向到文件：`>`、`>>`、`&>`
- 写入类命令：`rm`、`mv`、`cp`、`chmod`、`chown`、`mkdir`、`touch`、`tee`
- Git 写入子命令：`git add`、`git commit`、`git merge`、`git rebase`、`git checkout`、`git cherry-pick`、`git reset`、`git clean`、`git restore`
- 高风险命令：`rm -rf`、`git reset --hard`、`git clean -fdx`、`dd`、`truncate`
- 命令替换或子 shell：`` `...` ``、`$(...)`
- 解析失败或无法稳定判断的命令

这些命令的风险等级不同，但 hook 不做拒绝——全部交由宿主确认流和用户判断。

## 重定向的处理规则

重定向是误判的主要来源，需要区分只读重定向和写入重定向：

- **stderr 丢弃**：`2>/dev/null` 是只读操作，不应触发 ask
- **stderr 追加到文件**：`2>>error.log` 是写入操作，应触发 ask
- **stdout 写入文件**：`>`、`>>` 是写入操作，应触发 ask
- **stdout + stderr 合并写入**：`&>` 是写入操作，应触发 ask

判定逻辑：当重定向目标是 `/dev/null` 时视为只读，否则视为写入。

## 白名单设计规则

白名单的边界不是"什么命令安全"，而是"什么命令在实际使用中反复触发确认但从未产生副作用"。具体规则：

1. **必须有日志证据支撑。** 新增白名单命令前，先检查 `harness/.runtime/super-stack-readonly-hook.log` 中该命令在 ask 中的出现频率。只在 ask 中反复出现且从未产生副作用的命令才考虑加入白名单。
2. **不加有副作用的命令，即使副作用看起来无害。** `open`（macOS 打开 GUI）不在白名单，因为它会启动进程。`curl` 不在白名单，因为它会触发网络请求。
3. **不加需要上下文才能判断安全性的命令。** `git branch -d` 不在白名单，因为 `branch` 子命令本身有只读模式（`git branch` 列出分支）和写入模式（`git branch -d` 删除分支）。对这类子命令，只放行确认只读的用法，不整个放行。
4. **`sed` 只放行 `-n` 模式。** `sed -n` 是只读提取，`sed -i` 是原地修改。只对前者放行。

## 已知误判模式（来自日志分析）

以下误判模式来自 303 条实际判定日志的分析：

| 模式 | 频率 | 根因 | 需要的代码修正 |
|---|---|---|---|
| `printf '\n---\n'` 作为段分隔符 | ~23 条 | `printf` 不在白名单 | 加入白名单 |
| `2>/dev/null` stderr 丢弃 | ~20 条 | 正则把 `2>` 当写入重定向 | 区分 `2>/dev/null` 与 `2>file` |
| `sort` 管道 | 多条 | `sort` 不在白名单 | 加入白名单 |
| `nl` 带行号显示 | ~3 条 | `nl` 不在白名单 | 加入白名单 |
| `for` 循环中的只读命令 | 多条 | shell 关键字无法识别 | 保持 ask（无法安全判定循环体） |
| `SHELL=var cmd` 变量赋值前缀 | 少量 | 赋值后接只读命令未被识别 | 已有 wrapper 逻辑，但 `SHELL` 变量名不在已处理的赋值列表中 |

## 为什么不使用 `deny`

三个原因：

1. **Hook 没有资格替用户做绝对拒绝的决定。** 用户明确要求删除一个目录时，hook 硬拦截只增加绕路成本，不增加安全性。
2. **误伤不可预测。** 当前 deny 列表是手动维护的静态集合，实际使用中必然存在"hook 认为危险但用户确实想做"的场景。
3. **宿主已有确认机制。** Codex 和 Claude Code 本身就有权限确认流，hook 不需要在这之上再加一层硬拦截。

## 当前落地位置

共享判定脚本：

- [readonly_command_guard.py](../../../scripts/hooks/readonly_command_guard.py)

Claude 接线：

- [manifest.json](../../../config/manifest.json) 中的 `claude_hooks` block
- [render_managed_config.py](../../../scripts/config/render_managed_config.py) 会将其渲染后合并进 `~/.claude/settings.json`

Codex 接线：

- [manifest.json](../../../config/manifest.json) 中的 `codex_hooks` block
- [render_managed_config.py](../../../scripts/config/render_managed_config.py) 会将其渲染后由 [install-codex.sh](../../../scripts/install/install-codex.sh) 合并进 `~/.codex/config.toml`

## 当前验证方式

基础回归脚本：

- [readonly-hook.sh](../../../scripts/smoke/hooks/readonly-hook.sh)

它验证：

- 只读命令返回 `allow`
- 非只读命令（含高风险命令）返回 `ask`
- `harness/.runtime/super-stack-readonly-hook.log` 会留下判定证据

专项矩阵模板：

- [hook-risk-regression-matrix.md](../../reference/validation/hook-risk-regression-matrix.md)

## 当前一致性状态

当前仓库中的实现、冒烟测试与回归矩阵已对齐到同一口径：

1. 判定策略为两级：`allow` / `ask`，不使用 `deny`。
2. `readonly_command_guard.py` 中白名单已覆盖 `printf`、`sort`、`nl`、`uniq`。
3. `open` 不在白名单，默认进入 `ask`。
4. `2>/dev/null` 被视为 stderr 丢弃，不作为写入重定向。
5. `git branch -d/-D` 被识别为写入行为，进入 `ask`。
6. `readonly-hook.sh` 与 `hook-risk-regression-matrix.md` 仅验证 `allow` / `ask`。

若后续出现新误判，应先记录到回归矩阵，再同步调整脚本与冒烟用例。

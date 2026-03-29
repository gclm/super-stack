# super-stack 脚本架构

这份文档只回答一个问题：

当前 `scripts/` 目录怎么分层，真正的官方入口有哪些，新增脚本应该放到哪里。

这次整理的目标很明确：

- 不再保留“根目录旧入口 + 子目录新入口”两套并行方式
- 让脚本目录和 README / CI / 测试 / `docs/ + harness/` 里的叙述保持一致
- 把安装、检查、smoke、测试和公共库彻底拆开
- 把运行产物目录单独命名，避免和测试目录混淆
- 把 `runtime` 定义为纯运行仓库，不再把安装职责隐含塞回 runtime

## 1. 当前目录分层

### 1.1 `scripts/install/`

安装与接线相关入口：

- [install.sh](../../scripts/install/install.sh)
- [uninstall-global.sh](../../scripts/install/uninstall-global.sh)
- [install-claude.sh](../../scripts/install/install-claude.sh)
- [install-codex.sh](../../scripts/install/install-codex.sh)

适合放：

- 会改写用户宿主目录的脚本
- 安装 / 卸载 / 同步 / hook merge 辅助脚本

额外约束：

- 安装脚本的输入真源是当前 source repo
- `~/.super-stack/runtime` 只是安装结果，不是安装输入

### 1.2 `scripts/check/`

安装结果与运行态检查：

- [check-global-install.sh](../../scripts/check/check-global-install.sh)
- [check-browser-capability.sh](../../scripts/check/check-browser-capability.sh)
- [check-codex-runtime.sh](../../scripts/check/check-codex-runtime.sh)
- [validate-skills.py](../../scripts/check/validate-skills.py)

适合放：

- 健康检查
- 环境探测
- 安装后状态校验
- 仓库内技能结构与引用约束的轻量静态校验

### 1.3 `scripts/smoke/`

真实环境回归入口：

- [claude-global.sh](../../scripts/smoke/host/claude-global.sh)
- [codex-global.sh](../../scripts/smoke/host/codex-global.sh)
- [codex-regression-suite.sh](../../scripts/smoke/host/codex-regression-suite.sh)
- [codex-scenarios.sh](../../scripts/smoke/host/codex-scenarios.sh)
- [readonly-hook.sh](../../scripts/smoke/hooks/readonly-hook.sh)

适合放：

- 依赖真实 Claude / Codex / 浏览器环境的回归脚本
- 需要验证“这条主链路在本机真的通了没有”的脚本

### 1.4 `scripts/test/`

自动化测试入口：

- [test.sh](../../scripts/test/test.sh)
- [python.sh](../../scripts/test/python.sh)
- [skills.sh](../../scripts/test/skills.sh)
- [shell-integration.sh](../../scripts/test/shell-integration.sh)

适合放：

- 可直接进入 CI 的分层测试入口
- 自动化 unit / integration 编排

### 1.5 `scripts/lib/`

公共函数库：

- [common.sh](../../scripts/lib/common.sh)
- [install-state.sh](../../scripts/lib/install-state.sh)

原则：

- `lib` 只放复用逻辑，不放用户直接执行入口
- 新脚本应优先复用这里，而不是复制 `ok/warn/check_*` 和路径拼装
- runtime 只同步 `scripts/lib/common.sh` 这一份 workflow 最小依赖；`install-state.sh` 仍留在 source repo

### 1.6 `scripts/hooks/`

运行态 hook：

- [readonly_command_guard.py](../../scripts/hooks/readonly_command_guard.py)

### 1.7 `artifacts/`

运行产物输出目录：

- 浏览器抽取报告
- smoke 过程中需要人工查看的样例结果

原则：

- `artifacts/` 只放运行产物，不放自动化测试代码
- 默认输出应优先落到 `artifacts/`
- 如果脚本需要用户传入 `--output`，README 和帮助信息也应优先示范 `artifacts/...`

## 2. 单一入口约定

当前仓库只认可下面这套入口风格：

- 安装类：`scripts/install/*`
- 检查类：`scripts/check/*`
- 冒烟类：`scripts/smoke/*`
- 测试类：`scripts/test/*`
- 运行产物目录：`artifacts/*`

不再保留根目录 shell 入口作为官方路径。

这样做的原因是：

- 避免 README、测试、CI、文档各自引用不同入口
- 避免“同一个动作到底执行哪个脚本”这类协作噪音
- 让目录本身就能表达职责边界
- 避免把运行产物再次误放进 `tests/` 或一个名字模糊的目录里
- 避免把 `runtime` 误当成“可以反向拿来重新安装一切”的 source repo 替身

## 3. 典型调用关系

### 3.1 安装链路

```text
scripts/install/install.sh
  -> install.sh 内直接 reset install state
  -> scripts/install/install-claude.sh / scripts/install/install-codex.sh
       -> scripts/lib/install-state.sh
       -> host-specific managed block merge within install-*.sh
```

### 3.2 测试链路

```text
scripts/test/test.sh
  -> scripts/test/python.sh
  -> scripts/test/shell-integration.sh
       -> tests/python/*
       -> tests/shell/*
```

### 3.3 浏览器验证链路

```text
browse skill / host browser tooling
  -> scripts/check/check-browser-capability.sh
  -> host-side browser MCP or browser plugin
```

## 4. 新脚本放置规则

- 如果脚本会改写用户环境或服务安装链路，放 `scripts/install/`
- 如果脚本只负责检查状态或运行态探测，放 `scripts/check/`
- 如果脚本依赖真实宿主 / 浏览器 / 登录态验证，放 `scripts/smoke/`
- 如果脚本是自动化测试入口，放 `scripts/test/`
- 如果脚本是共享函数库，放 `scripts/lib/`
- 如果脚本是运行态 hook，放 `scripts/hooks/`
- 如果文件是运行出来供人工查看的报告或样例，放 `artifacts/`

## 5. 当前结论

这次整理后，`scripts/` 已经从“平铺入口堆积”切换为“按职责分层的单一入口结构”。

补充 runtime 同步白名单：

- 同步到 runtime：`scripts/hooks/`、`scripts/workflow/`、`scripts/lib/common.sh`
- 不同步到 runtime：`scripts/install/`、`scripts/check/`、`scripts/smoke/`、`scripts/test/`、`scripts/release/`、`scripts/lib/install-state.sh`

后续如果再新增根目录 shell 脚本，应默认视为结构回退，除非有非常明确的兼容性理由。

# super-stack 验证策略

这份文档回答的是一个很具体的问题：

同样叫“测试”，到底哪类逻辑该放到 `unit`、`integration` 还是 `smoke`。

目标不是追求形式完整，而是减少下面这些常见混乱：

- 明明只是纯逻辑判断，却只能靠真实宿主冒烟
- 明明是文件改写问题，却要等到整条安装链路跑完才知道
- README、脚本和规划里都在说“验证”，但没人能快速判断应该跑哪一层

## 1. 当前三层验证模型

### 1.1 unit

适合：

- Python hook 里的纯逻辑
- 命令分类、JSON 解析、返回结构生成
- 状态文件读取、日志写入、副作用最小的函数路径

当前入口：

- [scripts/test/python.sh](../scripts/test/python.sh)

当前覆盖：

- [tests/python/test_readonly_command_guard.py](../tests/python/test_readonly_command_guard.py)
- [tests/python/test_super_stack_state.py](../tests/python/test_super_stack_state.py)

### 1.2 integration

适合：

- shell 脚本对临时 `HOME` / fixture 目录的文件改写
- install / check / uninstall 的往返行为
- hooks merge 是否幂等
- 安装状态记录与恢复边界

当前入口：

- [scripts/test/shell-integration.sh](../scripts/test/shell-integration.sh)

当前覆盖：

- [tests/shell/test_global_install_roundtrip.sh](../tests/shell/test_global_install_roundtrip.sh)
- [tests/shell/test_install_state_roundtrip.sh](../tests/shell/test_install_state_roundtrip.sh)
- [tests/shell/test_hook_merge_idempotent.sh](../tests/shell/test_hook_merge_idempotent.sh)

### 1.3 smoke

适合：

- 真实宿主存在且已接线后的行为确认
- 真实 CLI、真实浏览器、真实登录态相关链路
- “本机上这条主链路真的通了没有”的高层验证

说明：

- 这层默认不进入 GitHub 托管 CI。
- 原因不是它不重要，而是它依赖真实 `Codex`、`Claude Code`、浏览器会话与本机登录态。
- 因此它更适合在本机执行，或放到专门准备过宿主环境的自托管 runner。

当前代表入口：

- [scripts/smoke/readonly-hook.sh](../scripts/smoke/readonly-hook.sh)
- [scripts/smoke/codex-regression-suite.sh](../scripts/smoke/codex-regression-suite.sh)
- [scripts/smoke/claude-global.sh](../scripts/smoke/claude-global.sh)
- [scripts/smoke/browser-extraction.sh](../scripts/smoke/browser-extraction.sh)

## 2. 统一测试入口

统一入口见：

- [scripts/test/test.sh](../scripts/test/test.sh)

常用方式：

```bash
./scripts/test/test.sh
./scripts/test/test.sh --layer unit
./scripts/test/test.sh --layer integration
./scripts/test/test.sh --layer smoke
./scripts/test/test.sh --layer all
```

说明：

- 默认执行 `unit + integration`
- `smoke` 依赖真实宿主和本机环境，默认不自动跑
- `all` 会按 `unit -> integration -> smoke` 顺序执行

## 3. 脚本到测试层的映射

| 对象 | 优先测试层 | 原因 |
|------|------------|------|
| `scripts/hooks/readonly_command_guard.py` | unit | 纯逻辑判断多，宿主依赖弱 |
| `.codex/hooks/super_stack_state.py` | unit | 输入输出稳定，适合直接断言 JSON |
| `scripts/lib/install-state.sh` | integration | 关键在文件恢复行为，不是单行函数 |
| `scripts/install/merge-codex-hooks.sh` | integration | 关键在文件写入和幂等性 |
| `scripts/install/merge-claude-hooks.sh` | integration | 关键在 JSON merge 结果 |
| `scripts/check/check-global-install.sh` | integration | 依赖安装后文件布局 |
| `scripts/smoke/codex-regression-suite.sh` | smoke | 依赖真实 Codex 运行态 |
| `scripts/smoke/claude-global.sh` | smoke | 依赖真实 Claude 接线 |
| `scripts/smoke/browser-extraction.sh` | smoke | 依赖真实浏览器与页面状态 |

## 4. 当前边界

当前已经明确做到这几件事：

- Python hooks 已有可本地运行的单元测试
- 全局安装链路、hooks merge、安装状态恢复已进入 shell 集成测试
- 仓库已经有统一测试入口和分层说明
- 浏览器与 hook 已补充专项回归矩阵模板

专项矩阵模板：

- [BROWSER_REGRESSION_MATRIX.md](../templates/validation/BROWSER_REGRESSION_MATRIX.md)
- [HOOK_RISK_REGRESSION_MATRIX.md](../templates/validation/HOOK_RISK_REGRESSION_MATRIX.md)

还没有进入的内容：

- smoke 尚未进入 CI 自动执行
- 浏览器真实页面的自动化专项回归执行
- 更细粒度的 hooks 风险规则样本扩展

这些属于当前稳定演进阶段的后续增强项。

## 5. 关于 CI 的正确理解

当前 CI 的定位是“最小工程回归”，不是“完整宿主验证”。

它适合负责：

- Bash 语法检查
- Python unit test
- shell integration test

它不适合负责：

- 真实 `Codex` 二进制行为验证
- 真实 `Claude Code` skills / hooks 加载验证
- 真实浏览器登录态与页面回归

如果后续要把宿主级验证自动化，比较靠谱的方向只有两类：

1. 自托管 runner
   - 预装 `codex`、`claude`
   - 准备独立测试账号、浏览器登录态与隔离 HOME
2. 保持 GitHub CI 最小闭环
   - 宿主 smoke 继续在本机或专用验证机执行

默认推荐第二种，先把边界守住，不在 GitHub 托管 CI 上假装做不到的事。

# source repo / runtime repo 边界设计

当前采用的最终口径很简单：

1. 当前仓库是 `source repo`
2. `~/.super-stack/runtime` 是 `runtime repo`
3. `~/.super-stack/state` 存安装状态
4. `~/.super-stack/backup` 存备份

这样做的核心价值是把“运行副本”“恢复状态”“备份快照”拆开，但仍然全部收敛在 `~/.super-stack` 这一个根目录下，后期维护会清楚很多。

## 1. 目录边界

### 1.1 source repo

当前开发仓库负责：

- 源码、文档、测试、skills、协议文件
- `bin/` 中受管包装脚本
- 安装、检查、卸载脚本
- 作为 runtime repo 的唯一来源

### 1.2 runtime repo

`~/.super-stack/runtime` 负责：

- 运行所需的最小资产集合
- 宿主入口实际引用的 `AGENTS.md`、hooks、脚本
- 浏览器稳定入口 `~/.super-stack/runtime/bin/*`

这里要明确一点：

- `runtime` 是纯运行仓库
- 它不是重新安装用的完整 source repo 副本
- 安装、重装、结构调整都应从当前 source repo 发起

它不再同步明显只属于 source repo 的开发目录，例如：

- `.git`
- `.github`
- `.idea`
- `.planning`
- `docs`
- `tests`
- `.agents`
- `.claude`

### 1.3 state

`~/.super-stack/state` 负责：

- 安装前记录
- 恢复清单
- `install-manifest.tsv`

这样卸载 `runtime` 时不会误删恢复数据。

### 1.4 backup

`~/.super-stack/backup` 负责：

- hooks 合并前备份
- 卸载前备份
- 安装前恢复快照
- 其他需要保留的安装快照

## 2. 宿主接线原则

后续无论是：

- `~/.codex/AGENTS.md`
- `~/.codex/config.toml`
- `~/.claude/CLAUDE.md`
- `~/.claude/settings.json`

都只应该引用 `~/.super-stack/runtime` 下的运行资产，而不是直接引用 source repo，也不再各自维护一套 `super-stack` 副本。

这也意味着：

- 宿主运行时依赖 `runtime`
- 安装流程依赖 `source repo`
- 不再把 `runtime` 当成自举安装源

## 3. 包装脚本怎么维护

你的思路是对的，直接在 source repo 维护 `bin/` 最省心。

当前浏览器包装脚本：

- [super-stack-browser](/Users/gclm/Codes/ai/claude-stack-plugin/bin/super-stack-browser)
- [super-stack-browser-health](/Users/gclm/Codes/ai/claude-stack-plugin/bin/super-stack-browser-health)
- [super-stack-browser-reset](/Users/gclm/Codes/ai/claude-stack-plugin/bin/super-stack-browser-reset)

都应该作为源仓库里的实体脚本维护，安装时直接复制到：

- `~/.super-stack/runtime/bin/super-stack-browser`
- `~/.super-stack/runtime/bin/super-stack-browser-health`
- `~/.super-stack/runtime/bin/super-stack-browser-reset`

这比“脚本生成脚本”更稳定，也更容易排查问题。

## 4. 源仓库目录整理建议

当前源仓库继续保持这些主干目录即可：

- `docs/`
- `protocols/`
- `templates/`
- `.agents/`
- `.claude/`
- `.codex/`
- `bin/`
- `scripts/`
- `tests/`
- `.planning/`

职责建议继续收敛为：

- `bin/` 放稳定入口脚本
- `scripts/install/` 只做安装、同步、卸载
- `scripts/check/` 只做环境和接线检查
- `scripts/smoke/` 只做真实链路验证
- `scripts/test/` 只做测试入口和编排
- `tests/` 只放测试用例本体

## 5. 为什么会有 `tests` 和 `scripts/test`

这两个目录不是重复，而是分工不同：

- `scripts/test/` 回答“怎么跑测试”
- `tests/` 回答“具体测什么”

比如：

- [test.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/test/test.sh) 是统一测试入口
- [python.sh](/Users/gclm/Codes/ai/claude-stack-plugin/scripts/test/python.sh) 负责 Python 测试编排
- [tests/shell](/Users/gclm/Codes/ai/claude-stack-plugin/tests/shell) 放 shell 用例
- [tests/python](/Users/gclm/Codes/ai/claude-stack-plugin/tests/python) 放 Python 用例

所以保留两层是合理的，只要后续坚持：

- `scripts/test` 不放 case
- `tests` 不放 runner

维护成本就会比较低。

### 6.3 我对这部分的判断

这里不是必须合并。

我反而建议保留双目录，只做命名认知收敛：

- `scripts/test/` 继续当入口
- `tests/` 继续当用例

因为这样更利于：

- CI 调用统一入口
- 本地开发按层跑测试
- 测试代码不和脚本编排逻辑混在一起

### 6.4 运行产物目录也要单独命名

当前更容易混淆的其实不是 `scripts/test/` 和 `tests/`，而是浏览器 smoke 这类输出样例如果落到一个名字模糊的目录里，会让人误以为那也是测试用例目录。

所以这里继续明确约束：

- 保留 `scripts/test/`
- 保留 `tests/`
- 运行产物统一落到更直观的 `artifacts/`

## 7. 我对你这版模型的最终建议

我赞同你这次的收敛方向，而且我建议就定成下面这句项目约束：

- 当前仓库是唯一 source repo
- `~/.super-stack/runtime` 是唯一 runtime repo
- 宿主只接 runtime repo，状态与备份分别固定在 `~/.super-stack/state`、`~/.super-stack/backup`
- `scripts/test` 是测试入口
- `tests` 是测试用例
- `artifacts` 是运行产物输出目录

这版比我上一轮那种更细的抽象更适合你现在这个项目阶段。

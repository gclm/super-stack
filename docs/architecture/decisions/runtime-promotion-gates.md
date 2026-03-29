# runtime promotion gate 设计

这份文档只讨论一件事：

当 OpenSpace 或其他自动化在当前 source repo 中产生改动后，这些改动如何被推广到 `~/.super-stack/runtime`。

这里的前提已经固定：

- 当前 `super-stack` 仓库是 source repo / canonical git truth
- `~/.super-stack/runtime` 是受管运行副本
- OpenSpace 可以直接修改 source repo working tree
- runtime 不直接作为主要编辑面

所以这份文档真正定义的是：

- source repo 改动的分级
- source-side check / smoke / review 的触发条件
- runtime sync 前后的验证动作

## 1. 为什么需要独立 gate

如果允许 OpenSpace 直接改 source repo，但没有推广门禁，最终还是会出现两个问题：

- 改动虽然在 source repo 里可见，但一旦直接推广到 runtime，运行面仍然可能退化
- check 虽然能挡掉结构错误，但挡不住所有行为漂移

因此需要单独的 runtime promotion gate，把“能编辑 source repo”和“能进入 runtime”拆开。

## 2. 三个控制面

推荐把整条链路拆成三个控制面：

### 2.1 Source Edit

改动首先发生在 source repo working tree。

来源可以是：

- 人工编辑
- OpenSpace 自动改动
- `codex-record-retrospective` 生成后自动应用

### 2.2 Promotion

source repo 改动是否可以同步到 `~/.super-stack/runtime`，由 promotion gate 决定。

### 2.3 Activation

runtime 被同步后，是否真正成为宿主当前可运行版本，还要过 install/check/smoke。

## 3. 推荐流程

```text
source repo edit
  -> source-side check
  -> classify change
  -> optional smoke / review
  -> sync to runtime
  -> runtime install/check
  -> optional runtime smoke
```

核心原则：

- 先在 source repo 验证，再推广到 runtime
- runtime 不承担研发验证主职责
- 每一级 gate 都应尽量机械化

## 4. 改动分级

推荐按 3 级管理。

## 4.1 L1：低风险改动

典型范围：

- `docs/` 普通文档
- skill references
- 非执行逻辑的文案或说明调整
- examples / samples
- 纯注释或描述修正

主要风险：

- 文义错误
- 引用路径错误
- 导航失效

默认 gate：

- source-side check
- 可自动 sync 到 runtime
- runtime 只跑最小存在性检查，不强制人工 review

## 4.2 L2：中风险改动

典型范围：

- `.agents/skills/` 的行为文案调整
- skill templates
- generators
- 部分 smoke/reference 脚本
- 会影响 agent 行为但不直接改宿主安装面的变更

主要风险：

- skill 行为漂移
- 输出协议变化
- 生成物形状变化

默认 gate：

- source-side check
- targeted smoke
- 通过后才 sync 到 runtime
- runtime 侧再跑 install/check 与最小 smoke

## 4.3 L3：高风险改动

典型范围：

- `scripts/install/`
- `scripts/check/`
- 宿主路由
- hooks
- managed config
- runtime sync 机制本身
- protocol 级别边界变更
- 会影响安装、启用、全局行为的 skill / script / config 变更

主要风险：

- 宿主损坏
- runtime 失配
- 行为大范围回归
- 安装态半损坏

默认 gate：

- source-side check
- targeted smoke
- 人工 review
- 通过后才 sync 到 runtime
- runtime 侧必须跑 install/check 与对应 smoke

## 5. gate 矩阵

| 等级 | source-side check | source-side smoke | 人工 review | runtime sync | runtime install/check | runtime smoke |
| --- | --- | --- | --- | --- | --- | --- |
| L1 | 必需 | 默认不需要 | 默认不需要 | 允许 | 最小检查 | 默认不需要 |
| L2 | 必需 | 必需 | 视影响面 | 允许 | 必需 | 最小 smoke |
| L3 | 必需 | 必需 | 必需 | 通过后才允许 | 必需 | 必需 |

## 6. source-side check 应该覆盖什么

最低限度要覆盖：

- skill 结构校验
- 引用路径合法性
- 模板/脚本存在性
- managed config 语义正确性
- 基本语法错误

对当前仓库，已有或接近已有的能力包括：

- `python3 scripts/check/validate-skills.py`
- 各类脚本级检查
- managed config 校验

这里的原则是：

- 能机械验证的先机械验证
- 不要把显然能脚本化的检查留给人工 review

## 7. source-side smoke 应该怎么定义

targeted smoke 不追求“全量发布验证”，只追求“对本次影响面足够敏感”。

例如：

- skill 行为变更：跑 skill 结构与关键路径 smoke
- install/check 变更：跑 install/check roundtrip
- 浏览器相关：跑 browser extraction 或 health smoke
- host routing 变更：跑 host-level regression suite

原则：

- 只跑与改动面匹配的最小 smoke
- 不要求每次都跑全仓完整测试矩阵

## 8. runtime sync 的语义

runtime sync 不是“复制当前工作区的任何状态”，而是：

- 只推广通过 gate 的 source repo 结果
- runtime 仍然是最小运行集
- sync 失败或 runtime check 失败时，应回到 source repo 修复，而不是在 runtime 就地热修

这点非常关键。

如果 runtime 被允许就地热修，source repo 和 runtime 的边界会再次崩掉。

## 9. runtime 侧要验证什么

最低限度：

- 同步结果完整
- install / uninstall / check 逻辑正常
- 宿主配置未损坏
- skills / hooks / routers 被正确加载

必要时再跑：

- host smoke
- browser smoke
- targeted regression suite

## 10. check 为什么能提效

你前面提到“同步时 check 不就可以充分提供效率了吗”，这个判断核心是对的。

真正的效率来自：

- 自动修改 source repo
- 自动执行机械 check
- 只有在 check 通过后才进入更贵的 gate

也就是说，check 的价值是把大量低价值人工判断前置替换掉。

## 11. 为什么 check 还不够

但只靠 check 仍然不够，因为它通常挡不住：

- 技能语义退化
- 提示词过拟合
- 跨 skill 的行为耦合问题
- 安装成功但运行行为异常

所以推荐顺序一定还是：

- check
- 再按等级决定是否加 smoke
- 再按等级决定是否加人工 review

## 12. 谁来负责分级

phase-1 推荐不要过度自动化。

建议模型：

- 默认由生成改动的自动化先给出建议等级
- `architecture-guardrails` 或 review 侧规则可升级等级
- 一旦命中宿主安装、managed config、runtime sync、hooks、router 等路径，直接升为 L3

也就是说：

- 等级可以从低往高升级
- 不要自动从高往低降

## 13. 失败处理

如果 gate 失败：

- source-side check 失败：留在 source repo 修复，不 sync
- source-side smoke 失败：留在 source repo 修复，不 sync
- runtime install/check/smoke 失败：回到 source repo 修复，再重新 sync

不要把失败后的修复直接写在 runtime。

## 14. 与 OpenSpace 的关系

OpenSpace 在这条链路里的角色是：

- backend：提供 memory / lineage / discovery
- editor：在允许范围内直接修改 source repo
- not deployer：不直接跳过 gate 把改动发布到 runtime

也就是说，OpenSpace 可以是高效编辑器，但不是绕过门禁的发布器。

## 15. 最终建议

我的最终建议是：

- 允许 OpenSpace 直接修改当前 source repo working tree
- 绝不把 runtime 当成主要编辑面
- 用 L1 / L2 / L3 三档 gate 管理推广风险
- 用 `check` 承担效率主力，用 `smoke / review` 兜高风险语义问题
- runtime 失败时永远回 source repo 修复，不在 runtime 热修

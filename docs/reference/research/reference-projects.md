# super-stack 参考项目调研与吸收映射

这份文档不是泛泛而谈的“灵感来源列表”，而是基于本机真实调研痕迹整理出来的参考项目清单。

这次回顾确认到，之前确实在 `/tmp` 下建立过一个调研目录：

- `/tmp/stack-inspect`

当前还能确认的本地调研副本包括：

- `/tmp/stack-inspect/get-shit-done`
- `/tmp/stack-inspect/superpowers`
- `/tmp/stack-inspect/gstack`
- `/tmp/stack-inspect/ecc`

这些目录中的 `.git` `origin` 已经核对过，所以本文优先使用这些真实仓库地址，而不是后补猜测。

## 1. 调研对象总表

| 名称 | GitHub | 本地调研目录 | 我们主要参考什么 |
|------|--------|--------------|------------------|
| GSD / Get Shit Done | <https://github.com/gsd-build/get-shit-done> | `/tmp/stack-inspect/get-shit-done` | context engineering、spec-driven workflow、跨宿主适配 |
| Superpowers | <https://github.com/obra/superpowers> | `/tmp/stack-inspect/superpowers` | 自动阶段化 workflow、skills 体系、subagent-driven delivery |
| gstack | <https://github.com/garrytan/gstack> | `/tmp/stack-inspect/gstack` | slash-command 组织、browser/QA/release 角色化能力、真实产品交付导向 |
| ECC / Everything Claude Code | <https://github.com/affaan-m/everything-claude-code> | `/tmp/stack-inspect/ecc` | hooks、memory、instincts、commands、Claude/Codex 双适配经验 |
| bdarbaz/claude-stack-plugin | <https://github.com/bdarbaz/claude-stack-plugin> | 无本地副本，来自在线调研 | 共享核心 + 宿主适配层的组织思路 |
| gclm-flow / ~/.agents / ~/.claude | 本地私有，不是 GitHub 公共仓库 | `/Users/gclm/Codes/ai/gclm-flow`、`~/.agents`、`~/.claude` | 真实工作流噪音、个人偏好、历史生态兼容 |
| 小红书 readonly hook 笔记 | 短链：<http://xhslink.com/o/poi4ocstQb> | 无仓库 | `PreToolUse` 只读自动放行思路 |

## 2. 为什么这些项目会成为参考

这些参考项目覆盖的是不同层的问题，而不是同一种东西的重复实现。

### 2.1 GSD

GSD 主要代表：

- context engineering
- spec 驱动开发
- 面向多宿主的轻量工作流系统

它对我们的价值不在于某一条 skill，而在于：

- “一套工作流内核如何在多个 agent 宿主上保持可复用”

### 2.2 Superpowers

Superpowers 主要代表：

- 自动阶段化的软件开发 workflow
- skill 化、而不是巨型提示词化
- 子 agent 驱动执行

它对我们的价值在于：

- 把“需求 -> 设计 -> 计划 -> 执行 -> 验证”做成真正可操作的链路

### 2.3 gstack

gstack 更像一个“软件工厂操作系统”视角的方案。

它对我们的价值在于：

- 对 slash commands 的组织非常强
- browser、QA、review、ship 这些能力很接近真实交付场景
- 它更像“高强度产出型”工作流，而不是只关注提示词结构

### 2.4 ECC

ECC 是目前参考项目里最接近“大而全 Claude 工程系统”的一类。

它对我们的价值在于：

- hooks 非常重视
- memory / instincts / learning 体系较完整
- 有比较成熟的 Claude / Codex 兼容意识

### 2.5 bdarbaz/claude-stack-plugin

这个项目给我们的核心启发不是技能内容，而是结构：

- 共享核心
- 宿主插件 / 适配层
- 不把所有内容塞进单宿主目录

### 2.6 gclm-flow / ~/.agents / ~/.claude

这是最“接地气”的参考来源。

它的价值不是抽象方法论，而是：

- 你真实长期使用过
- 暴露过真实噪音
- 能告诉我们哪些设计是纸面上好看、实际会烦人的

### 2.7 小红书 readonly hook 笔记

它提供的是一个非常具体的微观优化启发：

- 高频只读命令不应该每次都确认

这个启发已经直接落地成了 super-stack 现在的 readonly hook 骨架。

## 3. 各参考项目的真实仓库地址与本地证据

这一节只写已经实际核对过的来源。

### 3.1 GSD / Get Shit Done

- GitHub:
  - <https://github.com/gsd-build/get-shit-done>
- 本地调研目录:
  - `/tmp/stack-inspect/get-shit-done`
- 已核对 remote:
  - `origin https://github.com/gsd-build/get-shit-done.git`

### 3.2 Superpowers

- GitHub:
  - <https://github.com/obra/superpowers>
- 本地调研目录:
  - `/tmp/stack-inspect/superpowers`
- 已核对 remote:
  - `origin https://github.com/obra/superpowers.git`

补充说明：

- 在调研过程中还发现它把 skills 独立成了单独仓库的思路
- Release Notes 中提到了：
  - `obra/superpowers-skills`
  - <https://github.com/obra/superpowers-skills>

这对我们“共享核心与技能分层”的思路也有启发。

### 3.3 gstack

- GitHub:
  - <https://github.com/garrytan/gstack>
- 本地调研目录:
  - `/tmp/stack-inspect/gstack`
- 已核对 remote:
  - `origin https://github.com/garrytan/gstack.git`

这次回顾后可以确认：

- 之前文档里把 `gstack` 地址写得不确定，是不对的
- 现在已经能明确它就是 `garrytan/gstack`

### 3.4 ECC / Everything Claude Code

- GitHub:
  - <https://github.com/affaan-m/everything-claude-code>
- 官方站点:
  - <https://ecc.tools/>
- 本地调研目录:
  - `/tmp/stack-inspect/ecc`
- 已核对 remote:
  - `origin https://github.com/affaan-m/everything-claude-code.git`

### 3.5 bdarbaz/claude-stack-plugin

- GitHub:
  - <https://github.com/bdarbaz/claude-stack-plugin>
- 本地调研目录:
  - 当前没有保留在 `/tmp/stack-inspect` 中
- 参考类型:
  - 在线结构调研

### 3.6 gclm-flow / ~/.agents / ~/.claude

这部分不是公共 GitHub 参考，而是本地长期演进资产：

- `/Users/gclm/Codes/ai/gclm-flow`
- `~/.agents`
- `~/.claude`

它们不应该被算成“外部参考项目”，但必须算作：

- 真实运行生态参考
- 历史兼容约束来源

### 3.7 小红书 readonly hook 笔记

- 短链:
  - <http://xhslink.com/o/poi4ocstQb>
- 当前验证到的落地页:
  - <https://www.xiaohongshu.com/discovery/item/69b5fbde000000001f0008c5>

这不是 GitHub 项目，但它影响了我们的 hooks 设计方向，所以需要保留。

## 4. 吸收映射表

这一节回答“各参考项目具体影响了 super-stack 的哪个部分”。

| 参考来源 | 已吸收内容 | 对应 super-stack 落点 |
|----------|------------|------------------------|
| GSD | 多宿主工作流思路、context engineering、spec 驱动意识 | `AGENTS.md`、技能分层、全局安装主线策略 |
| Superpowers | 阶段化 workflow、skills 体系、subagent-driven delivery | `discuss -> plan -> build -> review -> verify -> ship` 主链路 |
| gstack | 更真实的软件工厂视角、browser / qa / release 角色能力 | `browse`、`qa`、后续 release / browser 能力补齐方向 |
| ECC | hooks、memory、instinct-like 经验沉淀、Claude/Codex 兼容意识 | `SessionStart / Stop`、readonly hook、验证脚本、后续经验回写 |
| bdarbaz/claude-stack-plugin | 共享核心 + 宿主适配层 | `claude/`、`codex/` 只做宿主适配 |
| gclm-flow / ~/.agents / ~/.claude | 中文环境约定、技能主镜像路径、真实噪音识别 | `README.md` 默认约定、`~/.agents/skills`、运行时体检 |
| 小红书 readonly hook | `PreToolUse` 降噪思路 | `scripts/hooks/readonly_command_guard.py` 与安装接线 |

## 5. 我们明确没有照搬的部分

super-stack 不是“把所有参考项目拼在一起”，而是做了很多明确取舍。

### 5.1 没有照搬完整目录结构

原因：

- 各项目宿主假设不同
- 很多目录是它们自己的生态产物
- 我们需要兼容 Claude 与 Codex 两边

### 5.2 没有照搬全部 skills / commands / agents

原因：

- 功能多不等于可用
- 过多历史资产会增加噪音
- 我们目前优先的是“高价值、可验证、可维护”

### 5.3 没有做成 Claude-only 或 Codex-only

原因：

- 你的目标从一开始就是双宿主共用
- 这也是 super-stack 和大多数参考项目最核心的区别之一

### 5.4 没有把 hooks 一步做成重型风险引擎

原因：

- 当前优先先解决高频噪音
- 风险分级可以作为后续增强方向

## 6. 当前 super-stack 相比参考项目的优势

### 6.1 验证闭环更完整

当前 super-stack 的最大特点不是“技能最多”，而是：

- 安装后可检查
- 路由可 smoke test
- hooks 可专项回归
- 运行时有真实证据

### 6.2 双宿主统一更明确

当前已经形成：

- 共享核心
- Claude 薄适配
- Codex 薄适配

这不是大多数参考项目的默认设计目标。

### 6.3 更贴近中文工作环境

当前已经明确沉淀了：

- 文档默认中文
- 提交采用中文 Angular 摘要
- 技术项保留英文

### 6.4 范围边界更清楚

当前 super-stack 已明确区分：

- 验证样本 vs 产品开发
- 参考结构复用 vs 直接复用实现
- 全局底座 vs 项目级安装分支

## 7. 当前还不如参考项目成熟的地方

### 7.1 浏览器能力已接通，但还没完全工程化

当前浏览器能力已经不再只是“概念存在”：

- 宿主侧 browser MCP / browser plugin 已经可接入
- Codex 当前已配置 `chrome-devtools-mcp`
- `check-browser-capability.sh` 已开始识别宿主 MCP / plugin provider

但和更成熟的参考项目相比，我们仍然缺少：

- 更完整的 browser 专项回归
- 更统一的 provider 切换与策略说明
- 更成体系的浏览器故障证据模板

### 7.2 hooks 仍处于第一阶段

当前我们只有两类稳定 hooks：

- 状态恢复 hooks
- readonly auto-allow hooks

下一阶段还应继续补：

- 风险命令分级
- 文件写入保护
- secrets / lockfile / docs 保护

### 7.3 历史生态迁移还没完全结构化

虽然已经能与本地历史生态共存，但还没有形成：

- 旧 skills 清理策略
- 旧 agents 清理策略
- 旧 hooks 与新 hooks 的合并治理策略

## 8. 浏览器方向结论

浏览器相关的完整测试历史与技术取舍，已经单独收口到：

- [浏览器技术选型记录](../../architecture/decisions/browser-technology-options.md)

这里不再重复展开所有候选方案，只保留当前结论：

- 保留宿主侧 browser MCP / plugin 作为正式主链路
- 对 Codex 当前优先使用 `chrome-devtools-mcp`
- 后续浏览器优化只围绕这条主链路继续做

## 9. 当前结论

回顾 `/tmp/stack-inspect` 这批真实调研记录后，可以确认：

1. super-stack 的参考来源不是空泛的
2. `gstack` 的真实仓库地址就是 `garrytan/gstack`
3. GSD 的真实仓库地址是 `gsd-build/get-shit-done`
4. 这几个参考项目各自影响的是不同层，不应该混成一类

当前最合理的理解方式是：

- super-stack 并不是“还差多少功能没抄完”
- 而是“已经吸收了多类成熟思路，并且开始形成自己的跨宿主、可验证工作流内核”

## 10. 后续维护建议

以后如果继续增加参考项目，建议统一按这个模板补一节：

1. GitHub 地址
2. 本地调研目录
3. 主要参考点
4. 吸收映射
5. 不照搬原因

这样文档就能长期保持可复盘，而不是再次退回“靠聊天记录回忆”。

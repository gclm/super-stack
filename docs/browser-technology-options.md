# 浏览器技术选型记录

这份文档专门记录 `super-stack` 在浏览器能力上的技术调研、真实测试与最终取舍。

它回答 3 个问题：

1. 我们测过哪些方案
2. 各方案真实表现如何
3. 为什么最终只保留当前方案

注意：

- 这份文档用于保留调研与决策历史
- `README.md`、`project-design.md`、`evolution-roadmap.md` 只保留最终结论，不再重复展开所有候选方案

## 1. 结论先行

当前正式保留的方案只有一条：

- 浏览器主方案：`agent-browser`
- 日常稳定入口：`super-stack-browser`

当前不再作为默认保留方案的选项：

- `Browser Use CLI`
- `chrome-mcp`
- `playwright-mcp`

其中：

- `Browser Use CLI` 已从默认安装与接线中移除
- `chrome-mcp` 不再作为当前默认保留方案

## 2. 为什么要单独收口

这轮真实使用暴露出来的问题，不是“有没有浏览器能力”，而是“保留多个主链路以后，体验会明显变差”。

主要表现为：

- 重复授权
- 会话漂移
- 代理、profile、connect 模式混杂后排障复杂
- 文档和脚本容易写成“历史方案大全”，而不是“当前正确做法”

所以现在的策略是：

- 一条主链路做稳
- 其他方案只保留到这份调研文档里

## 3. 实测过的技术选项

### 3.1 agent-browser

定位：

- 本地 browser CLI / binary
- 适合直接被 Claude / Codex 调用
- 更接近 `gstack` 那种“本地浏览器命令 + 本地运行时”的路线
- 当前通过全局 `npm install -g agent-browser` 维护

真实表现：

- 安装简单
- CLI 很轻
- DOM / snapshot / 评论区 / 图片轮播提取效果都不错
- 配合 `--auto-connect` 可以复用本机已登录 Chrome 状态

实际验证过的场景：

- `example.com`
- `baidu.com`
- 小红书帖子正文提取
- 小红书评论区提取
- 小红书多图轮播提取

保留原因：

- 已经覆盖 super-stack 当前最核心的浏览器验证需求
- 本地体验最顺
- 最适合作为唯一主方案继续打磨

### 3.2 super-stack-browser

定位：

- 不是新的底层技术
- 而是 `agent-browser` 的稳定包装入口
- 这是当前唯一对外暴露的浏览器入口

等价于：

```bash
agent-browser --auto-connect --session-name super-stack-browser
```

设计目的：

- 固定连接路径
- 固定会话名
- 减少重复授权
- 降低“有时直连、有时新开”的行为漂移

当前建议：

- 日常命令统一从 `super-stack-browser` 进入
- 不要把它和原始 `agent-browser` 命令混着当主入口使用

### 3.3 Browser Use CLI

定位：

- 更重的本地 browser automation CLI
- 带有更明显的 daemon / orchestration 风格

真实表现：

- 一度成功复用了 Chrome profile
- 在部分小红书场景里，正文提取效果并不差
- 但整体更重，接线更复杂

实际遇到的问题：

- daemon 行为更复杂
- 之前碰到过代理环境继承问题
- 与 `agent-browser` 并存时，整体链路更容易复杂化
- 会放大重复授权与排障成本

最终取舍：

- 不再作为默认保留方案
- 从当前 super-stack 默认接线中移除

### 3.4 chrome-mcp

定位：

- 浏览器能力通过 MCP server 暴露

真实表现：

- 更像 server / integration 方向
- 不如本地 CLI 轻便
- 对当前默认主链路来说性价比不高

最终取舍：

- 不再作为当前默认保留方案
- 保留在这份文档中，仅作为历史评估记录

### 3.5 playwright-mcp

定位：

- Playwright 能力通过 MCP 方式接入

真实表现：

- 作为技术方向可以理解
- 但不适合作为 super-stack 的实际默认方案

最终取舍：

- 不保留到当前主线

## 4. 为什么最终只保留 agent-browser

原因不是“其他方案完全不能用”，而是从使用体验和长期维护看，继续保留多套默认主链路不划算。

最终只保留 `agent-browser` 的核心理由有 4 个：

### 4.1 它已经够用了

当前已经验证：

- 页面打开
- DOM / snapshot
- 标题 / 正文 / 评论提取
- 多图轮播提取
- 登录态复用

这些能力已经覆盖 super-stack 现阶段最重要的浏览器需求。

### 4.2 体验更简单

多保留一套主链路，意味着：

- 多一套命令
- 多一套连接模型
- 多一套授权路径
- 多一套文档解释成本

这和“做稳主线”的目标是冲突的。

### 4.3 更容易压掉重复授权

重复授权的核心不是单一 bug，而是：

- 浏览器自动化入口不稳定
- 会话不稳定
- 不同工具混用

现在通过：

- 只保留 `agent-browser`
- 默认统一走 `super-stack-browser`

可以显著降低这类噪音。

### 4.4 文档可以回归清晰

从现在开始：

- 这份文档负责保留历史方案
- 其他文档只讲当前正确做法

这会让整个仓库更容易维护。

## 5. 当前正确使用方式

### 5.1 安装

```bash
./scripts/install/setup-browser.sh
```

### 5.2 检查

```bash
./scripts/check/check-browser-capability.sh
```

预期主 provider：

```text
ACTIVE_LOCAL
provider=local-binary:super-stack-browser:...
```

### 5.3 日常使用

推荐统一用：

```bash
~/.claude-stack/bin/super-stack-browser open https://example.com
```

如果稳定会话卡住、重复授权明显增多、或浏览器状态漂移，可以先执行：

```bash
./scripts/install/reset-browser-session.sh
```

如果确实需要改 session name：

```bash
SUPER_STACK_BROWSER_SESSION=my-browser ~/.claude-stack/bin/super-stack-browser open https://example.com
```

## 6. 后续只需要继续优化什么

后续浏览器方向只继续做这几类事：

- 稳定 `super-stack-browser` 体验
- 减少重复授权
- 增加 `browse` 专项回归
- 增加真实页面结构化提取脚本

后续不再优先做的事：

- 再同时保留多套默认浏览器主方案
- 在 README 和主设计文档里继续展开所有候选技术

# ARCHITECTURE

- 核心形态是“共享核心 + 薄宿主适配 + 本地安装验证”：
  - 路由层由根 `AGENTS.md` 驱动。
  - 执行细节下沉到 `.agents/skills/`。
  - 宿主差异由 `.codex/` 与 `.claude/` 吸收。
  - `scripts/` 负责把这些内容同步到本机宿主目录，并通过 `install/`, `check/`, `smoke/`, `test/`, `lib/` 分层提供安装、检查、回归与测试入口。
  - `~/.super-stack/runtime` 被视为纯运行仓库，只承载宿主运行时直接引用的最小资产。
- 数据流不是业务数据流，而是配置资产流：
  - 仓库内容 -> `scripts/install/sync-to-*` 脚本 -> 用户目录中的宿主配置/skills/hooks -> `scripts/check/*` 与 `scripts/smoke/*` 回归验证。
- 浏览器能力是单独子链路：
  - `scripts/install/install.sh` 安装 `agent-browser` 并部署 `super-stack-browser` 稳定包装入口。
  - `scripts/smoke/browser/browser-extraction.sh` 基于 DOM 提取元数据、评论和图片，输出 Markdown 报告到 `artifacts/` 或显式指定路径。
- 风险守卫目前仍较轻：
  - `scripts/hooks/readonly_command_guard.py` 主要做只读命令自动放行。
  - 文档与路线图明确提到后续才进入风险分级与 deny/ask 策略。

# INTEGRATIONS

- Host integrations:
  - Codex: `~/.codex/AGENTS.md`、`config.toml`、`agents/*.toml`、hooks。
  - Claude: `~/.claude/CLAUDE.md`、`settings.json`、skills 镜像。
- Browser integration:
  - 通过全局 `agent-browser` 与 `~/.claude-stack/bin/super-stack-browser` 包装命令接入。
- Local tooling:
  - 依赖 `npm`, `python3`, `sqlite3`（运行时检查可选）, `rg` 等本地工具。
- No backend persistence:
  - 仓库本身不维护数据库或服务端集成，更多是对宿主本地配置与运行时文件的管理。

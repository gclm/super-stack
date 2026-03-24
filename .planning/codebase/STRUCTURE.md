# STRUCTURE

- `AGENTS.md`: 全局工作流路由器，定义阶段切换规则与 supporting skills 入口。
- `.agents/skills/`: 共享技能主体，按 `core/ planning/ quality/ ship/` 分类。
- `.codex/`, `.claude/`: 宿主适配层与 hooks 配置来源。
- `.github/workflows/`: 最小 CI 闭环，目前覆盖 Bash 语法检查、Python unit test、shell integration test。
- `scripts/install/`: 安装、卸载、同步、hook merge、浏览器安装与会话重置入口。
- `scripts/check/`: 全局安装检查、浏览器能力检查、Codex 运行态检查。
- `scripts/smoke/`: Claude/Codex/browser/readonly hook 的真实环境回归入口。
- `scripts/test/`: 统一测试入口，以及 Python unit / shell integration 分层入口。
- `scripts/lib/`: shell 公共函数、检查辅助、安装状态记录与恢复。
- `scripts/hooks/`: 运行态 hook 脚本。
- `scripts/browser/`: 浏览器抽取器与报告渲染器。
- `tests/python/`, `tests/shell/`: 自动化测试主体。
- `docs/`: 设计说明、选型记录、路线图、参考项目吸收记录。
- `templates/`: `.planning/` 与验证文档模板。
- `test/`: 浏览器抽取 smoke 的人工样例输出目录，不承载自动化测试代码。

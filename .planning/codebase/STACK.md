# STACK

- Languages: Bash 为主，Python 用于 hooks 与 JSON 处理，内嵌少量 JavaScript 供浏览器提取脚本执行。
- Runtime shape: 不是常规应用服务，而是本地 agent workflow runtime 与宿主适配工具集。
- Package/runtime dependencies:
  - `npm install -g agent-browser` 用于浏览器主链路。
  - `python3` 用于 hooks 合并、回归脚本中的 JSON 处理。
  - `codex` / `claude` 本地二进制是关键外部依赖。
- Test style: 已具备 `unittest + shell integration + smoke` 分层验证，并接入最小 CI 闭环；真实宿主行为仍主要依赖 smoke。
- Deployment clue: 主要目标是向 `~/.codex`、`~/.claude`、`~/.agents` 这些用户目录安装和同步资产，而不是部署到远程环境。

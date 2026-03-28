# TESTING

- Current test strategy:
  - `scripts/test/test.sh` 作为统一测试入口，默认执行 `unit + integration`，可按层选择 `smoke`。
  - `scripts/test/python.sh` 运行 Python unit test。
  - `scripts/test/shell-integration.sh` 运行基于临时 HOME 的 shell integration test。
  - `.github/workflows/ci.yml` 在 PR / push 上执行语法检查、unit、integration。
  - `scripts/check/check-global-install.sh` 做全局安装结果检查。
  - `scripts/smoke/host/codex-regression-suite.sh`、`scripts/smoke/host/codex-scenarios.sh`、`scripts/smoke/host/claude-global.sh` 做宿主行为回归。
  - `scripts/smoke/hooks/readonly-hook.sh` 验证只读 hook 行为。
  - `scripts/smoke/browser/browser-extraction.sh` 验证浏览器抽取链路，默认把报告写到 `artifacts/`。
- Main gaps:
  - CI 已覆盖语法检查、unit 与 integration，但 smoke 仍更依赖本机环境。
  - 浏览器 smoke test 当前针对特定站点结构，泛化证据不足。
  - hooks 风险分级、browser 适配层等高风险能力还未进入更细粒度回归。

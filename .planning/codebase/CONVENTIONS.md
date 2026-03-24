# CONVENTIONS

- 文档与用户可见说明默认中文。
- 面向用户的脚本提示、验证结果说明、回归结论与协作回复默认中文。
- 代码/命令/路径/协议名称保持英文。
- 脚本普遍使用 `set -euo pipefail`，有一定工程纪律。
- 安装和检查统一走 `scripts/install/`、`scripts/check/`、`scripts/smoke/`、`scripts/test/` 分层入口。
- 质量验证采用 `unit / integration / smoke` 三层模型，优先让可自动化的逻辑尽量前移到 unit 或 integration。

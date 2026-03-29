# 系统概览

## 核心模块
- source repo：
  - `AGENTS.md`
  - `skills/`
  - `protocols/`
  - `templates/generated-project/`
  - `scripts/install|check|smoke|test|workflow|hooks|lib`
- host adapters：
  - `codex/`
  - `claude/`
- runtime：
  - `~/.super-stack/runtime`（`AGENTS.md`、`claude/`、`codex/`、`protocols/`、`templates/generated-project/`、`.codex/hooks/`、`scripts/hooks/`、`scripts/workflow/`、`scripts/lib/common.sh`）
- host memory backend：
  - OpenSpace Layer-A

## 关键边界
- workflow 规则在 source repo 中维护。
- target project 通过生成器得到 `docs/ + harness/` 本地结构。
- source repo 通过 install/sync 链把运行必需资产复制到 runtime。
- runtime 只承载运行所需最小资产，不作为研发真源。

## 主要风险
- source repo 和 runtime 不能同时作为真源。
- 旧状态模型退场必须按 contract -> consumers -> cleanup 的顺序推进。
- OpenSpace 当前只做薄对接，不直接接管 runtime promotion。

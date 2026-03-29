# 项目概览

## 定位
- `super-stack` 是 `Claude Code` 与 `Codex` 的共享 workflow source repo。
- 当前仓库维护 root router、共享 skills、protocols、generated-project scaffold，以及 install/check/smoke/test 链路。
- `~/.super-stack/runtime` 是受管运行副本，不是研发真源。

## 目标
- 为双宿主提供一致的阶段路由、技能触发和工程约束。
- 保持 source repo first，让共享工作流变更先在 source repo 验证，再推广到 runtime。
- 为 target project 提供可初始化的 `docs/ + harness/` 结构，而不是继续依赖旧的仓库内 planning database。
- 在不引入重型平台的前提下，逐步补齐 `super-stack-native harness` 与 OpenSpace Layer-A 接线。

## 范围
- 当前包含：
  - 共享 workflow contract、skills、protocols 与 host adapters
  - `templates/generated-project/` 与相关生成脚本
  - source-side `install / check / smoke / test` 与 runtime promotion gate
  - OpenSpace 的本机 Layer-A 对接与上游 host skills 纳管
- 当前不包含：
  - 项目级安装分支或项目级覆盖安装链路
  - 直接把 runtime 当主要编辑对象
  - 默认启用重型云端调度、自动 merge 或无审批的 skill 演化

## 成功标准
- Claude 与 Codex 的全局路由、skills 与 hooks 由同一 source repo 稳定管理。
- source-side checks、关键单测、全局安装 roundtrip 与 host smoke 能持续提供 fresh evidence。
- target project 可以通过标准生成器拿到可用的 `docs/ + harness/` 结构。
- 旧状态模型退场最终完成，不留下长期双真源。

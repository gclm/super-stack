# ROADMAP

## 当前定位

- product scope: `super-stack` 只维护 `Claude Code` 与 `Codex` 的全局 workflow runtime，不再维护项目级安装分支。
- current architecture focus: 共享核心、薄宿主适配、本地可验证安装链路。
- current cleanup status: 结构收敛已经完成，当前重点从“清结构”切换为“稳运行、补回归、控复杂度”。

## 当前已定版结构

### 脚本单一入口

仓库当前只认可下面这套入口：

- `scripts/install/`: 安装、卸载、同步、hook merge、浏览器安装与会话重置
- `scripts/check/`: 全局安装检查、浏览器能力检查、Codex 运行态检查
- `scripts/smoke/`: Claude / Codex / browser / readonly hook 的真实环境回归
- `scripts/test/`: 自动化测试统一入口，以及 unit / integration 分层入口
- `scripts/lib/`: shell 公共函数、检查辅助、安装状态记录与恢复
- `scripts/hooks/`: 运行态 hook 逻辑
- `scripts/browser/`: 浏览器抽取适配器与渲染器
- `artifacts/`: 浏览器抽取报告等运行产物输出目录

不再保留根目录旧入口作为第二套官方方式。

### 当前验证结构

- unit:
  - `scripts/test/test.sh --layer unit`
  - 覆盖 Python hooks 与 browser renderer 的纯逻辑路径
- integration:
  - `scripts/test/test.sh --layer integration`
  - 覆盖 install / check / uninstall roundtrip、hook merge 幂等、安装状态恢复
- smoke:
  - `scripts/smoke/*`
  - 覆盖真实 Claude / Codex / 浏览器环境链路
- CI:
  - `.github/workflows/ci.yml`
  - 当前覆盖 Bash 语法检查、Python unit test、shell integration test
- 运行产物:
  - `artifacts/`
  - 用于承载 browser smoke 报告等人工查看结果，不承载自动化测试代码

### 当前文档结构

- `README.md`: 首页入口，只保留“是什么、怎么装、怎么验”
- `docs/project-design.md`: 产品边界与总体设计
- `docs/script-architecture.md`: 脚本分层与目录约定
- `docs/validation-strategy.md`: unit / integration / smoke 的职责边界
- `docs/browser-technology-options.md`: 浏览器链路与正确使用方式
- `docs/readonly-command-hook.md`: readonly hook 设计与边界

## 已完成收口摘要

- 删除项目级安装模式与相关文档叙事
- 收敛为仅保留全局安装主线
- 建立安装状态记录与恢复机制
- 完成 `scripts/` 分层重组并统一为单一入口
- 建立 `tests/python/` 与 `tests/shell/`
- 新增统一测试入口 `scripts/test/test.sh`
- 建立 `unit / integration / smoke` 分层验证策略
- 浏览器抽取调整为 `adapter + renderer` 结构
- readonly hook 升级到 `allow / ask / deny` 风险分级 v1
- 接入最小 CI 闭环
- README、docs、tests、CI 已统一切换到同一套目录口径

## 当前优化优先级

### P0：稳定当前结构，禁止回退

1. 继续保持单一脚本入口，不再新增根目录平铺 shell 脚本。
2. 新增脚本必须先判断应进入 `install/check/smoke/test/lib/hooks/browser` 哪一层。
3. 任何 README、文档、CI、测试更新都必须同步使用新路径，避免再次出现“文档一套、仓库一套”。
4. 浏览器 smoke、样例报告和人工检查结果统一落到 `artifacts/`，不要再引入新的输出目录名。

### P1：补强真实环境验证

1. 完善 `scripts/smoke/claude-global.sh`
   - 目标：让 Claude 侧 browser active check、skills 加载、hooks 触发证据更完整。
2. 完善 `scripts/smoke/codex-regression-suite.sh`
   - 目标：补更多阶段/skill 路由回归样例，减少路由漂移。
3. 完善 `scripts/smoke/browser-extraction.sh`
   - 目标：继续降低对小红书页面结构的耦合，增强 generic-page 验证证据。

### P2：让测试体系更稳

1. 增加对 shell 公共库的更细粒度回归
   - 重点：`scripts/lib/install-state.sh`、`scripts/lib/checks.sh`
2. 增加对 browser renderers / extractors 的更明确自动化断言
   - 目标：让 browser 相关变更更早在 unit 或 integration 层暴露
3. 评估 smoke 的半自动执行策略
   - 目标：把当前完全人工执行的部分逐步模板化

### P3：控制文档与结构复杂度

1. 避免 roadmap 再次退化成“历史 diff 列表”
   - 原则：`ROADMAP` 只保留当前结构、当前优先级、后续路线。
2. 历史整改细节如仍需保留，优先放入专门的演进文档，而不是继续堆在路线图首页。
3. 保持 `.planning/codebase/*` 与真实仓库结构同步，避免再次出现结构说明过期。

## 下一阶段建议

如果按“投入最小、收益最大”的顺序继续推进，我建议是：

1. 先补 `browser-extraction` 的 generic 场景验证与文档样例
2. 再补 Claude / Codex smoke 的更多证据型回归
3. 最后再看是否需要引入更细粒度的 browser 自动化测试

## 当前判定

- roadmap status: 当前结构已收敛，可以进入“稳定演进”阶段
- main risk: 不是缺大功能，而是后续新增内容把脚本层次、文档口径和测试边界重新搞乱
- execution rule: 之后的改动优先保持结构一致性，其次再扩能力

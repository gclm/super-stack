# STATE

- status: stable_maintenance
- current focus: 保持单一脚本入口结构稳定，继续补强浏览器与真实环境回归证据
- active phase: Maintenance - 稳定演进
- planning mode: staged hybrid

- current baseline:
  - `super-stack` 已明确只维护全局 workflow runtime，不再维护项目级安装分支。
  - 脚本入口已统一到 `scripts/install/`、`scripts/check/`、`scripts/smoke/`、`scripts/test/`、`scripts/lib/`。
  - README、docs、CI、tests、`.planning/codebase/*` 已切换到同一套目录口径。
  - 最小自动化闭环已存在：Bash 语法检查、Python unit test、shell integration test。

- current risks:
  - browser 抽取链路仍有站点耦合，`generic-page` 证据还不够强。
  - smoke 仍依赖真实 Claude / Codex / 浏览器环境，自动化程度有限。
  - 后续新增脚本或文档时，如果不遵守分层规则，结构很容易再次回退成多入口状态。

- last scope change:
  - 本轮继续强化 workflow 触发层，把 `bug -> debug`、`可测试行为变更 -> tdd-execution`、`审查类请求 -> review`、`完成度证明 -> verify`、`用户流验证 -> qa` 从偏建议型规则提升为更强的默认路由与 `build` 回退规则。

- last architecture change:
  - 本轮继续对 `AGENTS.md`、`build`、`discuss`、`plan` 做瘦身，把共性细则下沉到 `protocols/workflow-governance.md` 和各自 reference，保持主文件更偏入口与路由；同时补齐质量链路的路由边界，明确 `review / verify / qa` 的分工，并补充“多 agent 已配置不等于应自动触发”的宿主约束说明、Codex 侧自动升级启发式，以及一份独立的多 agent 场景示例 reference。
  - 本轮进一步收敛 `AGENTS.md` 与 `.codex/AGENTS.md` 的职责：根文件保留共享真源，Codex adapter 只保留宿主特有执行细节。
  - 本轮新增 `codex-record-retrospective` 技能，用于按项目路径复盘 Codex 本地记录，并把通用经验反哺到 super-stack。

- verification status:
  - 已完成本轮文本级自检：根路由、`build` 与 `debug / tdd-execution / review / verify / qa` 的边界无明显冲突。
  - 当前口径已明确：`review` 负责找风险，`verify` 负责证明结果，`qa` 负责验证真实用户流与运行态信心。
  - 质量技能入口文案已补齐“适用 / 不适用 / 下一步路由”，当前边界与根路由保持一致，暂未发现明显冲突。
  - Codex adapter 已增加独立 multi-agent 场景 reference，当前主文件不再需要继续堆示例说明。
  - `.planning/` 已从忽略规则中移除，后续 roadmap、state 与 codebase map 可以作为仓库资产纳入版本管理。
  - `.planning/` 下的 hook 日志已改为单独忽略，避免共享状态文件重新被临时产物污染。
  - `codex-record-retrospective` 已补充“当前 live session 可能尚未入库”“不能只靠宽泛历史汇总”“证据不足时不能半截停住”的约束，并新增仓库托管的项目路径扫描脚本替代旧的本地历史脚本。
  - `codex-record-retrospective` 已新增 session 时间线提炼脚本，减少手工二次阅读 JSONL 原始记录的成本。
  - `map-codebase` 已补充“基础层 -> 设计层 -> 目标层”的陌生项目分层进入策略，避免不是目标驱动的全仓库深挖。
  - 本轮已把两次复盘结论正式写回 `build / verify / api-change-check / security-review / ship`：新增 incidental issue 分类、验证证据四级口径、API/鉴权/租户/上传下载边界检查，以及最终交付必须显式说明“已完成 / 已验证 / 当前约束 / 未纳入”。

- temporary unblock decisions:
  - 当前无新的临时 unblock 决策；后续若为通过构建或验证引入占位资源，必须在此显式记录其性质。

- next actions:
  - 后续结合真实项目继续观察 `review / verify / qa` 的命中率，必要时再补触发示例或更细的边界说明。
  - 在后续真实项目中继续观察 multi-agent 的实际命中率，确认问题主要来自宿主策略、显式授权要求，还是我们自己的升级阈值仍然过高。
  - 用真实项目路径验证 `codex-record-retrospective` 是否能稳定定位到相关 session，并正确区分项目噪音与 workflow 问题。
  - 用下一个真实 API / 鉴权 / 多租户项目任务，检验新增边界矩阵和证据分级是否能减少中途改方案与“验证过度乐观”的情况。
  - 继续补 `scripts/smoke/browser-extraction.sh` 的通用场景验证与样例。
  - 继续增强 `scripts/smoke/claude-global.sh` 与 `scripts/smoke/codex-regression-suite.sh` 的证据型回归。
  - 维持 `.planning/codebase/*`、README 与实际目录结构同步，不再让说明文件滞后。

- decision:
  - 结构收敛已经完成，当前不再继续扩张新的结构层次。
  - 后续所有改动优先保持结构一致性、验证闭环和单一入口约定，其次才扩新能力。
  - 以后出现中途调整产品边界、架构方向或数据库策略时，必须先显式回退到 `plan`，再继续 `build`。

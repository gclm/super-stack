# STATE

- status: stable_maintenance
- current focus: 保持单一脚本入口结构稳定，并继续把 source repo 定位与方案文档分层规则收敛成不易误触发的共享 workflow
- active phase: Maintenance - 稳定演进
- planning mode: staged hybrid

- current baseline:
  - `super-stack` 已明确只维护全局 workflow runtime，不再维护项目级安装分支。
  - 旧仓库 `gclm-flow` 当前定位为历史参考与素材来源，不再作为继续发布的主仓库；后续公开发布与结构收敛统一以 `super-stack` 为准。
  - 脚本入口已统一到 `scripts/install/`、`scripts/check/`、`scripts/smoke/`、`scripts/test/`、`scripts/lib/`。
  - README、docs、CI、tests、`.planning/codebase/*` 已切换到同一套目录口径。
  - 当前目录结构已明确收敛为：`~/.super-stack/runtime` 运行仓库、`~/.super-stack/state` 安装状态、`~/.super-stack/backup` 备份目录、`artifacts/` 运行产物目录。
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
  - 本轮进一步增强 `codex-record-retrospective` 路径扫描脚本，支持 `--project-path-alias`，可把项目迁移前后的历史路径一起纳入同一次证据扫描，降低仓库搬家后旧 session 被漏掉的概率。
  - 本轮为 `codex-record-retrospective` 新增一份仓库托管案例 reference，沉淀 `insky-device-sdk` 在真实使用中暴露出的 skill 调整信号，用于后续继续校准 retrospective / map-codebase / verify / 多 agent 升级阈值的边界。
  - 本轮收紧 `map-codebase` 的多模块策略：若基线扫描已显示仓库为多模块且用户目标模块仍不明确，则先用一句短问题确认范围，再继续深挖，避免为了求稳而默认做全仓级 deep read。
  - 本轮继续收紧 `verify` 的结果口径：对复杂项目与完成度判断类请求，要求显式区分“已实现 / 已验证 / 未验证 / 缺口”，避免把实现进度、测试结果和真实运行态信心混成一个过度乐观的完成结论。
  - 本轮将路径设计最终收敛为三段式：当前仓库是 `source repo`，`~/.super-stack/runtime` 是 `runtime repo`，`~/.super-stack/state` 存安装状态，`~/.super-stack/backup` 存备份；Claude / Codex 宿主入口已统一指向 `~/.super-stack/runtime`，浏览器稳定入口也统一到 `~/.super-stack/runtime/bin`。
  - 安装状态已扁平化到 `~/.super-stack/state/install-manifest.tsv`，恢复快照统一迁到 `~/.super-stack/backup/install-state`，避免在 `state` 目录下重复维护一套备份语义。
  - runtime 已进一步定义为纯运行仓库：安装和重装必须从 source repo 发起，runtime 不再承担完整安装源材料角色。
  - 本轮把 super-stack 自身维护的 source repo 定位规则显式写回 `AGENTS.md` 与 `protocols/workflow-governance.md`，统一要求优先读取 `~/.super-stack/state/source-repo-path.txt`，避免把 runtime 或宿主安装副本误当成 source-of-truth。
  - 本轮为 `discuss` 与 `build` 补齐方案类文档的深度识别与分层写作能力：`discuss` 负责识别 `brief / standard / deep`，`build` 负责通过独立 reference 控制金字塔结构、主文档与附录边界，以及混层漂移修复。
  - 本轮继续对上述新增规则做文案收紧，把“默认结构”与“建议分层”的表述从过硬约束收敛为默认起点和优先动作，降低未来真实项目中的机械套用风险。

- verification status:
  - 已完成本轮文本级自检：根路由、`build` 与 `debug / tdd-execution / review / verify / qa` 的边界无明显冲突。
  - 当前口径已明确：`review` 负责找风险，`verify` 负责证明结果，`qa` 负责验证真实用户流与运行态信心。
  - 质量技能入口文案已补齐“适用 / 不适用 / 下一步路由”，当前边界与根路由保持一致，暂未发现明显冲突。
  - Codex adapter 已增加独立 multi-agent 场景 reference，当前主文件不再需要继续堆示例说明。
  - `.planning/` 已从忽略规则中移除，后续 roadmap、state 与 codebase map 可以作为仓库资产纳入版本管理。
  - `.planning/` 下的 hook 日志已改为单独忽略，避免共享状态文件重新被临时产物污染。
  - `codex-record-retrospective` 已补充“当前 live session 可能尚未入库”“不能只靠宽泛历史汇总”“证据不足时不能半截停住”的约束，并新增仓库托管的项目路径扫描脚本替代旧的本地历史脚本。
  - `codex-record-retrospective` 的项目路径扫描脚本已支持显式历史路径别名，并已用 `insky-device-sdk` 的新旧路径完成一次 fresh verification，确认迁移前旧路径 session 能与当前路径命中合并出现在同一份报告中。
  - 已完成 `insky-device-sdk` 新路径阶段的使用记录复盘：确认该项目在真实任务中高频收敛到 `insky-cloud` 子模块，且暴露出 `map-codebase` 容易在已知模块场景下过度铺开、`verify` 需要继续强化“已实现 vs 已验证”分层表达、多 agent 升级阈值仍需更明确等 skill 调整信号。
  - `map-codebase` 与 `workflow-governance` 已补充 fresh rule：检测到多模块仓库时，不再默认按全仓深读继续推进，而是优先确认用户要先看哪个模块；已将这一策略作为后续 skill 调整的当前口径。
  - `verify` protocol 与 verify skill 已补充 fresh rule：复杂任务的验证总结必须使用“已实现 / 已验证 / 未验证 / 缺口”四段式表达，并继续保留四级证据强度，当前已将其作为后续完成度判断类回答的默认口径。
  - `codex-record-retrospective` 已新增 session 时间线提炼脚本，减少手工二次阅读 JSONL 原始记录的成本。
  - `map-codebase` 已补充“基础层 -> 设计层 -> 目标层”的陌生项目分层进入策略，避免不是目标驱动的全仓库深挖。
  - 本轮已把两次复盘结论正式写回 `build / verify / api-change-check / security-review / ship`：新增 incidental issue 分类、验证证据四级口径、API/鉴权/租户/上传下载边界检查，以及最终交付必须显式说明“已完成 / 已验证 / 当前约束 / 未纳入”。
  - 本轮已完成全仓路径与口径审计，技能、宿主配置、安装脚本、检查脚本、测试与文档当前均已适配 `runtime/state/backup` 与 `artifacts/` 结构。
  - 本轮已完成 fresh verification：`bash -n` 覆盖主要 shell 入口，`bash scripts/test/test.sh` 全量通过，且全仓未再检出 `.claude-stack`、`.super-stack/bin`、`.super-stack/scripts`、`.super-stack-state` 等旧路径残留。
  - runtime 复制策略已从整库复制收敛为最小运行集，不再同步 `.git`、`.github`、`.idea`、`.planning`、`docs`、`tests`、`.agents`、`.claude` 等只属于 source repo 的目录。
  - 发布前文档链接已完成一次仓库相对路径收口，README 与 `docs/` 内不再残留旧的本地 source repo 绝对路径。
  - 已完成本轮文本级接线：`AGENTS.md` 与 `workflow-governance.md` 已补 source repo 定位顺序，`discuss` 已补方案文档深度识别，`build` 已补方案文档分层入口，并新增 `pyramid-doc-writing.md` 作为专用 reference。
  - 已完成一轮文案收紧：当前口径更强调“默认起点、优先动作、必要时显式化”，弱化了可能导致误触发的硬模板语气，`discuss / build / reference` 的职责边界仍保持清晰。

- temporary unblock decisions:
  - 当前无新的临时 unblock 决策；后续若为通过构建或验证引入占位资源，必须在此显式记录其性质。

- next actions:
  - 为 GitHub 发布补齐远端仓库、推送主分支，并继续保持当前仓库作为唯一公开源。
  - 继续观察宿主入口、skills 镜像和 hooks 在真实环境中的稳定性，确认不再回退到宿主各自复制副本的旧路径。
  - 如后续需要进一步精简，可评估是否把 `sync-to-claude.sh` / `sync-to-codex.sh` 再往更薄的接线脚本方向收缩。
  - 继续维持安装、检查、卸载脚本围绕“source repo -> ~/.super-stack/runtime”工作，并保持状态/备份固定在同一根目录下。
  - 保持 `scripts/test/` 作为测试入口、`tests/` 作为测试用例目录，并把运行产物统一收敛到 `artifacts/`，避免第三套“像测试又不是测试”的目录口径。
  - 后续结合真实项目继续观察 `review / verify / qa` 的命中率，必要时再补触发示例或更细的边界说明。
  - 在后续真实项目中继续观察 multi-agent 的实际命中率，确认问题主要来自宿主策略、显式授权要求，还是我们自己的升级阈值仍然过高。
  - 用真实项目路径验证 `codex-record-retrospective` 是否能稳定定位到相关 session，并正确区分项目噪音与 workflow 问题。
  - 用下一个真实 API / 鉴权 / 多租户项目任务，检验新增边界矩阵和证据分级是否能减少中途改方案与“验证过度乐观”的情况。
  - 继续补 `scripts/smoke/browser-extraction.sh` 的通用场景验证与样例。
  - 继续增强 `scripts/smoke/claude-global.sh` 与 `scripts/smoke/codex-regression-suite.sh` 的证据型回归。
  - 维持 `.planning/codebase/*`、README 与实际目录结构同步，不再让说明文件滞后。
  - 在后续真实方案文档任务中观察 `brief / standard / deep` 与主文档/附录分层规则是否足够稳定，必要时再补更细的 examples，而不是继续把细则堆回主 skill。

- decision:
  - 结构收敛已经完成，当前不再继续扩张新的结构层次。
  - 后续所有改动优先保持结构一致性、验证闭环和单一入口约定，其次才扩新能力。
  - 后续路径与安装治理统一采用 `source repo -> runtime repo(~/.super-stack/runtime)`，并固定 `state` / `backup` 子目录边界。
  - 以后出现中途调整产品边界、架构方向或数据库策略时，必须先显式回退到 `plan`，再继续 `build`。

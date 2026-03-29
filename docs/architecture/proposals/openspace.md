# OpenSpace 方案设计

这份文档只讨论 OpenSpace 在 `super-stack` 中的角色，不讨论 target project 的 `docs/ + harness/` 细节。

这里先把边界说清楚：

- 当前仓库 `super-stack` 是 source repo / 原厂库 / canonical git truth
- `~/.super-stack/runtime` 是运行副本，不是研发真源
- OpenSpace 可以成为 skills 进化 backend，也可以成为 source repo 的受控修改执行者
- 但 runtime 只应该通过受管 sync / promotion gate 接收变更

## 1. 先回答核心分歧

之前最容易说错的一句话是：

- “OpenSpace 不能直接改当前项目”

在当前语境下，这句话不对。

更准确的说法应该是：

- OpenSpace 可以直接改当前 source repo working tree
- OpenSpace 不应直接把 `~/.super-stack/runtime` 当成主要编辑面

所以，我们要限制的不是“source repo draft edit authority”，而是“runtime direct edit”。

## 2. OpenSpace 到底解决什么

如果你的目标是“让 AI 越来越好用、技能依赖越来越完善”，单靠 repo 内文档是不够的。

你还需要一层宿主级能力：

- 记录跨项目的长期经验
- 追踪 skill / lesson 的 lineage
- 在需要时搜索本地或云端的已有技能与模式
- 把多次任务中重复出现的失败信号沉淀下来
- 为 skill 演进提供一个统一 backend

这正是 OpenSpace 更擅长的部分。

## 3. 为什么 OpenSpace 比 `~/.super-stack/projects/<slug>/` 更合适

自建目录方案的优点是可控，但它会把下面这些都变成我们自己的长期维护成本：

- memory schema
- ingestion pipeline
- lineage model
- import / export
- local / cloud search
- dashboard
- community sync

如果只是先做一个轻量 PoC，自建目录还说得过去。

但如果你的目标是长期演进，让 agent 在多项目、多任务、多次复盘后逐渐变强，那 OpenSpace 作为 backend 更合理，因为它天然就是为这类能力准备的基础设施。

## 4. 新的权限模型

我建议用三个权限来描述 OpenSpace，而不是简单说“能改”或“不能改”。

### 4.1 Draft Edit Authority

OpenSpace 可以在允许的路径范围内直接修改 source repo working tree，例如：

- `skills/` 下的低中风险改动
- `docs/` 中的设计说明与 references
- `templates/` 中的非高风险模板调整
- 少量配套脚本

这一步的目标是提升演进效率，而不是先生成一堆 proposal 再等人手工抄回去。

### 4.2 Promotion Authority

OpenSpace 不直接决定 runtime 是否更新。

source repo 改动要先经过分级 gate，再同步到 `~/.super-stack/runtime`。

也就是说：

- source repo 可以先被自动改
- runtime 必须后置推广

### 4.3 Activation Authority

runtime 被同步后，是否真正作为宿主运行版本生效，还要经过 install/check/smoke 这一层。

这样一来：

- OpenSpace 的效率没有被压死
- runtime 的稳定性也没有被牺牲

## 5. 为什么 runtime 不能直接编辑

原因不是“技术上做不到”，而是这样做不值得。

直接改 runtime 的问题：

- 很多 docs、tests、references、review 线索不在 runtime
- 容易绕过 source repo 的 git 审计
- sync 关系会被破坏
- 回滚和定位会变复杂

因此更稳的做法是：

- 在 source repo 改
- 在 runtime 推广

## 6. OpenSpace 和 `codex-record-retrospective` 的关系

推荐分工是：

- OpenSpace：底层 memory / lineage / search / import-export backend
- `codex-record-retrospective`：采集、归一化、推荐、source repo patch / direct edit adapter

### 6.1 `codex-record-retrospective` 未来的职责

它应该负责：

- 从 `harness/tasks/<task-id>/` 采集任务证据
- 从宿主 session / logs 提取时间线和上下文
- 做 path correlation、session slicing、lesson normalization
- 把 lesson 推入 OpenSpace
- 从 OpenSpace 拉回 candidate evolution
- 根据变更分级：
  - 直接修改 source repo working tree
  - 或生成 patch proposal / review packet
- 为 runtime promotion 输出足够的 evidence

### 6.2 OpenSpace 负责的事情

OpenSpace 负责：

- lesson persistence
- lineage tracking
- local / cloud retrieval
- skill discovery
- delegate-task 这类宿主级能力
- dashboard 和检查面板

这个拆法的好处是：

- 你的 workflow 逻辑仍然在 `super-stack`
- OpenSpace 成为 backend + executor，而不是新的真源

## 7. 推荐的本机部署方式

我不建议把 OpenSpace vendoring 到 `super-stack` 仓库里。

更稳的做法是把它作为独立受管依赖部署，并由 `super-stack` 管理接线。

### 7.1 推荐目录

建议把 OpenSpace 作为独立服务目录放在宿主级路径，例如：

```text
~/.super-stack/
  runtime/
  state/
  backup/
  openspace/
    .conda/
    bin/
      openspace-mcp-codex
    workspace/
    logs/
```

说明：

- `openspace/` 根目录本身就是上游仓库 checkout
- `.conda/`：独立 Conda 环境
- `bin/openspace-mcp-codex`：给 Codex MCP 注入最小环境变量的包装入口
- `workspace/`：`OPENSPACE_WORKSPACE`
- `logs/`：运行日志或诊断输出

这样做的原因是：

- 不污染 `super-stack` source repo
- 不把第三方依赖和 runtime 混在一起
- 升级、替换、回滚都更简单

当前已经在本机按这套形态完成了一次真实部署：

- git clone 路径：`~/.super-stack/openspace`
- 独立环境：`~/.super-stack/openspace/.conda`
- Codex MCP 包装入口：`~/.super-stack/openspace/bin/openspace-mcp-codex`
- OpenSpace workspace：`~/.super-stack/openspace/workspace`
- dashboard 日志目录：`~/.super-stack/openspace/logs/`

## 8. 如何搭建 OpenSpace

下面的步骤是基于官方 README 的实用化收口，不要求现在就把所有功能接全。

在重新核对 OpenSpace 源码之后，需要补一个更准确的判断：

- 对于“让宿主 Agent 接上 OpenSpace”这件事，官方 baseline 的确很薄
- 最小对接面就是：
  - MCP server
  - `OPENSPACE_HOST_SKILL_DIRS`
  - `OPENSPACE_WORKSPACE`
  - 复制 `delegate-task` 和 `skill-discovery` 两个 host skills
- 这一步完成后，OpenSpace 就会在 MCP 启动和后续 `execute_task` / `search_skills` 调用时，自动扫描并注册 host skill dirs

也就是说，之前方案里把“host 接线”和“retrospective 演化 adapter”讲得太近了，容易让人误以为接 OpenSpace 必须先做一整套自定义后端。

更准确的分层应该是：

- Layer A：官方薄对接
- Layer B：`super-stack` 的 retrospective / skill evolution 扩展
- Layer C：source repo direct edit + runtime promotion gate

其中只有 Layer A 是 OpenSpace baseline 必需项；Layer B / C 都是我们为了让 `super-stack` 长期进化而叠加的工程层。

### 8.1 Phase 0：先验证 OpenSpace 本身能跑

目标：确认上游仓库、Python 环境、MCP 可执行入口和 dashboard 没有基础障碍。

建议步骤：

1. clone OpenSpace 到 `~/.super-stack/openspace`
2. 在 `~/.super-stack/openspace/.conda/` 建独立环境
3. 在仓库根目录执行 `pip install -e .`
4. 运行 `~/.super-stack/openspace/.conda/bin/openspace-mcp --help`，确认命令已可用
5. 如需可视化，执行前端依赖安装与 build，再启动 dashboard server

这一步先不要接 `super-stack` 逻辑，只做“上游能不能在你机器上稳定运行”的体检。

当前机器上的实际验证结果：

- `pip install -e .` 已成功
- `openspace-mcp --help` 已通过
- `frontend/dist` 已构建完成
- dashboard 已可由 backend 直接提供静态页面

当前机器上的一个上游注意点：

- `pip install -e .[macos]` 会在当前环境触发依赖冲突：`openspace` 需要 `pyautogui>=0.9.54`，而 `atomacos` 约束 `pyautogui<0.9.42`
- 因此当前采用的是 base package 安装，不启用 `[macos]` extra
- 独立 Conda 环境能很好地隔离这类冲突，但不能“自动解决”上游声明本身互相矛盾的问题

### 8.2 Phase 1：把 OpenSpace 接进宿主，但不接 source repo 自动修改

目标：先把宿主与 OpenSpace 连接起来，让它成为一个可用 backend。

建议接法：

- 在宿主 MCP 配置中注册 `openspace` server
- `command` 使用 `openspace-mcp`
- 配好最小环境变量
- 把 OpenSpace 提供的 host skills 接进宿主技能发现路径

当前 `super-stack` 的最小实现口径是：

- `config/manifest.json` 已内置 `openspace` server 定义
- `codex_mcp` 已默认消费该 server
- 当宿主存在 `openspace-mcp` 或设置 `OPENSPACE_MCP_BIN` 时，`scripts/install/install.sh --host codex` 会自动把它写入 `~/.codex/config.toml`

也就是说，Codex 侧第一步不需要再改安装脚本，后续只需保证宿主二进制和环境变量可解析。

基于源码进一步确认后，这里再补一条非常重要的边界：

- “复制 host skills 就完成对接”这句话，对 OpenSpace 官方 baseline 来说是成立的
- 这两项 host skills 不是装饰品，它们就是 OpenSpace 教宿主 Agent 何时调用 `search_skills / execute_task / fix_skill / upload_skill` 的主要入口
- 只要 `OPENSPACE_HOST_SKILL_DIRS` 指向宿主 skill 目录，OpenSpace 的 MCP server 会自动把这些 skill dirs 重新扫描并注册进自己的 registry / DB

所以：

- 对“先接上 Codex”这个目标，我们现在已经达标
- 不需要为了“完成接线”再额外造一层自定义 ingestion backend
- 后续新增的任何 adapter，都应该被视为 `super-stack` 的增强层，而不是 OpenSpace baseline 的组成部分

当前机器上的实际接线方式是：

- `~/.codex/config.toml` 已存在 `[mcp_servers.openspace]`
- `command` 指向 `~/.super-stack/openspace/.conda/bin/openspace-mcp`
- wrapper 负责补齐：
  - `OPENSPACE_HOST_SKILL_DIRS=~/.agents/skills`
  - `OPENSPACE_WORKSPACE=~/.super-stack/openspace`
- OpenSpace host skills 已镜像到：
  - `~/.agents/skills/delegate-task`
  - `~/.agents/skills/skill-discovery`

推荐先用 local-only 模式：

- 不急着上 cloud
- 不急着开过宽权限
- 先证明宿主可以稳定发现、调用和记录

### 8.3 Phase 2：让 OpenSpace 开始修改 source repo

目标：让 OpenSpace 不只是存 memory，而是真正参与 source repo 的 skills 演进。

建议顺序：

1. `codex-record-retrospective` 先接 OpenSpace ingestion
2. 允许 OpenSpace 在低风险范围内直接修改 source repo working tree
3. source-side `check` 通过后，再进入 runtime promotion
4. 再逐步扩大到中风险改动

这里基于源码需要把 “ingestion” 的含义收紧：

- `OPENSPACE_WORKSPACE` 主要是工作目录、recording 和运行时空间，不是 lesson 导入接口
- `.openspace/openspace.db` 是内部存储，不适合拿来做外部脚本直写
- 本地最稳的真实接点仍然是“技能目录”

所以，`codex-record-retrospective` 如果要把结果真正送进 OpenSpace，本地最稳的方式不是直写 DB，也不是假设存在某个通用 lesson inbox，而是：

- 把高价值 lesson / recommendation 收口成可复用 skill
- 写入 `OPENSPACE_HOST_SKILL_DIRS` 所指向的宿主 skill 目录
- 让 OpenSpace 通过现有的自动扫描、注册、ID sidecar、safety check、lineage store 接管后续发现与演化

这也意味着我们前面的方案要收缩一下：

- baseline 不再强调“自定义 retrospective -> OpenSpace backend ingestion”
- 优先改成“retrospective -> candidate skill packet / skill patch -> host skill dirs -> OpenSpace auto-register”
- 只有当后续确认确实需要“非 skill 形态的长期 lesson storage”时，再补额外 adapter

### 8.4 Phase 3：按需开启 cloud community

只有在本地链路已经稳定后，再考虑：

- `OPENSPACE_API_KEY`
- cloud search
- import / export
- community skill reuse

这里一定要保留 gate。云端发现出来的 skill 或 recommendation，不能自动直推 runtime。

## 9. super-stack 应该如何接线

推荐由 `super-stack` 统一管理 OpenSpace 的接线，而不是让用户手工到处复制配置。

### 9.1 source repo 里要新增什么

后续若正式落地，source repo 里至少要补：

- OpenSpace 的受管安装脚本或安装说明
- 宿主 MCP 受管配置模板
- OpenSpace 可执行检查
- host skills 镜像或发现规则
- retrospective -> OpenSpace 的 adapter
- source-side 自动 check 入口
- runtime promotion gate 接口

### 9.2 managed config 需要覆盖什么

如果正式纳入 super-stack 的宿主管理，`managed-config` 至少要能表达：

- MCP server block
- OpenSpace 相关 env vars
- host skills 路径
- 可执行入口存在性检查
- local-only 与 cloud-enabled 的模式差异
- 是否允许 source repo draft edit

### 9.3 check / smoke 需要验证什么

最低限度要验证：

- `openspace-mcp` 命令存在
- 宿主 MCP 配置中有 `openspace` server
- OpenSpace host skills 可以被宿主发现
- local workspace 可写
- OpenSpace 对 source repo 的草稿改动能触发 source-side checks
- runtime promotion 后能跑 install/check/smoke

## 10. 推荐的环境变量口径

基于 OpenSpace 官方文档，后续最可能需要关注的是：

- `OPENSPACE_HOST_SKILL_DIRS`
- `OPENSPACE_WORKSPACE`
- `OPENSPACE_API_KEY`
- `OPENSPACE_ENABLE_RECORDING`
- `OPENSPACE_MAX_ITERATIONS`
- `OPENSPACE_BACKEND_SCOPE`

对 `super-stack` 的默认建议是：

- 默认 local mode
- 默认最小 scope
- 默认不开宽权限
- 默认先不开高风险 source repo 改动
- 默认不允许直接改 runtime

当前机器上的最小已验证值是：

- `OPENSPACE_HOST_SKILL_DIRS=~/.agents/skills`
- `OPENSPACE_WORKSPACE=~/.super-stack/openspace`

## 11. Dashboard 怎么用

如果你想观察 lineage、session、recording 和问题排查，OpenSpace 的 dashboard 是有价值的。

推荐用法：

- 开发调试阶段可以临时前台启动
- 如果已经决定长期保留，优先把 backend 作为常驻服务管理，而不是长期挂前端 dev server

当前机器上的实际运行方式：

- 前端已执行 production build
- backend 直接提供 `frontend/dist`
- PM2 当前管理的进程名为 `openspace-dashboard`
- 启动命令为：

```bash
~/.super-stack/openspace/.conda/bin/python -m openspace.dashboard_server --host 127.0.0.1 --port 7788
```

- 当前验证地址：`http://127.0.0.1:7788`

注意：dashboard 是观察面，不是新的 workflow 真源。

## 12. 真实数据流应该怎么走

推荐的数据流是：

```text
target project harness/
  -> codex-record-retrospective
  -> normalize / lesson extraction
  -> candidate skill / skill patch
  -> host skill dirs (OPENSPACE_HOST_SKILL_DIRS)
  -> OpenSpace auto-register + lineage
  -> candidate evolution
  -> source repo direct edit or patch proposal
  -> source-side check
  -> runtime sync / promotion
  -> runtime install/check/smoke
```

这个链路确保：

- 任务证据先落在项目内
- lesson 再进入宿主级后端
- source repo 才是主要编辑面
- runtime 只接收通过 gate 的推广结果

## 13. check 为什么重要，但为什么还不够

你前面那个判断是对的：sync 时跑 `check`，确实是效率关键点。

但 `check` 不能是唯一 gate。

原因是：

- `check` 很适合挡结构错误、路径错误、缺文件、格式错误、引用错误
- `check` 不一定能挡住技能语义退化、提示词漂移、跨技能耦合回归

所以推荐模型是：

- source-side `check`
- 必要时 targeted `smoke`
- 高风险改动再加人工 `review`
- 之后才允许 runtime promotion

详细分级见：

- [runtime-promotion-gates.md](/Users/gclm/workspace/lab/ai/super-stack/docs/architecture/decisions/runtime-promotion-gates.md)

## 14. 最终结论

我的判断是：

- OpenSpace 值得引入，而且适合替代 `~/.super-stack/projects/<slug>/`
- 它不该只做 passive backend，也可以直接参与 source repo 技能进化
- 但它的直接修改面应是当前 source repo，而不是 runtime
- 真正的效率来自“source repo direct edit + source-side check + runtime promotion gate”
- 真正的稳定性来自“runtime 不直接编辑、推广前分级 gate、推广后 install/check/smoke”

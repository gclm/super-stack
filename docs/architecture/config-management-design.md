# super-stack 配置治理设计

这份文档只回答一个问题：

当 super-stack 需要接管 Claude / Codex 的一部分全局配置时，应该如何定义配置归属、合并方式、检查口径与卸载恢复语义，避免继续出现“文件已安装但配置未启用”的半安装态。

## 1. 背景

当前 super-stack 已经完成以下结构收敛：

- source repo 固定为当前仓库
- runtime repo 固定为 `~/.super-stack/runtime`
- state 固定为 `~/.super-stack/state`
- backup 固定为 `~/.super-stack/backup`
- Claude / Codex 宿主入口统一引用 runtime，而不再直接引用 source repo

但在宿主配置层，之前仍存在一个明显问题：

- `~/.codex/agents/*.toml` 已被复制
- `~/.codex/config.toml` 却没有稳定注册这些 agents
- 安装结果于是落入“文件在，但配置未启用”的半安装态

这个问题说明，现有安装模型虽然已经做了目录分层，但还没有把“宿主文件内的受管配置片段”纳入统一治理。

## 2. 设计目标

本设计的目标是：

1. 明确哪些配置由 super-stack 完全接管。
2. 明确哪些文件整体归用户，但其中某些片段归 super-stack 管理。
3. 让 install / check / uninstall 三条链路遵循同一套语义。
4. 避免后续每加一种配置，就再发明一套新的 merge 规则。
5. 在不粗暴覆盖用户自定义配置的前提下，让 super-stack 需要的能力稳定可用。

本设计刻意不追求：

- 一次性接管所有宿主配置
- 自动合并用户任意复杂的 TOML / JSON 结构
- 在当前阶段引入过重的配置编排系统

## 3. 当前问题模型

当前宿主配置大致分成四层：

1. source repo 中的源定义
2. runtime repo 中的运行资产
3. 宿主 home 目录中的受管文件
4. 宿主 home 目录中的用户自定义配置

问题不在于分层本身，而在于不同层之间的接线规则不一致：

- 有些资产是“整文件复制”
- 有些资产是“仅当文件不存在才写入”
- 有些资产是“追加 hooks 块”
- 有些资产虽然被复制，但没有保证引用关系闭合

于是安装、检查、卸载三个阶段看到的对象并不是同一个配置模型。

## 4. 配置归属模型

为解决这个问题，建议把宿主配置归属明确分成三类。

### 4.1 fully managed

这类路径由 super-stack 完全管理，可以直接复制、覆盖、校验和删除。

典型对象：

- `~/.codex/AGENTS.md`
- `~/.codex/agents/super-stack-*.toml`
- `~/.claude/CLAUDE.md`
- `~/.claude/skills/<managed-skill>`
- `~/.agents/skills/<managed-skill>`
- `~/.super-stack/runtime/*`

规则：

- install 可直接写入
- check 应校验存在性与内容/结构
- uninstall 可直接删除，并按 install-state 恢复原状

### 4.2 managed block inside user-owned file

这类文件整体归用户，但其中某些片段由 super-stack 接管。

典型对象：

- `~/.codex/config.toml` 中的 super-stack hooks 块
- `~/.codex/config.toml` 中的 super-stack agents 块
- `~/.claude/settings.json` 中的 super-stack hooks 片段

规则：

- super-stack 只管理受管块，不管理文件其余内容
- install 只注入或更新受管块
- check 只验证受管块及其引用关系
- uninstall 只移除受管块，保留用户其余配置

### 4.3 user-owned

这类配置默认不由 super-stack 接管，也不应在没有明确设计决策的前提下被覆盖。

典型对象：

- `~/.codex/config.toml` 中用户自己的 model/provider 配置
- `~/.codex/config.toml` 中用户自己的 sandbox / approval / web_search 偏好
- `~/.codex/agents/*.toml` 中非 super-stack 角色文件
- `~/.claude/settings.json` 中与 super-stack 无关的个人设置

规则：

- install 不主动覆盖
- check 不把这些内容纳入失败条件
- uninstall 不触碰这些内容

## 5. 受管块模型

为了避免每类配置各写一套 merge 逻辑，建议统一使用“受管块”这一抽象。

一个受管块至少应有以下属性：

- `block_id`
- `target_file`
- `begin_marker`
- `end_marker`
- `ownership`
- `content_source`
- `verification_rules`
- `uninstall_behavior`

按当前项目实际情况，第一阶段建议先稳定这五个块：

- `codex_hooks`
- `codex_agents`
- `codex_mcp`
- `claude_mcp`
- `claude_hooks`

### 5.1 Codex hooks block

目标文件：

- `~/.codex/config.toml`

职责：

- session lifecycle hook
- readonly command guard hook

边界：

- 不负责启用 multi-agent
- 不负责 model/provider 选择

### 5.2 Codex agents block

目标文件：

- `~/.codex/config.toml`

职责：

- 启用 `multi_agent = true`
- 定义 `[agents]`
- 注册 `super_stack_explorer`
- 注册 `super_stack_reviewer`
- 注册 `super_stack_planner`

边界：

- 不接管用户自己的 provider / model 决策
- 不声明与 super-stack 无关的 agent

### 5.3 Codex MCP block

目标文件：

- `~/.codex/config.toml`

职责：

- 在 `[mcp_servers.*]` 下登记 super-stack 当前要启用的宿主 MCP server
- 只为当前可解析到可执行入口的 server 输出受管配置
- 让后续新增 MCP server 可以通过共享 manifest 扩展，而不是继续改安装脚本

边界：

- 不接管与 super-stack 无关的用户自定义 MCP server
- 不替用户自动安装第三方 MCP 可执行文件

### 5.4 Claude MCP block

目标文件：

- `~/.claude/settings.json`

职责：

- 在顶层 `mcpServers` 下登记 super-stack 当前要启用的宿主 MCP server
- 与 Codex 侧复用同一份共享 `mcp.servers`
- 保持 future MCP 扩展仍然是 manifest 驱动，而不是 shell 逻辑驱动

边界：

- 不接管用户自定义的其他 Claude settings
- 不替用户自动安装第三方 MCP 可执行文件

### 5.5 Claude hooks block

目标文件：

- `~/.claude/settings.json`

职责：

- session start / pre-tool-use / stop hooks

边界：

- 不接管其他 Claude 个性化设置

## 6. install / check / uninstall 一致性语义

当前后续设计必须围绕同一套生命周期语义展开。

### 6.1 install

install 的目标不是“尽量多复制文件”，而是建立一个完整、可验证的受管状态。

install 应完成：

1. 创建或更新 fully managed 资产。
2. 向用户文件中注入或刷新 managed blocks。
3. 记录安装前状态，用于 uninstall 恢复。
4. 记录 source repo 路径。
5. 建立引用关系闭合。

“引用关系闭合”指的是：

- 如果 `config.toml` 注册了 `agents/super-stack-explorer.toml`
- 那么对应文件必须在 `~/.codex/agents/` 中真实存在

### 6.2 check

check 的目标不是只看“某个文本是否出现”，而是验证受管状态是否闭环。

check 至少应覆盖：

1. fully managed 文件是否存在。
2. managed blocks 是否存在。
3. managed blocks 的关键字段是否存在。
4. managed blocks 引用的 fully managed 文件是否存在。
5. runtime / host / skills 之间的接线是否一致。

对 Codex 而言，下一阶段推荐的最小检查闭环是：

- `~/.codex/AGENTS.md` 指向 runtime
- `~/.codex/config.toml` 包含 agents 受管块
- `~/.codex/config.toml` 包含 hooks 受管块
- `multi_agent = true` 存在
- `config_file = "agents/super-stack-*.toml"` 存在
- `~/.codex/agents/super-stack-*.toml` 存在

### 6.3 uninstall

uninstall 的目标不是“删除一切”，而是回到 install 之前的可解释状态。

uninstall 应遵循：

1. 删除 fully managed 资产。
2. 移除 managed blocks。
3. 恢复 install-state 记录的原状。
4. 不触碰 user-owned 配置。

这里有一个重要约束：

- uninstall 恢复的是“install 开始时的状态”
- 不是测试作者主观想象中的“所有 super-stack 路径都应消失”

例如当前 `install.sh` 会先准备 browser wrapper，再记录 install-state，因此卸载后 `runtime` 可能恢复到“仅包含 browser wrappers 的预安装状态”，这是设计结果，不是异常。

## 7. 第一阶段治理范围

为了控制复杂度，建议下一阶段只把已经存在的治理对象规范化，而不继续扩张托管范围。

第一阶段仅包含：

1. Codex hooks block
2. Codex agents block
3. Codex MCP block
4. Claude MCP block
5. Claude hooks block

暂不纳入：

- 用户 provider / model 配置
- 用户 sandbox / approval 选择
- 用户自定义 agent
- 项目级 trust 或其他个性化本地配置

原因：

- 这些区域更容易和用户个人习惯冲突
- 在还没有统一受管块框架之前，贸然扩张只会增加配置缝隙

## 8. 配置定义的落地方式

从当前项目阶段来看，不建议立刻上复杂的配置编排系统，但也不应继续把受管块散落在多个脚本里硬编码。

建议分两步走。

### 8.1 当前阶段

保持现有 shell merge 脚本，但统一遵守受管块模型：

- 明确 block marker
- 明确 block ownership
- 明确 check 规则
- 明确 uninstall 预期

### 8.2 下一阶段

维持当前单一 `config/manifest.json`，作为 install / check / uninstall / validation 的共享定义源。

当前 `manifest.json` 至少应能表达：

- `manifest_version`
- `mcp.servers`
- 带显式 `kind` 的 `managed_blocks`
- `skill_validation.ignore_warnings`
- target file / markers / verify rules
- host 复用的 MCP server catalog

当前仓库已落地为 JSON；重点仍然不是格式，而是 install / check / validation 统一消费单一 manifest，而不是把规则散落在脚本里。

## 9. 渐进迁移计划

推荐按下面顺序推进。

### Phase 1

先把当前设计文档固定下来，并将现有脚本解释为“managed block v1”。

产出：

- 本文档
- `STATE.md` 中的当前决策记录

### Phase 2

补强单一 manifest 的显式校验与错误信息。

产出：

- `config/manifest.json` 统一承载 Codex hooks / agents / MCP、Claude hooks / MCP 与 skill validation exception
- 一份可被多个 host block 复用的共享 `mcp.servers`
- 一层最小渲染/检查/manifest schema 校验逻辑

### Phase 3

把 install / check 脚本逐步改成消费统一定义，而不是继续手写重复规则。

产出：

- 更薄的 merge 脚本
- 更一致的 check 逻辑

### Phase 4

补强 relation-based integration tests。

重点覆盖：

- 块存在
- 块幂等
- 引用关系闭合
- uninstall 恢复到 install 前语义

## 10. 风险与边界

### 10.1 风险：托管范围继续膨胀

如果在没有统一 ownership model 的前提下继续把更多用户配置纳入 super-stack 管理，配置冲突只会增加。

控制方式：

- 第一阶段只治理当前已存在的五类块
- 任何新增托管范围都先经过设计审查

### 10.2 风险：检查脚本和安装脚本再次漂移

如果检查脚本只 grep 文本，而安装脚本已经开始使用新的受管块定义，两者会再次失配。

控制方式：

- 当前已引入共享 manifest
- install / check / validation 已消费同一份定义，且通过 schema + semantic validation 双层校验防止配置漂移

### 10.3 风险：卸载预期与真实 install-state 不一致

如果测试继续假设“卸载后所有 super-stack 路径都不存在”，会不断误报。

控制方式：

- 始终以 install-state 记录的 pre-install 状态为准
- 在测试中明确区分“删除受管 runtime 内容”与“恢复 install 前 runtime 根目录”

## 11. 当前结论

当前最合理的下一步不是继续增加更多 merge 脚本，而是正式把 super-stack 的宿主配置治理定义为：

- fully managed 文件
- user-owned 文件中的 managed blocks
- 明确不接管的 user-owned 区域

并让 install / check / uninstall 三条链路以后都围绕这一模型演进。

这会比继续在个别脚本里补洞更稳定，也更容易解释给用户和后续维护者。

# super-stack v2 Roadmap: Claude Code Enhancement

v2 分支专注于为 Claude Code / Gclm Code 提供深度增强，优先聚焦 hooks 能力。

## 背景

v1 已完成：
- 共享路由 (AGENTS.md)
- 核心 skills
- 双宿主安装主线
- 基础 hooks (SessionStart, PreToolUse, Stop)
- readonly command guard (allow/ask 两级策略)

v2 目标：
- 让 Claude Code hooks 从"基础降噪"升级为"工程守卫"
- 为 Gclm Code 提供原生增强能力

## 当前 Claude Code Hooks 状态

| Hook | 当前行为 | 限制 |
|------|---------|------|
| SessionStart | 读取 harness/state.md 提示恢复 | 仅显示，无状态推断 |
| PreToolUse (Bash) | readonly 命令 auto-allow | 只有 allow/ask，无 deny |
| Stop | 提醒更新 state.md | 仅提醒，无自动保存 |

## v2 增强方向

### Phase 1: Hooks 风险分级

将 `readonly_command_guard.py` 从两级扩展为三级：

- `allow`: 白名单只读命令自动放行
- `ask`: 中等风险命令走确认流
- `deny`: 高危命令硬拦截（可选，用户可配置）

新增能力：
- 文件路径保护 (lockfile, secrets, .env)
- 危险命令 deny 列表 (rm -rf /, :(){ :|:& };:, etc.)
- 可配置的风险策略文件

### Phase 2: 智能状态恢复

增强 SessionStart hook：
- 自动检测上次中断点
- 从 harness/state.md 提取 active task
- 推断当前应该处于的 stage
- 提供恢复建议而非仅显示

### Phase 3: 上下文感知守卫

增强 PreToolUse hook：
- 识别当前 stage，根据 stage 调整策略
- 在 `build` stage 对写入操作更宽松
- 在 `review` stage 对写入操作更严格
- 支持 per-project hook 配置

### Phase 4: 自动状态持久化

增强 Stop hook：
- 自动提取当前对话关键决策
- 写入 harness/state.md
- 生成简短的 session summary

## Claude Code 原生能力探索

Gclm Code 作为 Claude Code 的增强版本，可以探索：

1. **自定义 hook 事件**
   - PostToolUse: 工具执行后的自动验证
   - OnError: 错误发生时的自动诊断
   - OnStageChange: workflow stage 变化时的自动动作

2. **hook 链式组合**
   - 多个 hook 按顺序执行
   - 前序 hook 可以影响后续 hook 行为

3. **hook 上下文共享**
   - hook 之间共享状态
   - 跨 session 的 hook 记忆

4. **项目级 hook 覆盖**
   - `.claude/hooks/` 项目本地 hook
   - 与全局 hook 合并策略

## 技术约束

- 保持与上游 Claude Code 的兼容性
- Gclm Code 特有能力通过 feature flag 控制
- hooks 必须保持轻量，不能显著增加延迟
- 所有增强必须可回退

## 里程碑

### M1: 风险分级落地
- deny 策略实现
- 文件路径保护
- 回归测试覆盖

### M2: 状态恢复增强
- 智能 stage 推断
- 恢复建议生成
- harness/state.md 格式扩展

### M3: 上下文感知
- stage-aware 策略
- per-project 配置
- 策略热加载

### M4: Gclm Code 原生能力
- 自定义事件 hook
- hook 链
- 项目级覆盖

## 不做的事

- 不做复杂的 AI 推断（保持 hook 为确定性逻辑）
- 不做跨仓库的全局状态（保持项目隔离）
- 不替代 Claude Code 原生安全机制（只做增强）

## 参考

- [readonly-command-hook.md](../architecture/decisions/readonly-command-hook.md)
- [hook-risk-regression-matrix.md](../reference/validation/hook-risk-regression-matrix.md)
- [evolution-roadmap.md](./evolution-roadmap.md)

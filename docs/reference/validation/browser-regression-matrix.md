# 浏览器专项回归矩阵

用于记录宿主侧 browser MCP / browser plugin 主链路是否仍然可用，以及当前问题出在：

- 浏览器能力探测
- 原始页面打开与落地 URL
- DOM / 截图 / console / network 证据采集
- 结论落盘与降级说明

## 基本信息

- 验证日期：
- 浏览器 provider：
- 会话名：
- 宿主：
- super-stack 版本或提交：

## 场景矩阵

| 编号 | 场景 | 适配器 | 证据 | 结果 | 备注 |
|------|------|--------|------|------|------|
| B1 | 检测宿主浏览器能力 | capability check | | | |
| B2 | 打开原始页面并记录落地 URL / 标题 | original-page open | | | |
| B3 | 提取正文或关键 DOM 片段 | DOM inspection | | | |
| B4 | 采集截图或页面快照 | screenshot / snapshot | | | |
| B5 | 检查 console / network 是否有关键异常 | console / network | | | |
| B6 | 无法取得浏览器证据时，是否明确说明降级原因 | fallback disclosure | | | |

## 需要重点记录的证据

- 输入 URL 与落地 URL
- 实际使用的 browser provider
- DOM 摘要、截图、console、network 中最小充分证据
- 证据落盘位置，例如 `harness/tasks/<task-id>/` 或评审记录
- 页面不可读时，是浏览器能力缺失、登录限制，还是页面结构变化

## 结论

- 总体结果：
- 主要退化点：
- 建议修复位置：

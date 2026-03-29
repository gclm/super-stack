# REQUIREMENTS

1. 共享工作流路由、技能、协议与模板，服务 Claude 与 Codex 双宿主。
2. 提供可安装、可检查、可回归的本地运行链路。
3. 产品定位收敛为全局配置底座，不再继续维护项目级安装分支与项目级覆盖安装链路。
4. 对明显跨 session 的复杂任务，工作流应支持可恢复的状态表达、可验证的完成口径，以及基于真实使用记录的持续演进。
5. 在现有 shared workflow runtime 基础上，逐步补齐适合本地长任务的 `super-stack-native harness`：统一进度产物、恢复入口、证据包、停止门与 retrospective automation，并保持 `source repo first`、薄入口与人工审批边界。

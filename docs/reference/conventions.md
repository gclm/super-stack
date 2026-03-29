# 项目约定

## 语言与文档
- 面向用户的说明、状态摘要、验证总结与设计文档默认使用中文。
- 命令、路径、协议名、代码标识与外部接口保持英文。
- target project 的长期知识默认放在 `docs/`，执行态默认放在 `harness/`。

## 工作流
- 主链路保持 `discuss -> plan -> build -> review -> verify -> ship`。
- 阶段前提不满足时要显式回退，不允许静默越级。
- 复杂长任务优先落 `harness/tasks/<task-id>/...`，不要只留在聊天上下文里。

## source/runtime 边界
- 共享变更先修改 source repo，再通过受管链路推广到 `~/.super-stack/runtime`。
- runtime 不作为主要编辑面，也不承载 source repo 自身的 `docs/` 或 `harness/` 状态。
- host 生成的 hook/log 产物统一落在 `harness/.runtime/` 并忽略提交。

## 提交与验证
- 若仓库沿用 super-stack 默认约定，commit message 使用 Angular 风格，摘要默认中文。
- 重要阶段边界优先形成可回退的小 checkpoint，而不是长期堆积大工作区。
- 任何结构变更都要同步更新 docs、tests、smoke 与 install/check 口径。

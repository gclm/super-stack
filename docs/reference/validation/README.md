# 验证参考

这些文档承载 `super-stack` 在 source repo 和 generated project 里的通用验证参考。

它们替代了旧的独立 validation 模板目录。新项目默认应从 `docs/reference/validation/` 读取和维护这些矩阵，而不是依赖仓库外散落模板。

## 文档清单

- [real-project-validation.md](real-project-validation.md): 在真实项目里验证 workflow / skill / host 行为的通用记录模板。
- [skill-regression-matrix.md](skill-regression-matrix.md): 回归 stage 路由、supporting skills 与工程约定是否漂移。
- [workflow-experience-validation.md](workflow-experience-validation.md): 记录一次完整工作流体验是否顺滑。
- [browser-regression-matrix.md](browser-regression-matrix.md): 回归宿主 browser MCP / plugin 的证据采集路径。
- [hook-risk-regression-matrix.md](hook-risk-regression-matrix.md): 回归 readonly hook 的 `allow / ask / deny` 风险分级。

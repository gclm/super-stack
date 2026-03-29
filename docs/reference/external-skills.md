# 外部 skills 引用机制（submodule）

本仓库通过 `git submodule` 引入外部 skills 仓库，目标是：

- 直接复用上游专业技能，不重复维护
- 通过固定 commit 保持可复现
- 通过定时更新 workflow 持续跟进上游

## 当前外部来源

- `external-skills/openspace`
  - 上游仓库：`https://github.com/HKUDS/OpenSpace`
  - 主要引用目录：`openspace/host_skills`
- `external-skills/contextweaver`
  - 上游仓库：`https://github.com/GowayLee/ContextWeaver`
  - 主要引用目录：`skills`
- `external-skills/obsidian-skills`
  - 上游仓库：`https://github.com/kepano/obsidian-skills`

## 拉取与初始化

首次克隆后执行：

```bash
git submodule update --init --recursive
```

若上游地址变更，可执行：

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

## 手动更新上游

```bash
git submodule update --remote --recursive
```

然后检查变更并提交：

```bash
git status
git add .gitmodules external-skills
git commit -m "chore: update external skills submodules"
```

## 自动更新

仓库内置 GitHub Actions：

- workflow: `.github/workflows/update-external-skills.yml`
- 触发方式：
  - 每日定时（UTC `03:17`）
  - 手动触发（`workflow_dispatch`）
- 行为：
  - 执行 `git submodule update --init --remote --recursive`
  - 若有变化，自动创建 PR

## 使用建议

- 在 super-stack 自有技能中，优先通过路径引用外部技能目录，不复制粘贴内容。
- 需要稳定发布时，依赖 submodule pin 到的 commit，而不是直接依赖上游 HEAD。

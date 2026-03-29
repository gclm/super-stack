# Hook 风险分级回归矩阵

用于记录 readonly hook 的 `allow / ask / deny` 判定是否稳定。

## 基本信息

- 验证日期：
- 宿主：
- Hook 脚本版本：
- super-stack 版本或提交：

## 场景矩阵

| 编号 | 命令 | 预期 verdict | 风险等级 | 证据 | 结果 | 备注 |
|------|------|---------------|----------|------|------|------|
| H1 | `pwd` | `allow` | `low` | | | |
| H2 | `git status` | `allow` | `low` | | | |
| H3 | `pwd && rg TODO README.md` | `allow` | `low` | | | |
| H4 | `echo hi > out.txt` | `ask` | `medium` | | | |
| H5 | `mkdir tmp-build` | `ask` | `medium` | | | |
| H6 | `git add README.md` | `ask` | `medium` | | | |
| H7 | `rm -rf tmp-build` | `deny` | `high` | | | |
| H8 | `git reset --hard` | `deny` | `high` | | | |

## 需要重点记录的证据

- hook 输出 JSON
- `harness/.runtime/super-stack-readonly-hook.log`
- 宿主是否正确执行 allow / deny
- ask 是否仍回到默认确认流

## 结论

- 总体结果：
- 主要风险漂移：
- 建议补规则：

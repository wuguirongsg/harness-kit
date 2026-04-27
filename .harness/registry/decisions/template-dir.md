# 架构决策：引入 template/ 目录

**日期**：2026-04-27
**背景**：harness-kit-v2 本身使用 .harness/ 协议进行开发。AI agent 在开发过程中会向 .harness/registry/_index.md、sessions/、decisions/、state/ 写入运行时数据，导致这些文件携带 harness-kit-v2 自身的历史记录被 install.sh 分发给用户项目。

---

## 决策

创建 `template/` 目录作为**唯一分发源**。`install.sh` 和 `upgrade.sh` 所有 cp 操作改为从 `template/` 读取，不再直接引用 `.harness/`、`.claude/`、`.cursor/` 等工作目录。

## 目录职责划分

| 目录 | 职责 | Agent 可以写入？ |
|------|------|----------------|
| `template/` | 分发给用户的纯净模板 | 否（agent 不感知这个目录） |
| `.harness/` | 本项目开发的实时状态 | 是 |

## 同步规则

`template/.harness/` 中的协议文件（SESSION_START.md、SESSION_END.md、hooks/）是 `.harness/` 中对应文件的分发副本。修改协议文件后必须手动同步到 `template/`。状态文件（state/、registry/sessions/、product/）的 `template/` 版本始终保持为空白初始状态，不随 `.harness/` 的运行时内容变化。

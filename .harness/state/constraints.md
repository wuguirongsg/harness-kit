# 已知约束

> 每次 Session 发现新约束时，追加到本文件末尾。不要删除历史条目。
> Agent 每次 Session 开始时扫读一遍，避免重蹈覆辙。

---

## 架构约束

- template/ 是唯一分发源，install.sh 和 upgrade.sh 只从 template/ 复制 — 防止 .harness/ 运行时状态（session记录、sprint状态）污染分发给用户的模板内容
- 修改协议文件（SESSION_START.md、SESSION_END.md、hooks/）后，必须同步更新 template/.harness/ 下的对应副本
- 所有 Hook 脚本必须通过 exit code 0/2 控制行为，不能靠 stdout 内容做逻辑判断
- 不引入 Node.js / Python 以外的运行时依赖（保持 install.sh 零额外依赖）
- features.json 只允许修改 passes 字段（false→true），禁止删除条目或修改 description
- 支持多 AI 工具（Claude Code / Cursor / Codex / OpenCode），不能为某一工具做特殊优化而破坏其他工具兼容性

## 已知坑

- install.bat 和 install.sh 是两条独立代码路径，修改一个必须同步另一个
- Hook 脚本大量使用 `2>/dev/null` 静默吞错，调试困难
- session-end-guard.sh 用日期检测 SESSION_END 是否完成，同一天多次会话只拦截第一次
- session-start.sh 无 token 预算控制，大型项目的 SESSION_START.md 可能占满上下文

## Session 中新发现的约束

（格式：`[YYYY-MM-DD] 约束描述 — 原因`）

[2026-04-27] template/ 是唯一分发源，install.sh 和 upgrade.sh 只从 template/ 复制 — 防止 .harness/ 运行时状态（session记录、sprint状态）污染分发给用户的模板内容。修改协议文件（SESSION_START.md、SESSION_END.md、hooks/）后，必须同步更新 template/.harness/ 下的对应副本。

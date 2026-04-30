# 决策索引

> **Agent 使用规则**：
> - Session 开始时：只读最近 5 条，了解近况
> - Session 结束时：在最前面追加新条目（不是末尾）
> - 不要读完整历史，用条目里的文件链接按需查阅

格式：`[日期 时间] [类型] 一句话摘要 → 详情文件`

类型说明：
- `DONE` 完成功能 · `WIP` 进行中 · `BLOCKED` 阻塞
- `DECISION` 架构决策 · `CONSTRAINT` 新发现约束 · `FIX` 修复问题

---

<!-- 新条目追加到这里（上方） -->

[2026-04-30 10:00] DECISION lifecycle phase 完整设计文档完成，7阶段模型 + :指令语法 + 自动判断算法，待实现 → decisions/lifecycle-phase-design.md

[2026-04-29 11:00] DECISION harness 生命周期支持不足诊断 + lifecycle phase 改造方向设计 → sessions/2026-04-29-1100.md

[2026-04-27 16:00] DONE 修复 install.bat template源bug + .gitignore + HARNESS_SETUP初始化完成（vision/features/AGENTS/constraints全部填写），第一阶段 5 个功能定义完成 → sessions/2026-04-27-1600.md

[2026-04-27 14:00] DECISION 引入 template/ 目录，install.sh/upgrade.sh 唯一源改为 template/，消除 .harness/ 运行时状态污染模板内容的问题 → decisions/template-dir.md

[2026-04-27 12:00] FIX install.sh 修复（zsh兼容/目标路径参数/session隔离），新增 install.ps1，Windows支持评估结论：只做install.bat不做.cmd hooks → sessions/2026-04-27-1200.md

[2026-04-23 13:49] FIX 修复 install.sh 中 Codex/OpenCode 源文件名错误（致命 bug），更新 README 目录结构和初始化说明 → sessions/2026-04-23-1349.md

[初始化日期] DECISION 项目 harness 初始化，建立 Session 协议框架 → decisions/init.md

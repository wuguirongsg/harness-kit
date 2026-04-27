# 项目愿景

> 这是所有决策的北极星。Sprint 规划前必读。
> 与愿景冲突的功能不做。修改本文件须在变更历史里记录原因。

---

## 产品定位

**为谁**：使用 AI Coding 工具（Claude Code / Cursor / Codex / OpenCode）的开发者

**解决什么问题**：Agent 在长时间自主工作中跑偏、失忆、自以为完成——三个核心问题都源于"靠 Prompt 叮嘱"不可靠

**一句话描述**：把约束写进环境（Hook 机械强制 + 外部状态文件），而不是靠 Prompt 叮嘱，让 AI Agent 在长时间自主工作中持续可靠

## 成功标准

用户安装 harness-kit 之后，以下状态出现，就算成功：

- Session 开始时 Agent 主动汇报状态并等待确认（不自说自话开始干活）
- Session 结束时 Agent 被强制完成收尾清单后才被允许退出（exit 2 拦截）
- 跨 Session 后 Agent 记得上次做到哪里、踩过什么坑（通过 registry 状态恢复）
- 功能完成后 features.json 的 passes 被正确更新，不会"看两眼就说做完了"
- 用户新项目 5 分钟内完成安装并开始第一次初始化对话

## 明确不做什么

> 清晰的边界防止功能蔓延。

- 不做：AI Agent 的 Prompt 工程服务（那是 AGENTS.md 的职责，harness 只提供 Hook 执行 + 状态管理）
- 不做：代码生成、代码审查、project scaffolding
- 不做：SaaS / Web 产品
- 不做：单一 AI 工具绑定（必须同时支持 Claude Code / Cursor / Codex / OpenCode）

## 核心用户画像

| 用户类型 | 核心诉求 | 典型场景 |
|----------|----------|----------|
| 个人开发者 | 希望 AI Agent 做事靠谱、不瞎搞 | 用 Claude Code 开发个人项目，每次会话 Agent 都知道做到哪了 |
| 小团队 | 希望统一团队的 AI 使用规范 | 全团队用 Cursor，harness 确保 commit 格式、代码风格一致 |
| 开源维护者 | 希望贡献者的 AI Agent 不乱改项目规范 | PR 贡献者用 AI 写的代码能自动通过约束检查 |

---

## 变更历史

> 愿景级别的调整必须记录原因，不允许静默变更。

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-04-27 | 项目愿景初始化 | HARNESS_SETUP 执行 |

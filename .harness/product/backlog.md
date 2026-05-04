# 产品 Backlog

> 需求池、产品方向、已知约束 — 集中在这一个文件。
> Sprint 规划时从"待评估"区取材；发现约束立即追加到"已知约束"区。

---

## 产品方向

> 所有决策的北极星。与此冲突的功能不做。

**为谁**：使用 AI Coding 工具（Claude Code / Cursor / Codex / OpenCode）的开发者

**解决什么**：Agent 在长时间自主工作中跑偏、失忆、自以为完成——三个核心问题都源于"靠 Prompt 叮嘱"不可靠

**一句话定位**：把约束写进环境（Hook 机械强制 + 外部状态文件），而不是靠 Prompt 叮嘱，让 AI Agent 在长时间自主工作中持续可靠

**成功标准**：
- Session 开始时 Agent 主动汇报状态并等待确认（不自说自话开始干活）
- Session 结束时 Agent 被强制完成收尾清单后才被允许退出（exit 2 拦截）
- 跨 Session 后 Agent 记得上次做到哪里、踩过什么坑（通过 registry 状态恢复）
- 功能完成后 features.json 的 passes 被正确更新，不会"看两眼就说做完了"
- 用户新项目 5 分钟内完成安装并开始第一次初始化对话

**明确不做**：
- AI Agent 的 Prompt 工程服务（那是 AGENTS.md 的职责，harness 只提供 Hook 执行 + 状态管理）
- 代码生成、代码审查、project scaffolding
- SaaS / Web 产品
- 单一 AI 工具绑定（必须同时支持 Claude Code / Cursor / Codex / OpenCode）

---

## 待评估需求

> 格式：`- [日期] [来源] 描述`
> 来源：自己 / 用户反馈 / 竞品观察 / 技术债 / [VERIFY] / [RETRO]

<!-- 新需求追加到这里 -->

---

## 已规划 / 已否决 / 变更

> 已进入 Sprint 的需求注明 Sprint；取消/调整的功能也记在这里。

- [2026-04-30] Sprint-1 — 7 阶段生命周期支持（DISCOVER/DESIGN/PLAN/BUILD/VERIFY/RELEASE/RETRO）
- [2026-04-30] Sprint-1 — Stop hook stdout 注入机制修复
- [2026-05-04] CANCEL — 移除独立 vision.md / constraints.md / changes.md，合并到 backlog.md（原因：过度设计，三个孤儿文件缺乏流程触发，实际从未被维护）

---

## 已知约束与坑

> 发现新约束立即追加。不要删历史。

### 架构约束

- template/ 是唯一分发源，install.sh/upgrade.sh 只从 template/ 复制 — 防止 .harness/ 运行时状态污染分发模板
- 修改协议文件（SESSION_START.md、SESSION_END.md、hooks/）后，必须同步更新 template/.harness/ 对应副本
- 所有 Hook 脚本必须通过 exit code 0/2 控制行为，不能靠 stdout 内容做逻辑判断
- 不引入 Node.js / Python 以外的运行时依赖（保持 install.sh 零额外依赖）
- features.json 只允许修改 passes 字段（false→true），禁止删除条目或修改 description
- 支持多 AI 工具（Claude Code / Cursor / Codex / OpenCode），不能为某一工具特殊优化而破坏其他工具兼容性

### 已知坑

- install.bat 和 install.sh 是两条独立代码路径，修改一个必须同步另一个
- Hook 脚本大量使用 `2>/dev/null` 静默吞错，调试时先去掉
- session-end-guard.sh 用日期检测 SESSION_END 是否完成，同一天多次会话只拦截第一次
- session-start.sh 无 token 预算控制，大型项目的 SESSION_START.md 可能占满上下文

### Session 中新发现

（格式：`[YYYY-MM-DD] 描述 — 原因`）

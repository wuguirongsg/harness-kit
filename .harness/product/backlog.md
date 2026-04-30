# 需求池（Backlog）

> 所有未规划的需求、想法、用户反馈都先进这里。
> 随时可以告诉 Agent："把这个加到 backlog：[描述]"，Agent 立即记录。
> Sprint 规划时从"待评估"区取材，不直接跳到 features.json。

---

## 待评估

> 格式：`- [日期] [来源] 描述`
> 来源可以是：自己、用户反馈、竞品观察、技术债、临时想法

<!-- 新需求默认追加到这里 -->


## 已规划

> 已进入某个 Sprint 的需求，从"待评估"移过来，注明 Sprint。

- [2026-04-30] 第二阶段 — harness 生命周期阶段支持（DISCOVER/DESIGN/PLAN/BUILD/VERIFY/RELEASE/RETRO）+ `:phase` 指令语法 → 设计文档见 decisions/lifecycle-phase-design.md
- [2026-04-30] 第二阶段 — Stop hook stdout 注入机制修复（settings.json additionalContext 验证）

<!-- 格式：- [日期] Sprint-N — 描述 -->

## 已否决

> 决定不做的需求。必须写原因，不允许静默删除。

<!-- 格式：- [日期] 否决原因 — 描述 -->

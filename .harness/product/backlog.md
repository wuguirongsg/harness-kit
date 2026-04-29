# 需求池（Backlog）

> 所有未规划的需求、想法、用户反馈都先进这里。
> 随时可以告诉 Agent："把这个加到 backlog：[描述]"，Agent 立即记录。
> Sprint 规划时从"待评估"区取材，不直接跳到 features.json。

---

## 待评估

> 格式：`- [日期] [来源] 描述`
> 来源可以是：自己、用户反馈、竞品观察、技术债、临时想法

<!-- 新需求默认追加到这里 -->

- [2026-04-29] [用户] harness SESSION_START 只有"功能开发"和"Sprint切换"两种模式，不支持完整软件开发生命周期（DISCOVER/DESIGN/PLAN/BUILD/VERIFY/RELEASE/RETRO），需要引入 lifecycle phase 概念重新设计 SESSION_START 行为
- [2026-04-29] [用户] Stop hook 的 stdout 注入机制可能未生效——hook exit 2 后 SESSION_END 清单未能自动注入到 Claude 上下文，用户只看到"No stderr output"通知，需排查并修复

## 已规划

> 已进入某个 Sprint 的需求，从"待评估"移过来，注明 Sprint。

<!-- 格式：- [日期] Sprint-N — 描述 -->

## 已否决

> 决定不做的需求。必须写原因，不允许静默删除。

<!-- 格式：- [日期] 否决原因 — 描述 -->

# Session 结束协议

按顺序执行，5 分钟内完成。

## 第零步：捕获需求
用户提到的新想法/改动意向/反馈 → 追加到 `.harness/product/backlog.md` 待评估区。
格式：`- [日期] [来源] 描述`

## 第一步：决策记录
本次有架构/命名/选型/接口决策 → 创建 `.harness/registry/decisions/YYYY-MM-DD.md`。
无重大决策则跳过。

## 第二步：约束记录
发现新边界或坑 → 追加到 `.harness/state/constraints.md`。无则跳过。

## 第三步：Session 摘要
有具体产出（代码/决策/Bug）→ 创建 `.harness/registry/sessions/YYYY-MM-DD-HHmm.md`。
纯探索讨论则跳过。内容：完成了什么、未完成什么、下次从哪开始。

## 第四步：更新索引
在 `.harness/registry/_index.md` **最前面**追加一行：
`[YYYY-MM-DD HH:mm] [类型] 摘要 → sessions/文件名`
类型：DONE / WIP / BLOCKED / FIX / DISCOVER / DECISION

## 第五步：features.json 与 changes.md
**BUILD/VERIFY 阶段**：完成的功能 passes 改为 true（只能 false→true）。
**PLAN 阶段**：追加新功能条目到 features.json；更新 current-sprint.md 元数据（阶段/目标/默认阶段）。
　　并检查：本次有无功能被取消/推迟/降优先级？
　　→ 有 → 追加到 `product/changes.md`（格式见文件头部注释）
　　→ 无 → 跳过（不需要在 changes.md 写"无变更"）
**RETRO 阶段**：讨论产生改进行动项 → 写入 backlog.md；方向性调整 → 追加到 changes.md。
**其他阶段**：跳过本步骤。

## 第六步：git commit
```bash
git add .harness/
git commit -m "chore: session YYYY-MM-DD HH:mm - 一句话摘要"
```

## 最后：告知用户
本次完成了什么、未完成什么、下次建议从哪里开始。

---

## FIX 子模式（快速修复）
1. **第零步（保留）**：对话中提到新想法/反馈 → 一行追加到 `product/backlog.md`；无则跳过
2. `_index.md` 最前面追加：`[时间] FIX 修复内容 → commit hash前7位`
3. `git add .harness/ && git commit -m "chore: session ..."`

跳过第一~三步（决策文件/约束/摘要）。

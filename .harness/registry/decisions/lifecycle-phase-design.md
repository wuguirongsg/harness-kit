# harness 生命周期阶段支持 — 设计文档

**状态**：已实现（部分补丁见 2026-05-04 追加）
**日期**：2026-04-30
**补丁日期**：2026-05-04
**背景**：当前 SESSION_START 只有"功能开发"和"Sprint切换"两种模式，
不符合完整软件开发周期（需求→设计→规划→开发→验证→发布→复盘）。

---

## 一、问题诊断

现有系统假设"每次对话 = 编写代码"，因此：
- SESSION_START 永远问"哪个 feat 还没做"
- 设计讨论、需求梳理、架构决策类会话被强行套进迭代框架
- 用户每次都要对抗协议，而不是被协议辅助

---

## 二、生命周期阶段模型

### 阶段定义

```
DISCOVER → DESIGN → PLAN → BUILD → VERIFY → RELEASE → RETRO
  需求       设计     规划    开发     验证      发布      复盘
```

| 阶段 | 典型任务 | 主要产出 |
|------|----------|----------|
| DISCOVER | 梳理需求、用户访谈、澄清模糊点 | `docs/requirements/` 下的需求文档 |
| DESIGN | 产品设计、架构决策、技术选型 | `docs/design/` 下的设计文档；`registry/decisions/` 下的 ADR |
| PLAN | Sprint 规划、任务分解、优先级排序 | `registry/decisions/sprint-N-plan.md`；`features.json` 新条目 |
| BUILD | 编写代码、功能实现 | 代码提交；`features.json` passes 更新 |
| VERIFY | 测试、回归、Bug 排查 | 测试报告；Bug 修复提交 |
| RELEASE | 发布准备、部署、变更记录 | `docs/releases/vX.Y.Z.md`；git tag |
| RETRO | 阶段复盘、改进项 | `registry/decisions/retro-N.md` |

### 阶段流动规则

- 阶段不是严格线性的，可以在任意阶段跳转
- `current-sprint.md` 记录当前项目的"默认阶段"（大部分工作所在）
- 单次 Session 可以临时切换阶段，不改变项目默认阶段
- 只有用户明确说"我们进入 X 阶段了"，才更新 `current-sprint.md` 的 phase 字段

---

## 三、阶段指令语法

用 `:` 前缀（避开 `/` 被各工具占用）。

### 支持的指令

| 指令 | 作用 |
|------|------|
| `:discover` | 明确开始需求探索 Session |
| `:design` | 明确开始设计 Session |
| `:plan` | 明确开始规划 Session |
| `:build` | 明确开始开发 Session（当前默认行为）|
| `:fix` | 快速修复子模式——跳过规划，直接描述问题，做完只需一行记录 |
| `:verify` | 明确开始验证/测试 Session |
| `:release` | 明确开始发布 Session |
| `:retro` | 明确开始复盘 Session |
| `:status` | 任何时候查看当前阶段和状态摘要 |
| `:phase X` | 将项目默认阶段切换为 X，并更新状态文件 |

### 使用方式

指令可以出现在消息任意位置：

```
:build 继续做 feat-002

我想 :design 讨论一下新的认证架构

:retro 回顾一下上个 Sprint
```

### 指令解析规则

Agent 在每轮对话开始时检查用户消息是否包含 `:xxx` 指令。
如果包含且匹配已知阶段名，立即切换上下文；如果不认识，提示用户可用指令列表。

---

## 四、阶段自动判断算法

### 判断时机

SESSION_START 执行"两步法"：

**第一步（读状态文件后，用户说话前）**：
只输出简短状态摘要（当前阶段、最近一条 _index 条目、一句话提示），然后用开放式问题等待用户。

```
## Session 开始

当前默认阶段：BUILD（feat-002、feat-004、feat-005 待完成）
上次：[从 _index.md 最新条目]

今天要做什么？（或用 :指令 明确阶段）
```

**第二步（用户回复后）**：
根据以下优先级判断本次 Session 阶段：

```
优先级 1：用户消息包含 :指令 → 直接使用
优先级 2：用户消息包含阶段关键词 → 推断
优先级 3：current-sprint.md 的 phase 字段 → 使用默认阶段
优先级 4：features.json 有 passes=false → BUILD
```

判断后**明确告知用户**，用户可以纠正：

```
检测到：DESIGN 阶段（你提到"架构"、"设计"）
如果不对，用 :build 或其他 :指令 切换。
```

### 关键词映射

| 关键词（中英混合） | 推断阶段 |
|---------|----------|
| 需求、用户故事、用户说、requirement、user story | DISCOVER |
| 架构、设计、方案、UI、交互、选型、architecture、design | DESIGN |
| 规划、Sprint、任务拆解、优先级、plan、roadmap | PLAN |
| 实现、开发、写代码、feat、fix、build | BUILD |
| 测试、验证、回归、bug、test、verify | VERIFY |
| 发布、上线、部署、release、deploy、tag | RELEASE |
| 复盘、总结、retrospective、retro、回顾 | RETRO |

---

## 五、各阶段 Session 行为

### 5.1 DISCOVER（需求探索）

**Session 开始报告**：
```
## Session 开始 — DISCOVER 阶段

当前需求池：[backlog.md "待评估"区条目数量]
上次讨论：[最近一条 DISCOVER 类型的 _index 条目]

今天要探索/梳理什么需求？
```

**工作中行为**：
- 讨论内容直接进 backlog.md（不需要立即分解任务）
- 如果澄清了之前模糊的需求，更新 backlog.md 对应条目
- 涉及产品方向调整 → 同步更新 `product/vision.md`

**Session 结束**：
- 产出文件（如有）：`docs/requirements/YYYY-MM-DD-[主题].md`
- `_index.md` 条目类型：`DISCOVER`
- **不需要**更新 `features.json`

---

### 5.2 DESIGN（产品/技术设计）

**Session 开始报告**：
```
## Session 开始 — DESIGN 阶段

相关需求：[从 backlog 提取相关条目]
已有设计文档：[列出 docs/design/ 下相关文件]
待决策：[从 backlog 中 [设计] 标签条目]

今天要设计/决策什么？
```

**工作中行为**：
- 架构/方案选择 → 写入 `registry/decisions/YYYY-MM-DD.md`（ADR 格式）
- 产品设计（UI 流程、业务逻辑）→ 写入 `docs/design/[模块名].md`
- 不写代码，只做决策和文档

**Session 结束**：
- 产出文件：`docs/design/` 和/或 `registry/decisions/`
- `_index.md` 条目类型：`DECISION`
- **不需要**更新 `features.json`（DESIGN 阶段不产生可验证的功能）

---

### 5.3 PLAN（规划）

**Session 开始报告**：
```
## Session 开始 — PLAN 阶段

当前 Sprint：[current-sprint.md 阶段名]
backlog 待评估：[条目列表]
上个 Sprint 完成率：[features.json passes=true 比例]

今天要规划哪个阶段/功能集？
```

**工作中行为**：
- 草拟 Sprint 功能列表，列优先级和依赖关系
- 用户确认后：写入 `features.json`、更新 `current-sprint.md`
- 任务分解粒度：每个 feat 一次 Session 内能完成

**Session 结束**：
- 产出文件：`registry/decisions/sprint-N-plan.md`
- `_index.md` 条目类型：`DECISION`
- **必须**更新 `features.json` 和 `current-sprint.md`（这是 PLAN 阶段的核心产出）

---

### 5.4 BUILD（开发）— 维持当前行为

BUILD 分两种子模式，由用户指令或关键词自动区分。

#### 正常 BUILD（`:build`）

**Session 开始报告**：
```
## Session 开始 — BUILD 阶段

上次完成了：[_index.md 最新条目]
当前未完成功能：
- feat-xxx: 描述

建议本次做：feat-xxx（无依赖，优先级最高）

请确认：本次 Session 做什么？
```

**工作中行为**：同现有协议（Karpathy 准则、每完成一个 feat 立即 commit）

**Session 结束**：同现有协议（更新 features.json、写 session 摘要、git commit）

---

#### 快速修复（`:fix`）

适用场景：临时性小需求、发现的小 Bug、计划外的紧急改动——不需要预先规划，不新增 feat 条目。

**Session 开始**：
```
## Session 开始 — 快速修复

跳过规划。描述要修什么？
```

**工作中行为**：
- 直接开始，无需对照 features.json
- 遵守 Karpathy 准则（说清楚改哪里、为什么，再动手）
- 改完立即 commit（`fix: 描述`）

**Session 结束（极简）**：
- **不**写 session 摘要文件
- **不**更新 features.json
- 在 `_index.md` 最前面追加一行 `FIX` 条目即可：
  `[日期 时间] FIX 一句话描述 → commit abc1234`
- git commit `.harness/`（只含 _index.md 变更）

**自动触发条件**（无需用户明确输入 `:fix`）：
用户消息包含以下关键词时，Agent 自动识别为快速修复模式并告知用户：
- "顺手改一下"、"小改"、"临时"、"快速修一下"、"发现个问题"
- "这里有个 bug"、"顺便"、"简单改"

---

### 5.5 VERIFY（验证/测试）

**Session 开始报告**：
```
## Session 开始 — VERIFY 阶段

已完成功能（passes=true）：[列表]
上次验证结果：[最近 VERIFY 类型 _index 条目]

今天要验证哪些功能，还是排查哪个 Bug？
```

**工作中行为**：
- 跑测试、记录测试结果
- 发现 Bug → 写入 backlog.md（来源：[VERIFY]）或立即修复（进入 BUILD）
- 功能通过验收 → 可以在 `features.json` 中确认（不做到正式通过不改）

**Session 结束**：
- 产出：测试结果记录在 session 摘要
- `_index.md` 条目类型：`DONE`（验证通过）或 `BLOCKED`（有问题待修复）

---

### 5.6 RELEASE（发布）

**Session 开始报告**：
```
## Session 开始 — RELEASE 阶段

待发布功能：[passes=true 且未发布的条目]
上次发布：[最近 RELEASE 类型 _index 条目]

今天要发布 vX.Y.Z，还是准备发布清单？
```

**工作中行为**：
- 准备 release notes → `docs/releases/vX.Y.Z.md`
- 执行发布检查清单
- 打 git tag

**Session 结束**：
- `_index.md` 条目类型：`DONE`（发布完成）
- 更新 `current-sprint.md` 记录发布版本

---

### 5.7 RETRO（复盘）

**Session 开始报告**：
```
## Session 开始 — RETRO 阶段

本 Sprint 完成：[features.json passes=true 列表]
本 Sprint 未完成：[passes=false 列表]
耗时：[从 _index.md 推算首尾日期]

今天复盘哪个 Sprint？
```

**工作中行为**：
- 讨论什么做得好、什么做得差
- 提出改进行动项 → 写入 backlog.md（来源：[RETRO]）
- 如果发现 harness 协议本身的问题 → 提出修改建议到 backlog

**Session 结束**：
- 产出文件：`registry/decisions/retro-N.md`
- `_index.md` 条目类型：`DECISION`

---

## 六、状态文件变更

### current-sprint.md 新增字段

```markdown
**阶段**：第一阶段
**目标**：...
**完成标准**：...
**默认 Session 阶段**：BUILD        ← 新增，默认 BUILD
**当前版本**：v0.1.0                ← 新增，RELEASE 时更新
```

`默认 Session 阶段` 含义：
- Session 开始时，如果用户消息无关键词、无 `:指令`，使用此值作为初始判断
- 用户用 `:phase X` 明确切换后，Agent 更新此字段
- 这是项目级别的"大部分工作所在"，单次 Session 的临时切换不改变它

### features.json 无变化

features.json 保持现有结构，不新增字段。阶段信息只在 `current-sprint.md` 维护。

---

## 七、目录结构变更

```
项目根目录/
├── .harness/
│   ├── SESSION_START.md      ← 重写（支持多阶段）
│   ├── SESSION_END.md        ← 小幅更新（各阶段不同产出要求）
│   ├── state/
│   │   ├── current-sprint.md ← 新增 phase 字段
│   │   ├── features.json     ← 不变
│   │   └── constraints.md    ← 不变
│   ├── product/
│   │   ├── vision.md         ← 不变
│   │   └── backlog.md        ← 新增来源标签规范（[DISCOVER]/[RETRO]）
│   └── registry/
│       ├── _index.md         ← 新增 DISCOVER/DESIGN/VERIFY/RELEASE/RETRO 类型
│       ├── sessions/         ← 不变
│       └── decisions/        ← 新增 retro-N.md 格式
│
└── docs/                     ← 新增（项目级，放进 .gitignore 或保留由项目决定）
    ├── requirements/         ← DISCOVER 阶段产出
    ├── design/               ← DESIGN 阶段产出
    └── releases/             ← RELEASE 阶段产出
```

`docs/` 归属说明：
- 这是项目级别的目录，**不在** `.harness/` 内
- harness 负责建立惯例（Agent 知道往这里写），但不强制包含在 template 中
- install.sh 在初始化时创建 `docs/` 目录骨架（空目录 + .gitkeep）

---

## 八、SESSION_START.md 重写结构（伪代码）

```
第一步：读状态文件（与现在相同）

第二步：输出"第一屏"（用户说话前）
  → 显示：当前默认阶段、最近1条 _index 条目、简短提示
  → 结尾：开放式问题 "今天要做什么？（或用 :指令 明确阶段）"

第三步：用户回复后，判断阶段
  → 检查 :指令（优先级最高）
  → 检查关键词映射
  → 回退到 current-sprint.md 的默认阶段
  → 告知用户判断结果，提供纠正入口

第四步：执行对应阶段的"Session 开始报告"
  → 各阶段显示不同的上下文信息（见第五节）

第五步：明确复述目标，开始工作
```

---

## 九、SESSION_END.md 变更（最小化）

各阶段结束时，在"第三步写摘要"和"第四步更新 _index.md"中，
类型字段使用阶段对应的类型（不再限于 DONE/WIP/BLOCKED）：

| 阶段 | 允许的 _index 类型 |
|------|------------------|
| DISCOVER | `DISCOVER` |
| DESIGN | `DECISION` |
| PLAN | `DECISION` |
| BUILD | `DONE` / `WIP` / `BLOCKED` / `FIX` |
| VERIFY | `DONE` / `BLOCKED` |
| RELEASE | `DONE` |
| RETRO | `DECISION` |

`features.json` 更新步骤：在非 BUILD/VERIFY 阶段结束时跳过（这两个阶段才会改 passes）。

---

## 十、session-end-guard.sh 修复

**现象**：hook exit 2 正确，但 SESSION_END 清单未注入 Claude 上下文。
**原因**：hook stdout 是注入机制，需确认 Claude Code Stop hook 的 stdout 注入是否需要额外配置。

**待验证**：settings.json 的 Stop hook 是否需要加 `"additionalContext": true`。
（SessionStart hook 有此字段，Stop hook 缺失）

修复步骤（实现时确认）：
```json
"Stop": [{
  "hooks": [{
    "type": "command",
    "command": "bash .harness/hooks/session-end-guard.sh",
    "additionalContext": true,   ← 待测试
    "timeout": 10
  }]
}]
```

---

## 十一、实现计划

按依赖顺序，分 4 个 feat 实现：

| feat | 内容 | 依赖 | 预计改动文件 |
|------|------|------|-------------|
| feat-A | `current-sprint.md` 加 phase 字段；`_index.md` 类型扩展 | 无 | current-sprint.md |
| feat-B | `SESSION_START.md` 重写（两步法 + 7 种阶段报告） | feat-A | SESSION_START.md + template 副本 |
| feat-C | `SESSION_END.md` 小幅更新（阶段相关的跳过逻辑） | feat-B | SESSION_END.md + template 副本 |
| feat-D | `session-end-guard.sh` 修复 + install.sh 建 docs/ 骨架 | feat-C | hooks/session-end-guard.sh + install.sh + settings.json |

feat-A 和 feat-D 无强依赖，可以先做 feat-D（排查 Stop hook 问题）。

---

## 约束合规检查

| 约束 | 本设计是否遵守 |
|------|--------------|
| template/ 是唯一分发源 | ✅ SESSION_START.md 修改后同步 template/ 副本 |
| Hook 脚本只用 exit 0/2 | ✅ 不改 hook 脚本逻辑结构 |
| 不引入新运行时依赖 | ✅ 全部是 markdown + bash |
| features.json 只改 passes | ✅ |
| 支持多 AI 工具 | ✅ SESSION_START.md 是纯 markdown，与工具无关 |

---

## 十二、补丁：状态文件责任矩阵（2026-05-04）

### 背景

原设计实现后，发现三个遗漏：
1. `changes.md` 没有任何流程触发点，成为空文件
2. FIX 子模式跳过第零步（backlog 捕获），导致需求永久丢失
3. `current-sprint.md` 的功能状态栏与 `features.json` 重复，且无强制同步机制

### 修复原则

**每个状态文件必须有明确的"由谁写、什么时候必须写"，不允许"有则填"作为唯一触发。**

### 状态文件责任矩阵

| 状态文件 | 触发阶段 | 规则 |
|---------|---------|------|
| `backlog.md` | 所有阶段（含FIX） | 有新想法/反馈则填；DISCOVER/VERIFY/RETRO 结束时强制检查 |
| `changes.md` | PLAN、RETRO | PLAN 结束时检查有无取消/调整；RETRO 的方向性决定追加 |
| `features.json` | BUILD/VERIFY（更新passes）、PLAN（新增条目） | 强制 |
| `current-sprint.md` | PLAN（元数据）、RELEASE（版本号） | 只含 阶段/目标/完成标准/默认Session阶段/当前版本；无功能状态栏 |
| `_index.md` | 所有阶段 | 强制 |

### 具体改动

- `current-sprint.md`：删除"本阶段功能列表"状态表，新增"当前版本"字段
- `SESSION_END.md` 第五步：区分 BUILD/VERIFY/PLAN/RETRO 的差异处理，绑定 changes.md 触发
- `SESSION_END.md` FIX 子模式：加回第零步（backlog 捕获），不再完全跳过
- `SESSION_START.md` PLAN 报告：明确来源为 features.json，不再提 current-sprint.md 状态栏

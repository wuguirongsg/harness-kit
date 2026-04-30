# Harness Kit 版本记录

> 记录 harness-kit 自身的版本变更。
> 项目用户通过 `upgrade.sh` 从旧版本升级到新版本。

---

## [0.5.0] — 2026-04-30

### 新增
- **7 阶段生命周期支持**：SESSION_START.md 完整重写，支持 DISCOVER / DESIGN / PLAN / BUILD / VERIFY / RELEASE / RETRO 七个开发阶段
- **两步法 Session 开始**：第一屏只输出简短状态摘要等待用户说明意图，用户回复后再显示阶段对应的上下文，不再默认强推功能开发流程
- **`:指令` 语法**：用户可通过 `:build`、`:discover`、`:design`、`:plan`、`:verify`、`:release`、`:retro`、`:fix`、`:status`、`:help` 明确指定阶段；也支持关键词自动判断
- **`:fix` 快速修复子模式**：跳过规划直接描述问题，SESSION_END 极简（只更新 `_index.md` 一行，不创建摘要文件）
- `current-sprint.md` 新增 `默认 Session 阶段` 字段，记录项目当前所在阶段
- `docs/` 骨架目录（`requirements/` / `design/` / `releases/`）由 install.sh/bat 初始化时自动创建
- SESSION_END.md 明确：探索性会话（无产出）可跳过摘要文件，只更新 `_index.md` 即满足 guard 放行条件

### 变更
- `SESSION_END.md` 各阶段允许的 `_index.md` 条目类型不同（DISCOVER / DECISION / DONE / BLOCKED / FIX / RELEASE / RETRO）
- `SESSION_END.md` 非 BUILD/VERIFY 阶段跳过 `features.json` 更新步骤
- `_index.md` 类型说明改为单行 `>` blockquote 格式，修复 `session-start.sh` 过滤器误抓类型说明的 Bug
- `commit-msg` hook 新增 `discover`、`design`、`verify`、`release`、`retro` 提交类型
- Stop hook（`session-end-guard.sh`）加 `additionalContext: true`，尝试修复 SESSION_END 清单未注入 Claude 上下文的问题
- `session-end-guard.sh` FALLBACK 清单说明更新：非 BUILD/VERIFY 阶段跳过 features.json 步骤

### 升级方式
```bash
bash /path/to/harness-kit/upgrade.sh
```

升级后需手动在 `current-sprint.md` 添加一行：
```
**默认 Session 阶段**：BUILD
```

---

## [0.4.0] — 2026-04-27

### 新增
- `.cursor/rules/karpathy-guidelines.mdc` — Karpathy 编码行为准则（Cursor `alwaysApply: true`）
  - 编码前先思考：明确理解、列方案、选最简单的
  - 简洁优先：最少代码，不加推测性内容
  - 外科手术式修改：只改必须改的，清理自己制造的孤儿代码
  - 目标驱动执行：定义可验证的成功标准，循环验证
- `SESSION_START.md` 新增"编码前置原则"区块，每次 Session 加载时自动生效
- `SESSION_END.md` 新增验收自检清单（标 `passes=true` 前逐条确认）
- `HARNESS_SETUP.md` Q4 新增验收标准格式，features.json 模板新增 `acceptance` 字段

### 变更
- `install.sh` / `install.bat`：新安装时写入 `.cursor/rules/karpathy-guidelines.mdc`
- `upgrade.sh`：升级时自动替换 karpathy-guidelines.mdc（协议文件），备份 `.cursor/rules/`
- `upgrade.sh`：修复 commit-msg hook 升级仍用 heredoc 的问题，改为从 `.harness/hooks/commit-msg` 复制

### 升级方式
```bash
bash /path/to/harness-kit/upgrade.sh
```

旧版本升级后 Cursor 用户立即获得 Karpathy 行为准则。features.json 中可按需补充 `acceptance` 字段（可选，不影响现有条目）。

---

## [0.3.0] — 2026-04-25

### 新增
- `.harness/product/` 目录：需求管理层
  - `vision.md` — 项目愿景，产品方向北极星
  - `backlog.md` — 需求池，接收零散需求和用户反馈
  - `changes.md` — 变更日志，记录方向调整和需求取消
- `HARNESS_SETUP.md` 新增 Q0 / Q0.5 / Q0.75（愿景和边界问题）
- `SESSION_END.md` 新增第零步：捕获需求到 backlog
- `SESSION_START.md` 新增读取 vision.md / backlog.md
- `.harness/VERSION` 版本标记文件
- `upgrade.sh` 升级脚本，支持从旧版本平滑升级

### 变更
- `SESSION_START.md` Sprint 切换流程：Step 编号调整，新增 backlog 检查步骤

### 升级方式
```bash
bash /path/to/harness-kit/upgrade.sh
```

---

## [0.2.0] — 2026-04-23

### 新增
- OpenCode plugin（`.opencode/plugin/harness.ts`）
- Codex hooks（`.codex/hooks.json` + `.codex/config.toml`）
- `SESSION_START.md` Sprint 切换流程（场景 B）
- `SESSION_END.md` 情况 B（阶段切换文件更新）

### 变更
- `AGENTS.md` 模板：删除冗余的 Session 协议章节，只保留约束和坑
- README 定位重写：从"状态管理框架"改为"执行环境框架"
- `install.sh` 修复：commit-msg hook 改为内联写入，不再依赖外部文件

---

## [0.1.0] — 2026-04-21

### 初始版本
- `HARNESS_SETUP.md` — 一次性 AI 初始化协议
- `SESSION_START.md` — Session 开始检查清单
- `SESSION_END.md` — Session 结束总结清单
- `.harness/registry/` — 决策索引系统（_index.md / decisions/ / sessions/）
- `.harness/state/` — 状态文件（features.json / constraints.md / current-sprint.md）
- `.claude/settings.json` — Claude Code Hook 配置
- `.cursor/hooks.json` — Cursor Hook 配置
- `install.sh` — 一键安装脚本

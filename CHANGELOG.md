# Harness Kit 版本记录

> 记录 harness-kit 自身的版本变更。
> 项目用户通过 `upgrade.sh` 从旧版本升级到新版本。

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

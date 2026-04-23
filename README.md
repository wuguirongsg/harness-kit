# harness-kit

> AI Agent 跨 Session 状态管理框架。解决的核心问题：Agent 每次 Session 都失忆，历史决策和进度全部丢失。

---

## 核心思路

harness-kit 不是 AGENTS.md 生成器，而是一套 **Session 协议**，由三个文件驱动 Agent 的行为：

| 文件 | 时机 | 作用 |
|------|------|------|
| `HARNESS_SETUP.md` | 仅一次 | AI 扫描项目 + 问答初始化，生成所有状态文件 |
| `.harness/SESSION_START.md` | 每次开始 | 读取 registry 状态，向用户汇报，确认本次目标 |
| `.harness/SESSION_END.md` | 每次结束 | 提取决策，更新 registry，git commit |

搭配一套轻量的 **registry** 目录，作为 Agent 的"外部工作记忆"，解决跨 Session 失忆问题。

---

## 快速开始

### 第一步：下载 harness-kit

```bash
git clone https://github.com/yourname/harness-kit.git
# 或者直接下载 zip 解压
```

### 第二步：在你的项目里运行 install.sh

```bash
cd /path/to/your-project      # 先进入你自己的项目根目录
bash /path/to/harness-kit/install.sh
```

`install.sh` 会自动完成：

- 复制所有协议文件和 Hook 脚本到你的项目
- 设置 Hook 脚本的可执行权限（`chmod +x`）
- 生成 `CLAUDE.md` 和 `.cursorrules`（内容与 `AGENTS.md` 相同）
- 写入 `.claude/settings.json` Hook 配置（SessionStart / Stop / PreToolUse）
- 检测到 Codex 时写入 `.codex/hooks.json` 和 `.codex/config.toml`
- 检测到 OpenCode 时写入 `.opencode/plugin/harness-opencode-plugin.ts`

### 第三步：让 AI 初始化你的项目（只做一次）

根据你使用的工具：

```bash
# Claude Code
claude "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"

# Cursor：在 Chat 面板里输入
请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness

# Codex CLI
codex "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"

# OpenCode
opencode "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"
```

AI 会自动扫描项目（读 `Cargo.toml` / `package.json` / `go.mod` 等），然后**逐条问你 5 个问题**（只问 AI 自己发现不了的信息），最后生成所有状态文件。**完成后 `HARNESS_SETUP.md` 可以删除。**

### 第四步：开始每次 Session

```bash
cd your-project
claude        # 直接启动，不需要任何额外参数
```

`.claude/settings.json` 里配置了 `SessionStart` Hook，**Claude Code 启动时自动触发**，把 registry 最近记录、当前 Sprint 目标、未完成功能清单注入上下文。Claude 会主动向你汇报状态并等待确认，不需要手动叫它读任何文件。

### 第五步：结束每次 Session

```bash
# 直接退出：Ctrl+C 或输入 /exit
```

`Stop` Hook 自动拦截退出动作，检查今天是否完成了 SESSION_END。**如果没做，Claude 无法退出**，会被强制执行收尾清单（写 session 摘要、更新 registry 索引、更新 features.json、git commit）。全部完成后才放行退出。

---

## 强制执行机制

harness-kit 的约束不依赖 AI "记得去做"，而是通过 `.claude/settings.json` 的 Hook 系统机械执行：

| Hook | 触发时机 | 作用 |
|------|----------|------|
| `SessionStart` | 每次启动 Claude Code | 自动注入 registry、Sprint 状态、未完成功能清单 |
| `Stop` + `exit 2` | Claude 准备退出时 | 检查 SESSION_END 是否完成，未完成则强制拦截 |
| `PreToolUse` | 每次 Bash 命令执行前 | 拦截危险命令，校验 commit message 格式 |
| `PostToolUse` | 每次文件写入后（异步）| 校验 features.json 格式完整性 |

Cursor 用户：Hook 配置在 `.cursor/hooks.json`，`stop` 事件同样会拦截退出。

---

## 目录结构

初始化完成后，你的项目会多出以下结构（完全独立，不干扰原有代码）：

```
your-project/
  AGENTS.md                          ← AI 工具自动读取（极简，≤60 行）
  CLAUDE.md                          ← Claude Code 专用（同上）
  .cursorrules                       ← Cursor 专用（同上）
  HARNESS_SETUP.md                   ← 初始化完成后可删除
  .claude/
    settings.json                    ← Claude Code Hook 配置
  .cursor/
    hooks.json                       ← Cursor Hook 配置
  .codex/
    hooks.json                       ← Codex Hook 配置
    config.toml                      ← Codex 功能开关（启用 hooks）
  .opencode/
    plugin/
      harness-opencode-plugin.ts     ← OpenCode Plugin
  .harness/
    SESSION_START.md                 ← 每次开始前的检查清单
    SESSION_END.md                   ← 每次结束前的总结清单
    hooks/                           ← Hook 脚本（install.sh 自动设权限）
    registry/
      _index.md                      ← 决策索引（Agent 只读最近 5 条）
      decisions/                     ← 架构决策记录
      sessions/                      ← Session 摘要（由 Agent 自动写入）
    state/
      features.json                  ← 功能完成合约
      constraints.md                 ← 已知约束（持续增量追加）
      current-sprint.md              ← 当前阶段目标
```

---

## 迭代规划

每个 Sprint 结束后，在新 Session 里告诉 Claude：

```
第一阶段已经全部完成，请结合 docs/ 里的 PRD 规划第二阶段
```

Claude 会读取 `features.json`（全部 `passes: true`）和 `current-sprint.md`，自动理解阶段切换，向你确认新功能范围后写入状态文件。之后每次 Session 自动加载新阶段的状态，无需任何手动操作。

---

## 为什么不做 AGENTS.md 生成器

ETH Zurich 2026 年的研究（arXiv:2602.11988）发现：

- AI 自动生成的 AGENTS.md：成功率 **-3%**，推理成本 **+20%**
- 人工写的 AGENTS.md：成功率 **+4%**，但要求只写"AI 发现不了的信息"

原因：AI 生成的内容主要是复述代码里已有的文档，对 Agent 来说是噪音而不是信号。

harness-kit 的做法：用 `HARNESS_SETUP.md` 让 AI 自主扫描项目，只通过问答收集"AI 自己发现不了的信息"，写成极简的 AGENTS.md。真正的价值在于 registry + Session 协议带来的**状态连续性**。

---

## 支持的工具

| AI 工具 | 配置文件 | 强制执行方式 |
|---------|---------|-------------|
| Claude Code | `CLAUDE.md` + `.claude/settings.json` | ✓ 原生 Hook，全自动 |
| Cursor | `.cursorrules` + `.cursor/hooks.json` | ✓ 原生 Hook，全自动 |
| OpenCode | `AGENTS.md` + `.opencode/plugin/harness.ts` | ✓ Plugin 系统，全自动 |
| Codex CLI | `AGENTS.md` + `.codex/hooks.json` | ✓ 原生 Hook，全自动（需开启 `features.hooks=true`）|
| Windsurf | `AGENTS.md` | — 依赖 AGENTS.md 指令约束 |
| Aider | `AGENTS.md` | — 依赖 AGENTS.md 指令约束 |

Claude Code、Cursor、OpenCode、Codex 均支持生命周期 hook/plugin，SESSION_START 和 SESSION_END 完全自动执行。

> **Codex 注意**：hooks 功能目前处于开发阶段，默认关闭，需在 `.codex/config.toml` 里设置 `features.hooks = true` 启用。

---

## 许可证

MIT

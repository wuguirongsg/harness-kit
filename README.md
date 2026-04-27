# harness-kit

> AI Agent 执行环境框架。核心理念来自 Harness Engineering：**把约束写进环境，而不是靠 Prompt 叮嘱**——让 Agent 在长时间自主工作中持续可靠，而不是跑偏、反复犯错、或者做到一半宣布完成。

---

## 核心思路

使用 AI Agent 写代码时，三个最常见的问题：

- **跑偏**：没有持久约束，Agent 自行决策，悄悄积累架构债
- **失忆**：每次新 Session 从零开始，不知道上次做到哪里、踩过什么坑
- **自以为完成**：Agent 扫了一眼觉得"差不多了"，就宣布任务完成

harness-kit 的做法：不靠 Prompt 叮嘱，而是通过 **Hook 机械强制 + 外部状态文件**解决这三个问题。

两层结构：

| 层 | 组成 | 解决什么 |
|----|------|----------|
| 强制执行层 | Hook 系统（settings.json / plugin / hooks.json）| Agent 行为约束，不依赖 AI 是否记得 |
| 状态持久层 | `.harness/` registry + state 目录 | 跨 Session 保持决策、进度、约束记录 |

两层之间由三个协议文件串联：

| 文件 | 时机 | 作用 |
|------|------|------|
| `HARNESS_SETUP.md` | 仅一次 | AI 扫描项目 + 问答初始化，生成所有状态文件 |
| `.harness/SESSION_START.md` | 每次开始（Hook 自动触发）| 注入状态上下文，Agent 主动汇报并等待确认 |
| `.harness/SESSION_END.md` | 每次结束（Hook 强制拦截）| 提取决策、更新 registry、git commit |

---

## 快速开始

### 第一步：下载 harness-kit

```bash
git clone https://github.com/yourname/harness-kit.git
# 或者直接下载 zip 解压
```

### 第二步：在你的项目里运行安装脚本

**macOS / Linux**

```bash
bash /path/to/harness-kit/install.sh /path/to/your-project
```

也可以先 `cd` 到项目目录再不带参数运行：

```bash
cd /path/to/your-project
bash /path/to/harness-kit/install.sh
```

**Windows（PowerShell）**

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\harness-kit\install.ps1 C:\path\to\your-project
```

也可以先 `cd` 到项目目录再不带参数运行：

```powershell
cd C:\path\to\your-project
powershell -ExecutionPolicy Bypass -File C:\path\to\harness-kit\install.ps1
```

`install.sh` 会自动完成：

- 复制所有协议文件和 Hook 脚本到你的项目
- 设置 Hook 脚本的可执行权限（`chmod +x`）
- 生成 `CLAUDE.md` 和 `.cursorrules`（内容与 `AGENTS.md` 相同）
- 写入 `.claude/settings.json` Hook 配置（SessionStart / Stop / PreToolUse）
- 检测到 Codex 时写入 `.codex/hooks.json` 和 `.codex/config.toml`
- 检测到 OpenCode 时写入 `.opencode/plugin/harness-opencode-plugin.ts`

### 第三步：让 AI 初始化你的项目（只做一次）

```bash
# Claude Code
claude "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"

# Codex CLI
codex "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"

# OpenCode
opencode "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"

# Cursor：在 Chat 面板输入同样的内容
```

AI 会自动扫描项目（读 `Cargo.toml` / `package.json` / `go.mod` 等），然后**逐条问你 5 个问题**（只问 AI 自己发现不了的信息），最后生成所有状态文件。**完成后 `HARNESS_SETUP.md` 可以删除。**

### 第四步：开始每次 Session

```bash
claude        # 直接启动，不需要任何额外参数
```

`SessionStart` Hook 自动触发，把 registry 最近记录、当前 Sprint 目标、未完成功能清单注入上下文。Agent 会主动汇报状态并等待确认，不需要手动叫它读任何文件。

### 第五步：结束每次 Session

```bash
# 直接退出：Ctrl+C 或输入 /exit
```

`Stop` Hook 自动拦截，检查今天是否完成了 SESSION_END。**如果没做，Agent 无法退出**，被强制执行收尾清单（写摘要、更新 registry、更新 features.json、git commit）。全部完成才放行。

---

## 强制执行机制

harness-kit 的约束不依赖 AI "记得去做"，通过 Hook 系统机械执行：

| Hook | 触发时机 | 作用 |
|------|----------|------|
| `SessionStart` | 每次启动时 | 自动注入 registry、Sprint 状态、未完成功能 |
| `Stop` + `exit 2` | Agent 准备退出时 | SESSION_END 未完成则强制拦截 |
| `PreToolUse` | 每次 Bash 命令前 | 拦截危险命令，校验 commit message 格式 |
| `PostToolUse` | 每次文件写入后（异步）| 校验 features.json 格式完整性 |

---

## 目录结构

```
your-project/
  AGENTS.md                     ← 极简，≤60 行，只写 AI 发现不了的信息
  CLAUDE.md / .cursorrules      ← 同上，各工具自动读取
  .claude/settings.json         ← Claude Code Hook 配置
  .cursor/hooks.json            ← Cursor Hook 配置
  .codex/hooks.json             ← Codex Hook 配置
  .opencode/plugin/harness-opencode-plugin.ts   ← OpenCode Plugin
  .harness/
    SESSION_START.md            ← Hook 注入的检查清单
    SESSION_END.md              ← Hook 强制执行的总结清单
    hooks/                      ← Hook 脚本
    registry/
      _index.md                 ← 决策索引（Agent 只读最近 5 条）
      decisions/                ← 架构决策记录
      sessions/                 ← Session 摘要（Agent 自动写入）
    state/
      features.json             ← 功能完成合约（防止自以为完成）
      constraints.md            ← 已知约束（持续增量追加）
      current-sprint.md         ← 当前阶段目标
```

---

## 迭代规划

每个 Sprint 结束后，在新 Session 里说：

```
第一阶段已经全部完成，请结合 docs/ 里的 PRD 规划第二阶段
```

Agent 读取 `features.json`（全部 `passes: true`）和 `current-sprint.md`，自动理解阶段切换，向你确认新功能范围后写入状态文件。之后每次 Session 自动加载新阶段状态，无需手动操作。

---

## 需求管理

日常使用中，随时可以告诉 Agent：

```
把这个加到 backlog：我希望支持 PDF 导入
```

Agent 立即追加到 `.harness/product/backlog.md`，下次 Sprint 规划时自动纳入评估。

需求变更或方向调整时：

```
之前计划的 XX 功能不做了，原因是 YY
```

Agent 在 `.harness/product/changes.md` 记录变更，同时更新 `features.json` 对应条目，保留历史不删除。

---

## 升级 harness-kit

harness-kit 自身持续迭代。已安装旧版本的项目，运行以下命令升级：

```bash
# 先拉取最新版本
git pull  # 或重新下载 zip

# 在你的项目里运行升级脚本
cd your-project
bash /path/to/harness-kit/upgrade.sh
```

升级策略：
- 🔄 **自动替换**：SESSION_START/END、hooks 脚本、tool 配置文件
- 🔒 **永不覆盖**：`.harness/product/`、`.harness/state/`、`.harness/registry/`、`AGENTS.md`
- 📦 **自动备份**：升级前把当前协议文件备份到 `.harness/backup/v当前版本/`

查看版本变更历史：见 `CHANGELOG.md`。

---

## 为什么 AGENTS.md 要保持极简

ETH Zurich 2026 年的研究（arXiv:2602.11988）发现：

- AI 自动生成的 AGENTS.md：成功率 **-3%**，推理成本 **+20%**
- 人工写的 AGENTS.md：成功率 **+4%**，但要求只写"AI 发现不了的信息"

写多了反而是噪音。harness-kit 的 AGENTS.md 只写两件事：**不可推翻的架构约束**和**容易踩的坑**，其余全靠 Hook 机械执行和 registry 状态注入。

---

## 支持的工具

| AI 工具 | 强制执行方式 |
|---------|-------------|
| Claude Code | ✓ 原生 Hook（`.claude/settings.json`），全自动 |
| Cursor | ✓ 原生 Hook（`.cursor/hooks.json`），全自动 |
| OpenCode | ✓ Plugin 系统（`.opencode/plugin/harness-opencode-plugin.ts`），全自动 |
| Codex CLI | ✓ 原生 Hook（`.codex/hooks.json`），全自动（需开启 `features.hooks=true`）|
| Windsurf / Aider | — 依赖 AGENTS.md 指令，无机械强制 |

---

## 许可证

MIT

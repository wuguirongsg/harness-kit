# 决策索引

> **Agent 使用规则**：
> - Session 开始时：只读最近 5 条，了解近况
> - Session 结束时：在最前面追加新条目（不是末尾）
> - 不要读完整历史，用条目里的文件链接按需查阅

格式：`[日期 时间] [类型] 一句话摘要 → 详情文件`

> 类型：`DONE`完成 · `WIP`进行中 · `BLOCKED`阻塞 · `FIX`计划外修复 · `DECISION`决策 · `CONSTRAINT`约束 · `DISCOVER`需求探索 · `VERIFY`验证 · `RELEASE`发布 · `RETRO`复盘

---

<!-- 新条目追加到这里（上方） -->

[2026-06-03 21:00] RELEASE v0.5.2 打 tag 推送 GitHub，GitHub Actions 自动发布 npm（含 CRLF 修复 + .gitignore + session-end flag 本地化）

[2026-06-03 17:30] FIX upgrade.bat LF→CRLF + chcp 65001 修复 Windows CMD 执行崩溃；install.bat 同步加 chcp 65001；推送 Gitee+GitHub；npm publish v0.5.1 待完成（需先 npm login）

[2026-06-03 16:30] FIX 添加 .harness/.gitignore 排除 .session-end-flag，同步 template/，升版本 v0.5.1，推送 Gitee+GitHub，npm publish 待完成（需先 npm login）

[2026-06-03 今日] FIX session-end flag 改为项目本地路径（.harness/.session-end-flag），session-start 清残留 flag，SESSION_START 补 Stop Hook 说明 → commit a7e54b7

[2026-05-04 22:59] DONE session-end 三条路径统一（移除 dirty 检查）+ SESSION_END.md 按阶段重写 + OpenCode 去重改为内存标志 → sessions/2026-05-04-2259.md

[2026-05-04 14:00] DECISION 精简状态文件：删除 vision/constraints/changes 三个孤儿文件，内容合并到 backlog.md；SESSION_START 读取从6文件减至4个 → commit 5b59464

[2026-05-04 11:00] DECISION 状态文件责任矩阵重设计：current-sprint.md 去功能状态栏，changes.md 绑定 PLAN/RETRO，FIX 加回 backlog 捕获 → decisions/lifecycle-phase-design.md（十二节）

[2026-05-02 14:00] FIX SESSION_END.md 精简（224→43行），session-end.sh 加停止提示文案 → commit 待提交

[2026-05-02 13:00] FIX Stop hook flag 改为 $PWD hash 隔离，防多项目相互污染 → commit 4a4a4af

[2026-05-02 12:00] DONE Stop hook 恢复，用 harness dirty 检测触发 SESSION_END，多轮对话场景验证通过 → sessions/2026-05-02-1200.md

[2026-05-01 10:00] FIX 移除 Claude Code/Codex/Cursor Stop hook，session-start.sh 加遗漏检测，SESSION_END 改为下次补救机制 → commit 4be126c

[2026-04-30 11:00] FIX session-end-guard 增加纯问答快速放行（工作树干净则 exit 0） → commit c83d073

[2026-04-30 10:00] DONE lifecycle phase 改造完成（feat-006~009），SESSION_START两步法+7阶段+:fix，Stop hook修复 → sessions/2026-04-30-1000.md

[2026-04-30 09:00] DECISION lifecycle phase 完整设计文档完成，7阶段模型 + :指令语法 + 自动判断算法 → decisions/lifecycle-phase-design.md

[2026-04-29 11:00] DECISION harness 生命周期支持不足诊断 + lifecycle phase 改造方向设计 → sessions/2026-04-29-1100.md

[2026-04-27 16:00] DONE 修复 install.bat template源bug + .gitignore + HARNESS_SETUP初始化完成（vision/features/AGENTS/constraints全部填写），第一阶段 5 个功能定义完成 → sessions/2026-04-27-1600.md

[2026-04-27 14:00] DECISION 引入 template/ 目录，install.sh/upgrade.sh 唯一源改为 template/，消除 .harness/ 运行时状态污染模板内容的问题 → decisions/template-dir.md

[2026-04-27 12:00] FIX install.sh 修复（zsh兼容/目标路径参数/session隔离），新增 install.ps1，Windows支持评估结论：只做install.bat不做.cmd hooks → sessions/2026-04-27-1200.md

[2026-04-23 13:49] FIX 修复 install.sh 中 Codex/OpenCode 源文件名错误（致命 bug），更新 README 目录结构和初始化说明 → sessions/2026-04-23-1349.md

[初始化日期] DECISION 项目 harness 初始化，建立 Session 协议框架 → decisions/init.md

[2026-05-29 10:20] FIX CI smoke-test 三个 job 因 git identity 未配置导致 commit --allow-empty 失败（Ubuntu exit 128 / Windows exit 1），在 smoke-test.yml 所有 Create temp target project 步骤添加 git config user.email/user.name → commit 待推送

# harness-kit — Agent 工作规范

> 由 HARNESS_SETUP 生成。只包含 AI 自己推断不出来的信息。
> Session 开始/结束的行为由 Hook 系统强制执行，本文件不再重复。

---

## 不可推翻的约束

- template/ 是唯一分发源，install.sh/upgrade.sh 必须从 template/ 复制，**禁止**直接从 `.harness/` 复制
- .harness/ 下的运行时数据（sessions/、decisions/、state/）**绝不**打包分发给用户
- 所有 Hook 脚本必须通过 exit code 0/2 控制行为，不能靠 stdout 内容做逻辑判断
- 不引入 Node.js / Python 以外的运行时依赖（保持 install.sh 零额外依赖）
- features.json 的 passes 字段只能从 false 改为 true，禁止删除条目或修改 description

## 容易踩的坑

- 修改 SESSION_START.md / SESSION_END.md 或 hook 脚本后，**必须手动同步**更新 template/.harness/ 下的对应副本，否则 install.sh 分发的是旧版本
- install.bat 和 install.sh 是两条独立代码路径，修改一个**必须同步修改另一个**
- Hook 脚本里的 `2>/dev/null` 会静默吞掉错误，调试时先去掉它看真实报错
- session-end-guard.sh 用日期检测是否已完成 SESSION_END，同一天多次会话只会拦截第一次

## 状态文件位置

| 文件 | 说明 |
|------|------|
| `.harness/state/current-sprint.md` | 当前阶段目标 |
| `.harness/state/features.json` | 功能完成合约，passes 只能 false→true |
| `.harness/state/constraints.md` | 已知约束，发现新的立即追加 |
| `.harness/registry/_index.md` | 决策索引，每次 Session 读最近 5 条 |

# 初始化记录

**日期**：2026-04-27
**执行**：Harness 初始化 Agent（Sisyphus）

## 项目概况

- **项目名**：harness-kit-v2
- **技术栈**：Bash（Hook脚本 + 安装脚本）、TypeScript（OpenCode Plugin）、Batch（Windows安装）
- **目录结构**：template/（分发源）、.harness/（运行时状态）、.claude/.cursor/.codex/.opencode/（各工具Hook配置）
- **构建/测试**：无（待建立）
- **版本**：0.4.0

## 确认的约束

1. template/ 是唯一分发源，install.sh/upgrade.sh 必须从 template/ 复制
2. .harness/ 运行时数据（sessions/、decisions/、state/）绝不打包分发
3. 所有 Hook 脚本通过 exit code 0/2 控制行为
4. 不引入 Node.js / Python 以外的运行时依赖
5. features.json passes 只能 false→true，禁止删除条目
6. install.bat 和 install.sh 是独立代码路径，修改须同步
7. Hook 脚本 2>/dev/null 静默吞错，调试困难

## 已知风险

1. install.bat 之前直接从根目录 .harness/ 复制（已在本Session修复）
2. 无测试基础设施，Hook 脚本正确性完全依赖人工验证
3. Python3 是硬依赖，Hook 脚本无 fallback 机制
4. session-end-guard 用日期检测，同日多Session只拦截第一次
5. template/ 同步靠人工，无自动检查机制

## 第一阶段范围

5个功能：修复已知缺陷(feat-001✓)、Python3 fallback(feat-002)、HARNESS_SETUP(feat-003)、集成测试(feat-004)、template同步检查(feat-005)

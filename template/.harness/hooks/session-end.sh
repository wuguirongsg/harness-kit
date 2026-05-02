#!/usr/bin/env bash
# .harness/hooks/session-end.sh
# Claude Code Stop hook — 触发 SESSION_END 协议
# exit 0 = 允许停止；exit 2 = 阻断停止并将 stdout 注入为 additionalContext

HARNESS_DIR=".harness"

# 没有 .harness 目录 → 不是 harness 项目，放行
[ -d "$HARNESS_DIR" ] || exit 0

# 只在 Claude Code 环境中触发
[ "${CLAUDE_CODE_HOOKS:-}" = "1" ] || exit 0

# 检查 .harness/ 是否有未提交内容
# 有 = 本轮有实际工作未走完 SESSION_END → 触发
# 没有 = SESSION_END 已执行（已 commit）或纯问答 → 放行
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
harness_dirty=$(git status --porcelain -- "$HARNESS_DIR" 2>/dev/null)
[ -n "$harness_dirty" ] || exit 0

# 注入 SESSION_END 协议并阻断停止
if [ -f "$HARNESS_DIR/SESSION_END.md" ]; then
    cat "$HARNESS_DIR/SESSION_END.md"
else
    echo "## Session 结束提示"
    echo "SESSION_END.md 不存在，请手动完成 session 收尾工作。"
fi

exit 2

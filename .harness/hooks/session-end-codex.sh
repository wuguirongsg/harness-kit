#!/usr/bin/env bash
# .harness/hooks/session-end-codex.sh
# Codex Stop hook — 触发 SESSION_END 协议
# exit 0          = 允许停止
# stdout JSON     = 阻断停止，stopReason 注入为上下文

HARNESS_DIR=".harness"
PROJECT_HASH=$(printf '%s' "$PWD" | cksum | awk '{print $1}')
FLAG="/tmp/harness-session-end-${PROJECT_HASH}"

# 没有 .harness 目录 → 不是 harness 项目，放行
[ -d "$HARNESS_DIR" ] || exit 0

# 检查 .harness/ 是否有未提交内容
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
harness_dirty=$(git status --porcelain -- "$HARNESS_DIR" 2>/dev/null)
[ -n "$harness_dirty" ] || exit 0

# 注入 SESSION_END 协议并阻断停止
if [ -f "$HARNESS_DIR/SESSION_END.md" ]; then
    if [ -f "$FLAG" ]; then
        rm "$FLAG"
        exit 0
    fi
    touch "$FLAG"
    END_CONTENT=$(cat "$HARNESS_DIR/SESSION_END.md")
    python3 -c "
import json, sys
content = sys.argv[1]
print(json.dumps({'continue': False, 'stopReason': content}))
" "$END_CONTENT"
    exit 0
fi

exit 0

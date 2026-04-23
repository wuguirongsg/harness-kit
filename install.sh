#!/usr/bin/env bash
# install.sh
# 把 harness-kit-v2 的文件复制到当前项目，并设置权限

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

# 检查是否在项目根目录
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ]; then
    warn "当前目录似乎不是项目根目录，确认要在这里安装吗？[y/N]"
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] || exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 复制文件
cp -n "$SCRIPT_DIR/HARNESS_SETUP.md"    ./HARNESS_SETUP.md    2>/dev/null && success "HARNESS_SETUP.md" || warn "HARNESS_SETUP.md 已存在，跳过"
cp -n "$SCRIPT_DIR/AGENTS.md"           ./AGENTS.md           2>/dev/null && success "AGENTS.md" || warn "AGENTS.md 已存在，跳过"
cp -rn "$SCRIPT_DIR/.harness"           ./.harness            2>/dev/null && success ".harness/" || warn ".harness/ 已存在，跳过"
mkdir -p .claude .cursor
cp -n "$SCRIPT_DIR/.claude/settings.json"  ./.claude/settings.json  2>/dev/null && success ".claude/settings.json" || warn ".claude/settings.json 已存在，跳过"
cp -n "$SCRIPT_DIR/.cursor/hooks.json"     ./.cursor/hooks.json     2>/dev/null && success ".cursor/hooks.json" || warn ".cursor/hooks.json 已存在，跳过"

# 生成 CLAUDE.md 和 .cursorrules（与 AGENTS.md 同内容）
cp -n ./AGENTS.md ./CLAUDE.md    2>/dev/null && success "CLAUDE.md" || warn "CLAUDE.md 已存在，跳过"
cp -n ./AGENTS.md ./.cursorrules 2>/dev/null && success ".cursorrules" || warn ".cursorrules 已存在，跳过"

# 设置 hook 脚本可执行权限（关键步骤）
chmod +x .harness/hooks/*.sh
success "hook 脚本权限设置完成"

# 安装 git commit-msg hook（检查 commit message 格式）
if [ -d ".git" ]; then
    cat > .git/hooks/commit-msg << 'HOOK'
#!/bin/sh
MSG=$(cat "$1")
if ! echo "$MSG" | grep -qE "^(feat|fix|docs|refactor|test|chore|style|perf|session):"; then
  echo ""
  echo "⚠️  [harness] commit message 格式不符合规范"
  echo "    格式：<type>: <描述>"
  echo "    type 可选：feat / fix / docs / refactor / test / chore / style / perf / session"
  echo ""
  exit 1
fi
HOOK
    chmod +x .git/hooks/commit-msg
    success "git commit-msg hook 安装完成"
fi

# 安装 Codex hooks（如果已安装 codex）
if command -v codex &>/dev/null || [ -f ".codex/config.toml" ]; then
    mkdir -p .codex
    cp -n "$SCRIPT_DIR/.codex/codex-hooks.json"   .codex/hooks.json   2>/dev/null \
        && success "Codex hooks.json 安装完成" \
        || warn ".codex/hooks.json 已存在，跳过"
    cp -n "$SCRIPT_DIR/.codex/codex-config.toml"  .codex/config.toml  2>/dev/null \
        && success "Codex config.toml 安装完成" \
        || warn ".codex/config.toml 已存在，跳过"
fi

# 安装 OpenCode plugin（如果已安装 opencode）
if command -v opencode &>/dev/null || [ -f ".opencode/opencode.json" ]; then
    mkdir -p .opencode/plugin
    cp -n "$SCRIPT_DIR/.opencode/plugin/harness-opencode-plugin.ts" .opencode/plugin/harness-opencode-plugin.ts 2>/dev/null \
        && success "OpenCode plugin 安装完成（.opencode/plugin/harness-opencode-plugin.ts）" \
        || warn ".opencode/plugin/harness-opencode-plugin.ts 已存在，跳过"
fi

echo ""
echo "安装完成。下一步："
echo ""
echo "  claude \"请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness\""
echo ""

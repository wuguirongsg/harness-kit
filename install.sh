#!/usr/bin/env bash
# install.sh
# 把 harness-kit-v2 的文件复制到目标项目，并设置权限
#
# 用法：
#   bash install.sh                        # 安装到当前目录
#   bash install.sh /path/to/your-project  # 安装到指定目录
#
# TODO(feat-010): 中英文双语支持 — 预留 --lang 参数
#   bash install.sh --lang en                    # 英文版，安装到当前目录
#   bash install.sh --lang en /path/to/project   # 英文版，安装到指定目录
#   实现时从 template/locales/<lang>/ 覆盖对应协议文件；默认 zh（无需改动）
#   详见 docs/design/i18n-bilingual.md

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

command -v python3 >/dev/null || { echo "错误：需要 Python3，请先安装 python3（hooks 脚本依赖）"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
TMPL="$SCRIPT_DIR/template"

# 确定目标目录
if [ -n "$1" ]; then
    TARGET_DIR="$(cd "$1" && pwd)"
else
    TARGET_DIR="$(pwd)"
fi

# 检查目标目录是否像项目根目录
if [ ! -d "$TARGET_DIR/.git" ] && [ ! -f "$TARGET_DIR/package.json" ] && \
   [ ! -f "$TARGET_DIR/Cargo.toml" ] && [ ! -f "$TARGET_DIR/go.mod" ]; then
    warn "目标目录 $TARGET_DIR 似乎不是项目根目录，确认要在这里安装吗？[y/N]"
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] || exit 1
fi

echo "安装目标：$TARGET_DIR"
echo ""

# 复制协议文件
cp -n "$TMPL/HARNESS_SETUP.md" "$TARGET_DIR/HARNESS_SETUP.md" 2>/dev/null && success "HARNESS_SETUP.md" || warn "HARNESS_SETUP.md 已存在，跳过"
cp -n "$TMPL/AGENTS.md"        "$TARGET_DIR/AGENTS.md"        2>/dev/null && success "AGENTS.md" || warn "AGENTS.md 已存在，跳过"

# 复制 .harness 协议文件
mkdir -p "$TARGET_DIR/.harness"
cp -rn "$TMPL/.harness/SESSION_START.md" "$TARGET_DIR/.harness/SESSION_START.md" 2>/dev/null && success ".harness/SESSION_START.md" || warn ".harness/SESSION_START.md 已存在，跳过"
cp -rn "$TMPL/.harness/SESSION_END.md"   "$TARGET_DIR/.harness/SESSION_END.md"   2>/dev/null && success ".harness/SESSION_END.md" || warn ".harness/SESSION_END.md 已存在，跳过"
cp -rn "$TMPL/.harness/hooks"            "$TARGET_DIR/.harness/hooks"            2>/dev/null && success ".harness/hooks/" || warn ".harness/hooks/ 已存在，跳过"
cp -n  "$TMPL/.harness/gitignore"       "$TARGET_DIR/.harness/.gitignore"       2>/dev/null && success ".harness/.gitignore" || warn ".harness/.gitignore 已存在，跳过"

# 初始化 registry（使用干净模板，不携带 harness-kit 自身的历史记录）
mkdir -p "$TARGET_DIR/.harness/registry/sessions" "$TARGET_DIR/.harness/registry/decisions"
cp -n "$TMPL/.harness/registry/_index.md"          "$TARGET_DIR/.harness/registry/_index.md"          2>/dev/null && success ".harness/registry/_index.md" || warn ".harness/registry/_index.md 已存在，跳过"
cp -n "$TMPL/.harness/registry/decisions/init.md"  "$TARGET_DIR/.harness/registry/decisions/init.md"  2>/dev/null && success ".harness/registry/decisions/init.md" || warn ".harness/registry/decisions/init.md 已存在，跳过"

# 初始化 state 目录
mkdir -p "$TARGET_DIR/.harness/state"
cp -n "$TMPL/.harness/state/features.json"     "$TARGET_DIR/.harness/state/features.json"     2>/dev/null && success ".harness/state/features.json" || warn ".harness/state/features.json 已存在，跳过"
cp -n "$TMPL/.harness/state/current-sprint.md" "$TARGET_DIR/.harness/state/current-sprint.md" 2>/dev/null && success ".harness/state/current-sprint.md" || warn ".harness/state/current-sprint.md 已存在，跳过"

# 创建 product 目录（需求 + 产品方向 + 约束，统一在 backlog.md）
if [ ! -d "$TARGET_DIR/.harness/product" ]; then
    mkdir -p "$TARGET_DIR/.harness/product"
    cp "$TMPL/.harness/product/backlog.md" "$TARGET_DIR/.harness/product/backlog.md"
    success ".harness/product/ 需求管理目录"
fi

# 创建 docs/ 骨架（设计/需求/发布文档目录）
for doc_dir in requirements design releases; do
    if [ ! -d "$TARGET_DIR/docs/$doc_dir" ]; then
        mkdir -p "$TARGET_DIR/docs/$doc_dir"
        touch "$TARGET_DIR/docs/$doc_dir/.gitkeep"
    fi
done
success "docs/ 骨架创建完成（requirements/ design/ releases/）"

# 写入版本标记
HARNESS_VERSION=$(cat "$TMPL/.harness/VERSION" 2>/dev/null) || { warn "VERSION 文件缺失，使用 'unknown'"; HARNESS_VERSION="unknown"; }
echo "$HARNESS_VERSION" > "$TARGET_DIR/.harness/VERSION"
success "写入版本标记：$HARNESS_VERSION"

# 复制 Hook 配置
mkdir -p "$TARGET_DIR/.claude" "$TARGET_DIR/.cursor" "$TARGET_DIR/.cursor/rules"
cp -n "$TMPL/.claude/settings.json"  "$TARGET_DIR/.claude/settings.json"  2>/dev/null && success ".claude/settings.json" || warn ".claude/settings.json 已存在，跳过"
cp -n "$TMPL/.cursor/hooks.json"     "$TARGET_DIR/.cursor/hooks.json"     2>/dev/null && success ".cursor/hooks.json" || warn ".cursor/hooks.json 已存在，跳过"
cp -n "$TMPL/.cursor/rules/karpathy-guidelines.mdc" \
      "$TARGET_DIR/.cursor/rules/karpathy-guidelines.mdc" 2>/dev/null \
    && success ".cursor/rules/karpathy-guidelines.mdc" \
    || warn ".cursor/rules/karpathy-guidelines.mdc 已存在，跳过"

# 生成 CLAUDE.md 和 .cursorrules（与 AGENTS.md 同内容）
cp -n "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/CLAUDE.md"    2>/dev/null && success "CLAUDE.md" || warn "CLAUDE.md 已存在，跳过"
cp -n "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.cursorrules" 2>/dev/null && success ".cursorrules" || warn ".cursorrules 已存在，跳过"

# 设置 hook 脚本可执行权限
chmod +x "$TARGET_DIR/.harness/hooks/"*.sh
success "hook 脚本权限设置完成"

# 安装 git commit-msg hook
if [ -d "$TARGET_DIR/.git" ]; then
    cp "$TARGET_DIR/.harness/hooks/commit-msg" "$TARGET_DIR/.git/hooks/commit-msg"
    chmod +x "$TARGET_DIR/.git/hooks/commit-msg"
    success "git commit-msg hook 安装完成"
fi

# 安装 Codex hooks（如果已安装 codex）
if command -v codex &>/dev/null || [ -f "$TARGET_DIR/.codex/config.toml" ]; then
    mkdir -p "$TARGET_DIR/.codex"
    cp -n "$TMPL/.codex/codex-hooks.json"  "$TARGET_DIR/.codex/hooks.json"  2>/dev/null \
        && success "Codex hooks.json 安装完成" \
        || warn ".codex/hooks.json 已存在，跳过"
    cp -n "$TMPL/.codex/codex-config.toml" "$TARGET_DIR/.codex/config.toml" 2>/dev/null \
        && success "Codex config.toml 安装完成" \
        || warn ".codex/config.toml 已存在，跳过"
fi

# 安装 OpenCode plugin（如果已安装 opencode）
if command -v opencode &>/dev/null || [ -f "$TARGET_DIR/.opencode/opencode.json" ]; then
    mkdir -p "$TARGET_DIR/.opencode/plugin"
    cp -n "$TMPL/.opencode/plugin/harness-opencode-plugin.ts" \
          "$TARGET_DIR/.opencode/plugin/harness-opencode-plugin.ts" 2>/dev/null \
        && success "OpenCode plugin 安装完成（.opencode/plugin/harness-opencode-plugin.ts）" \
        || warn ".opencode/plugin/harness-opencode-plugin.ts 已存在，跳过"
fi

echo ""
echo "安装完成。下一步："
echo ""
echo "  claude \"请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness\""
echo ""

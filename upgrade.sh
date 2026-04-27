#!/usr/bin/env bash
# upgrade.sh — harness-kit 版本升级脚本
#
# 用法：
#   cd your-project
#   bash /path/to/harness-kit/upgrade.sh
#
# 升级策略：
#   🔄 协议文件（自动替换）：SESSION_START/END、hooks、tool configs
#   🔒 数据文件（永不覆盖）：product/、state/、registry/、AGENTS.md

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m';  RED='\033[0;31m'; NC='\033[0m'

info()    { echo -e "${BLUE}[upgrade]${NC} $1"; }
success() { echo -e "${GREEN}[upgrade]${NC} ✓ $1"; }
warn()    { echo -e "${YELLOW}[upgrade]${NC} ⚠ $1"; }
error()   { echo -e "${RED}[upgrade]${NC} ✗ $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR=".harness"
VERSION_FILE="$HARNESS_DIR/VERSION"
TARGET_VERSION=$(cat "$SCRIPT_DIR/$HARNESS_DIR/VERSION" 2>/dev/null) || error "harness-kit 源包缺少 VERSION 文件，请检查安装包完整性"

# ── 检查是否在项目目录 ─────────────────────────────────────────
[ -d "$HARNESS_DIR" ] || error "未找到 .harness/ 目录，请在已安装 harness-kit 的项目根目录下运行"

# ── 读取当前版本 ───────────────────────────────────────────────
CURRENT_VERSION="0.1.0"   # 旧版本没有 VERSION 文件，默认 0.1.0
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
fi

echo ""
echo "================================================"
echo "  Harness Kit 升级向导"
echo "  当前版本：$CURRENT_VERSION → 目标版本：$TARGET_VERSION"
echo "================================================"
echo ""

if [ "$CURRENT_VERSION" = "$TARGET_VERSION" ]; then
    success "已经是最新版本 ($TARGET_VERSION)，无需升级"
    exit 0
fi

# ── 列出本次升级内容 ──────────────────────────────────────────
info "本次升级内容（从 CHANGELOG.md）："
echo ""

# 提取目标版本的 changelog
if [ -f "$SCRIPT_DIR/CHANGELOG.md" ]; then
    CHANGELOG_SECTION=$(awk "/^## \[$TARGET_VERSION\]/,/^## \[/" "$SCRIPT_DIR/CHANGELOG.md" \
      | grep -v "^## \[" | head -20)
    if [ -n "$CHANGELOG_SECTION" ]; then
        echo "$CHANGELOG_SECTION"
    else
        echo "  未找到版本 $TARGET_VERSION 的 CHANGELOG 条目，请查看 CHANGELOG.md"
    fi
else
    echo "  请查看 CHANGELOG.md 了解详细变更"
fi

echo ""
read -rp "确认升级？[Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
[[ "$CONFIRM" =~ ^[Yy] ]] || { info "已取消"; exit 0; }
echo ""

# ── 备份当前协议文件 ───────────────────────────────────────────
BACKUP_DIR="$HARNESS_DIR/backup/v${CURRENT_VERSION}"
mkdir -p "$BACKUP_DIR"
info "备份当前协议文件到 $BACKUP_DIR ..."

# 只备份协议文件，不备份数据文件
[ -f "$HARNESS_DIR/SESSION_START.md" ] && cp "$HARNESS_DIR/SESSION_START.md" "$BACKUP_DIR/"
[ -f "$HARNESS_DIR/SESSION_END.md"   ] && cp "$HARNESS_DIR/SESSION_END.md"   "$BACKUP_DIR/"
[ -d "$HARNESS_DIR/hooks" ]            && cp -r "$HARNESS_DIR/hooks"          "$BACKUP_DIR/"
[ -f ".claude/settings.json" ]         && cp ".claude/settings.json"          "$BACKUP_DIR/claude-settings.json"
[ -f ".cursor/hooks.json" ]            && cp ".cursor/hooks.json"             "$BACKUP_DIR/cursor-hooks.json"
[ -d ".cursor/rules" ]                 && cp -r ".cursor/rules"               "$BACKUP_DIR/cursor-rules"
[ -f ".codex/hooks.json" ]             && cp ".codex/hooks.json"              "$BACKUP_DIR/codex-hooks.json"
success "备份完成"

# ── 数据文件保护检查 ──────────────────────────────────────────
PROTECTED=(
    "$HARNESS_DIR/product"
    "$HARNESS_DIR/state"
    "$HARNESS_DIR/registry"
    "AGENTS.md"
    "CLAUDE.md"
)
info "保护数据文件（以下文件不会被覆盖）："
for p in "${PROTECTED[@]}"; do
    [ -e "$p" ] && echo "  🔒 $p"
done
echo ""


# ── 替换协议文件 ──────────────────────────────────────────────
info "升级协议文件..."

# SESSION_START / SESSION_END
cp "$SCRIPT_DIR/$HARNESS_DIR/SESSION_START.md" "$HARNESS_DIR/SESSION_START.md"
success "SESSION_START.md"

cp "$SCRIPT_DIR/$HARNESS_DIR/SESSION_END.md" "$HARNESS_DIR/SESSION_END.md"
success "SESSION_END.md"

# hooks 脚本
cp -r "$SCRIPT_DIR/$HARNESS_DIR/hooks/." "$HARNESS_DIR/hooks/"
chmod +x "$HARNESS_DIR/hooks/"*.sh
success "hooks/ 脚本"

# Tool 配置（Claude / Cursor / Codex）
mkdir -p .claude .cursor .cursor/rules .codex
cp "$SCRIPT_DIR/.claude/settings.json"  ".claude/settings.json"
success ".claude/settings.json"
cp "$SCRIPT_DIR/.cursor/hooks.json"     ".cursor/hooks.json"
success ".cursor/hooks.json"
cp "$SCRIPT_DIR/.cursor/rules/karpathy-guidelines.mdc" ".cursor/rules/karpathy-guidelines.mdc"
success ".cursor/rules/karpathy-guidelines.mdc"

if [ -f "$SCRIPT_DIR/.codex/hooks.json" ]; then
    cp "$SCRIPT_DIR/.codex/hooks.json"  ".codex/hooks.json"
    cp "$SCRIPT_DIR/.codex/codex-config.toml" ".codex/codex-config.toml" 2>/dev/null || true
    success ".codex/hooks.json"
fi

# OpenCode plugin
if [ -f "$SCRIPT_DIR/.opencode/plugin/harness-opencode-plugin.ts" ]; then
    mkdir -p .opencode/plugin
    cp "$SCRIPT_DIR/.opencode/plugin/harness-opencode-plugin.ts" ".opencode/plugin/harness-opencode-plugin.ts"
    success ".opencode/plugin/harness-opencode-plugin.ts"
fi

# ── 新版本新增的目录和文件（只创建，不覆盖）────────────────────
info "检查新增目录和文件..."

# 0.3.0 新增：.harness/product/
if [ ! -d "$HARNESS_DIR/product" ]; then
    mkdir -p "$HARNESS_DIR/product"
    cp "$SCRIPT_DIR/$HARNESS_DIR/product/vision.md"  "$HARNESS_DIR/product/vision.md"
    cp "$SCRIPT_DIR/$HARNESS_DIR/product/backlog.md" "$HARNESS_DIR/product/backlog.md"
    cp "$SCRIPT_DIR/$HARNESS_DIR/product/changes.md" "$HARNESS_DIR/product/changes.md"
    success ".harness/product/ 目录（新增）"
else
    warn ".harness/product/ 已存在，跳过（数据文件受保护）"
fi

# git commit-msg hook（从 .harness/hooks/commit-msg 写入最新版本）
if [ -d ".git" ]; then
    cp "$HARNESS_DIR/hooks/commit-msg" ".git/hooks/commit-msg"
    chmod +x ".git/hooks/commit-msg"
    success "git commit-msg hook"
fi


# ── 更新 VERSION 文件 ─────────────────────────────────────────
echo "$TARGET_VERSION" > "$VERSION_FILE"
success "VERSION → $TARGET_VERSION"

# ── git commit ────────────────────────────────────────────────
if [ -d ".git" ]; then
    read -rp "是否 git commit 本次升级？[Y/n]: " DO_COMMIT
    DO_COMMIT="${DO_COMMIT:-Y}"
    if [[ "$DO_COMMIT" =~ ^[Yy] ]]; then
        git add \
            "$HARNESS_DIR/SESSION_START.md" \
            "$HARNESS_DIR/SESSION_END.md" \
            "$HARNESS_DIR/hooks/" \
            "$HARNESS_DIR/VERSION" \
            ".claude/" ".cursor/" ".cursor/rules/" \
            2>/dev/null || true
        [ -d "$HARNESS_DIR/product" ] && git add "$HARNESS_DIR/product/" 2>/dev/null || true
        [ -d ".codex" ]  && git add ".codex/"  2>/dev/null || true
        [ -d ".opencode" ] && git add ".opencode/" 2>/dev/null || true
        git commit -m "chore: 升级 harness-kit $CURRENT_VERSION → $TARGET_VERSION" 2>/dev/null \
            && success "git commit 完成" \
            || warn "commit 失败（可能没有变更），请手动处理"
    fi
fi

# ── 完成 ──────────────────────────────────────────────────────
echo ""
echo "================================================"
echo -e "  ${GREEN}✓ 升级完成：$CURRENT_VERSION → $TARGET_VERSION${NC}"
echo "================================================"
echo ""
echo "协议文件已更新，你的数据文件完好无损："
echo "  🔒 .harness/product/   — 需求和愿景（已保护）"
echo "  🔒 .harness/state/     — Sprint 状态（已保护）"
echo "  🔒 .harness/registry/  — 决策历史（已保护）"
echo "  🔒 AGENTS.md / CLAUDE.md — 项目规范（已保护）"
echo ""
echo "备份位置：$BACKUP_DIR"
echo ""

# 版本专项提示：用 awk 做语义版本比较，避免 bash [[ ]] 不支持 >= 的问题
version_lt() { [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ] && [ "$1" != "$2" ]; }
version_ge() { ! version_lt "$1" "$2"; }

# 0.3.0 专项提示
if version_lt "$CURRENT_VERSION" "0.3.0" && version_ge "$TARGET_VERSION" "0.3.0"; then
    echo "📌 0.3.0 新增需求管理层，建议："
    echo "   1. 打开 .harness/product/vision.md，填写项目愿景"
    echo "   2. 把积压的需求整理到 .harness/product/backlog.md"
    echo "   3. 下次 Session 时 Agent 会自动读取这两个文件"
    echo ""
fi

# 0.4.0 专项提示
if version_lt "$CURRENT_VERSION" "0.4.0" && version_ge "$TARGET_VERSION" "0.4.0"; then
    echo "📌 0.4.0 新增 Karpathy 编码行为准则，建议："
    echo "   1. Cursor 用户：已自动写入 .cursor/rules/karpathy-guidelines.mdc"
    echo "      （alwaysApply: true，无需额外操作）"
    echo "   2. 可选：在 features.json 的功能条目里补充 acceptance 字段"
    echo "      格式：\"acceptance\": \"验收标准：用一句话描述如何判断此功能已完成\""
    echo "   3. SESSION_START / SESSION_END 已更新编码准则和验收自检，"
    echo "      下次 Session 自动生效"
    echo ""
fi

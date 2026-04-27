#!/usr/bin/env bash
# upgrade.sh — harness-kit 修复 & 更新脚本
#
# 用法：
#   cd your-project
#   bash /path/to/harness-kit/upgrade.sh
#
# 策略：
#   🔄 协议文件（无条件替换）：SESSION_START/END、hooks、tool configs
#   🆕 数据目录（只创建不覆盖）：product/、state/、registry/（缺失时自动修复）
#   🔒 数据内容（永不触碰）：product/*.md、state/*、registry/*、AGENTS.md

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m';  RED='\033[0;31m'; NC='\033[0m'

info()    { echo -e "${BLUE}[harness]${NC} $1"; }
success() { echo -e "${GREEN}[harness]${NC} ✓ $1"; }
warn()    { echo -e "${YELLOW}[harness]${NC} ⚠ $1"; }
error()   { echo -e "${RED}[harness]${NC} ✗ $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR=".harness"
TARGET_VERSION=$(cat "$SCRIPT_DIR/$HARNESS_DIR/VERSION" 2>/dev/null) \
    || error "harness-kit 源包缺少 VERSION 文件，请检查安装包完整性"

# ── 检查是否在项目目录（宽松检查，支持 .harness/ 已被误删的情况）───
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "Cargo.toml" ] && \
   [ ! -f "go.mod" ] && [ ! -f "pyproject.toml" ] && [ ! -d "$HARNESS_DIR" ]; then
    error "未找到项目标识（.git、package.json 等），请在项目根目录下运行"
fi

# ── 读取当前版本（仅用于展示，不影响后续逻辑）────────────────────
CURRENT_VERSION="未知"
if [ -f "$HARNESS_DIR/VERSION" ]; then
    CURRENT_VERSION=$(tr -d '[:space:]' < "$HARNESS_DIR/VERSION")
fi

echo ""
echo "================================================"
echo "  Harness Kit 修复 & 更新"
echo "  当前版本：$CURRENT_VERSION  →  目标版本：$TARGET_VERSION"
echo "================================================"
echo ""
info "将无条件更新所有协议文件至 $TARGET_VERSION"
info "你的数据文件（product/、state/、registry/、AGENTS.md）不会被修改"
echo ""

# ── 显示最新版本的 CHANGELOG ──────────────────────────────────────
if [ -f "$SCRIPT_DIR/CHANGELOG.md" ]; then
    info "最新版本内容（$TARGET_VERSION）："
    echo ""
    awk -v ver="$TARGET_VERSION" '
        $0 ~ ("^## \\[" ver "\\]") { in_section=1; next }
        in_section && /^## \[/     { exit }
        in_section                  { print }
    ' "$SCRIPT_DIR/CHANGELOG.md" || true
    echo ""
fi

read -rp "确认执行？[Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
[[ "$CONFIRM" =~ ^[Yy] ]] || { info "已取消"; exit 0; }
echo ""

# ── 备份现有协议文件（按时间戳，支持多次运行不互相覆盖）────────────
BACKUP_DIR="$HARNESS_DIR/backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
info "备份现有协议文件 → $BACKUP_DIR"
[ -f "$HARNESS_DIR/SESSION_START.md" ] && cp "$HARNESS_DIR/SESSION_START.md" "$BACKUP_DIR/"
[ -f "$HARNESS_DIR/SESSION_END.md"   ] && cp "$HARNESS_DIR/SESSION_END.md"   "$BACKUP_DIR/"
[ -d "$HARNESS_DIR/hooks" ]            && cp -r "$HARNESS_DIR/hooks"          "$BACKUP_DIR/"
[ -f ".claude/settings.json" ]         && cp ".claude/settings.json"          "$BACKUP_DIR/claude-settings.json"
[ -f ".cursor/hooks.json" ]            && cp ".cursor/hooks.json"             "$BACKUP_DIR/cursor-hooks.json"
[ -d ".cursor/rules" ]                 && cp -r ".cursor/rules"               "$BACKUP_DIR/cursor-rules"
[ -f ".codex/hooks.json" ]             && cp ".codex/hooks.json"              "$BACKUP_DIR/codex-hooks.json"
success "备份完成"
echo ""

# ── 无条件替换所有协议文件 ────────────────────────────────────────
info "更新协议文件..."
mkdir -p "$HARNESS_DIR/hooks"

cp "$SCRIPT_DIR/$HARNESS_DIR/SESSION_START.md" "$HARNESS_DIR/SESSION_START.md"
success "SESSION_START.md"

cp "$SCRIPT_DIR/$HARNESS_DIR/SESSION_END.md" "$HARNESS_DIR/SESSION_END.md"
success "SESSION_END.md"

cp -r "$SCRIPT_DIR/$HARNESS_DIR/hooks/." "$HARNESS_DIR/hooks/"
chmod +x "$HARNESS_DIR/hooks/"*.sh
success "hooks/"

cp "$SCRIPT_DIR/HARNESS_SETUP.md" "HARNESS_SETUP.md"
success "HARNESS_SETUP.md"

mkdir -p .claude .cursor .cursor/rules
cp "$SCRIPT_DIR/.claude/settings.json"  ".claude/settings.json"
success ".claude/settings.json"
cp "$SCRIPT_DIR/.cursor/hooks.json"     ".cursor/hooks.json"
success ".cursor/hooks.json"
cp "$SCRIPT_DIR/.cursor/rules/karpathy-guidelines.mdc" ".cursor/rules/karpathy-guidelines.mdc"
success ".cursor/rules/karpathy-guidelines.mdc"

if [ -f "$SCRIPT_DIR/.codex/codex-hooks.json" ]; then
    mkdir -p .codex
    cp "$SCRIPT_DIR/.codex/codex-hooks.json"   ".codex/hooks.json"
    cp "$SCRIPT_DIR/.codex/codex-config.toml"  ".codex/config.toml" 2>/dev/null || true
    success ".codex/hooks.json"
fi

if [ -f "$SCRIPT_DIR/.opencode/plugin/harness-opencode-plugin.ts" ]; then
    mkdir -p .opencode/plugin
    cp "$SCRIPT_DIR/.opencode/plugin/harness-opencode-plugin.ts" \
       ".opencode/plugin/harness-opencode-plugin.ts"
    success ".opencode/plugin/harness-opencode-plugin.ts"
fi

if [ -d ".git" ]; then
    mkdir -p .git/hooks
    cp "$HARNESS_DIR/hooks/commit-msg" ".git/hooks/commit-msg"
    chmod +x ".git/hooks/commit-msg"
    success "git commit-msg hook"
fi

echo ""

# ── 修复缺失的数据目录（只创建，绝不覆盖已有内容）────────────────
info "检查并修复缺失的数据目录..."

mkdir -p "$HARNESS_DIR/registry/sessions" "$HARNESS_DIR/registry/decisions"
mkdir -p "$HARNESS_DIR/state"

_create_if_missing() {
    local src="$1" dst="$2" label="$3"
    if [ ! -e "$dst" ]; then
        cp "$src" "$dst"
        success "$label（已修复）"
    fi
}

_create_if_missing \
    "$SCRIPT_DIR/$HARNESS_DIR/registry/_index.md" \
    "$HARNESS_DIR/registry/_index.md" \
    ".harness/registry/_index.md"

if [ ! -d "$HARNESS_DIR/product" ]; then
    mkdir -p "$HARNESS_DIR/product"
    cp "$SCRIPT_DIR/$HARNESS_DIR/product/vision.md"  "$HARNESS_DIR/product/vision.md"
    cp "$SCRIPT_DIR/$HARNESS_DIR/product/backlog.md" "$HARNESS_DIR/product/backlog.md"
    cp "$SCRIPT_DIR/$HARNESS_DIR/product/changes.md" "$HARNESS_DIR/product/changes.md"
    success ".harness/product/（已修复）"
fi

_create_if_missing \
    "$SCRIPT_DIR/$HARNESS_DIR/state/features.json" \
    "$HARNESS_DIR/state/features.json" \
    ".harness/state/features.json"

_create_if_missing \
    "$SCRIPT_DIR/$HARNESS_DIR/state/current-sprint.md" \
    "$HARNESS_DIR/state/current-sprint.md" \
    ".harness/state/current-sprint.md"

_create_if_missing \
    "$SCRIPT_DIR/$HARNESS_DIR/state/constraints.md" \
    "$HARNESS_DIR/state/constraints.md" \
    ".harness/state/constraints.md"

echo ""

# ── 更新 VERSION ──────────────────────────────────────────────────
echo "$TARGET_VERSION" > "$HARNESS_DIR/VERSION"
success "VERSION → $TARGET_VERSION"
echo ""

# ── git commit ────────────────────────────────────────────────────
if [ -d ".git" ]; then
    read -rp "是否 git commit 本次更新？[Y/n]: " DO_COMMIT
    DO_COMMIT="${DO_COMMIT:-Y}"
    if [[ "$DO_COMMIT" =~ ^[Yy] ]]; then
        git add \
            "$HARNESS_DIR/SESSION_START.md" \
            "$HARNESS_DIR/SESSION_END.md" \
            "$HARNESS_DIR/hooks/" \
            "$HARNESS_DIR/VERSION" \
            "HARNESS_SETUP.md" \
            ".claude/" ".cursor/" \
            2>/dev/null || true
        [ -d "$HARNESS_DIR/product"  ] && git add "$HARNESS_DIR/product/"  2>/dev/null || true
        [ -d "$HARNESS_DIR/state"    ] && git add "$HARNESS_DIR/state/"    2>/dev/null || true
        [ -d "$HARNESS_DIR/registry" ] && git add "$HARNESS_DIR/registry/" 2>/dev/null || true
        [ -d ".codex"    ] && git add ".codex/"    2>/dev/null || true
        [ -d ".opencode" ] && git add ".opencode/" 2>/dev/null || true
        git commit -m "chore: 更新 harness-kit 至 $TARGET_VERSION" 2>/dev/null \
            && success "git commit 完成" \
            || warn "没有需要提交的变更"
    fi
fi

# ── 完成 ──────────────────────────────────────────────────────────
echo ""
echo "================================================"
echo -e "  ${GREEN}✓ 完成 → $TARGET_VERSION${NC}"
echo "================================================"
echo ""
echo "  🔄 已更新：协议文件（SESSION_START/END、hooks、tool configs）"
echo "  🔒 未修改：product/、state/、registry/、AGENTS.md"
echo "  📦 备份于：$BACKUP_DIR"
echo ""

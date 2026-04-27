# install.ps1
# 把 harness-kit-v2 的文件复制到目标项目
#
# 用法：
#   .\install.ps1                              # 安装到当前目录
#   .\install.ps1 C:\path\to\your-project      # 安装到指定目录
#
# 如遇执行策略报错，用：
#   powershell -ExecutionPolicy Bypass -File install.ps1

param(
    [string]$TargetPath = ""
)

$ErrorActionPreference = "Stop"

function success($msg) { Write-Host "v $msg" -ForegroundColor Green }
function warn($msg)    { Write-Host "! $msg" -ForegroundColor Yellow }

$ScriptDir = $PSScriptRoot

# 确定目标目录
if ($TargetPath -ne "") {
    $TargetDir = (Resolve-Path $TargetPath).Path
} else {
    $TargetDir = (Get-Location).Path
}

# 检查目标目录是否像项目根目录
$looksLikeProject = (Test-Path "$TargetDir\.git")         -or
                    (Test-Path "$TargetDir\package.json") -or
                    (Test-Path "$TargetDir\Cargo.toml")   -or
                    (Test-Path "$TargetDir\go.mod")

if (-not $looksLikeProject) {
    warn "目标目录 $TargetDir 似乎不是项目根目录，确认要在这里安装吗？[y/N]"
    $confirm = Read-Host
    if ($confirm -notmatch "^[Yy]") { exit 1 }
}

Write-Host "安装目标：$TargetDir"
Write-Host ""

# 辅助：复制单个文件，已存在则跳过
function Copy-IfNew($src, $dst) {
    $name = Split-Path $dst -Leaf
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    if (-not (Test-Path $dst)) {
        Copy-Item $src $dst
        success $name
    } else {
        warn "$name 已存在，跳过"
    }
}

# 辅助：递归复制目录，已存在则跳过
function Copy-DirIfNew($src, $dst) {
    $name = Split-Path $dst -Leaf
    if (-not (Test-Path $dst)) {
        Copy-Item $src $dst -Recurse
        success "${name}/"
    } else {
        warn "${name}/ 已存在，跳过"
    }
}

# 协议文件
Copy-IfNew "$ScriptDir\HARNESS_SETUP.md" "$TargetDir\HARNESS_SETUP.md"
Copy-IfNew "$ScriptDir\AGENTS.md"        "$TargetDir\AGENTS.md"

# .harness 模板（排除本项目自身的 session 记录）
foreach ($dir in @(
    "$TargetDir\.harness\registry\sessions",
    "$TargetDir\.harness\registry\decisions",
    "$TargetDir\.harness\state"
)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Copy-IfNew    "$ScriptDir\.harness\SESSION_START.md"      "$TargetDir\.harness\SESSION_START.md"
Copy-IfNew    "$ScriptDir\.harness\SESSION_END.md"        "$TargetDir\.harness\SESSION_END.md"
Copy-DirIfNew "$ScriptDir\.harness\hooks"                 "$TargetDir\.harness\hooks"
Copy-IfNew    "$ScriptDir\.harness\registry\_index.md"    "$TargetDir\.harness\registry\_index.md"

# Hook 配置
Copy-IfNew "$ScriptDir\.claude\settings.json" "$TargetDir\.claude\settings.json"
Copy-IfNew "$ScriptDir\.cursor\hooks.json"    "$TargetDir\.cursor\hooks.json"

# CLAUDE.md 和 .cursorrules（与 AGENTS.md 同内容）
$agentsContent = Get-Content "$TargetDir\AGENTS.md" -Raw
if (-not (Test-Path "$TargetDir\CLAUDE.md")) {
    Set-Content "$TargetDir\CLAUDE.md" $agentsContent -NoNewline
    success "CLAUDE.md"
} else {
    warn "CLAUDE.md 已存在，跳过"
}
if (-not (Test-Path "$TargetDir\.cursorrules")) {
    Set-Content "$TargetDir\.cursorrules" $agentsContent -NoNewline
    success ".cursorrules"
} else {
    warn ".cursorrules 已存在，跳过"
}

# Windows 不需要 chmod，跳过
success "（Windows 无需设置脚本权限）"

# git commit-msg hook（Git for Windows 提供 sh 环境，hook 脚本正常生效）
if (Test-Path "$TargetDir\.git") {
    $hookPath = "$TargetDir\.git\hooks\commit-msg"
    if (-not (Test-Path $hookPath)) {
        $hookDir = Split-Path $hookPath -Parent
        if (-not (Test-Path $hookDir)) {
            New-Item -ItemType Directory -Path $hookDir -Force | Out-Null
        }
        # 用 Unix 换行符写入，确保 sh 能正确解析
        $hookContent = "#!/bin/sh`nMSG=`$(cat `"`$1`")`nif ! echo `"`$MSG`" | grep -qE `"^(feat|fix|docs|refactor|test|chore|style|perf|session):`"; then`n  echo `"`"`n  echo `"⚠️  [harness] commit message 格式不符合规范`"`n  echo `"    格式：<type>: <描述>`"`n  echo `"    type 可选：feat / fix / docs / refactor / test / chore / style / perf / session`"`n  echo `"`"`n  exit 1`nfi`n"
        [System.IO.File]::WriteAllText($hookPath, $hookContent, [System.Text.Encoding]::UTF8)
        success "git commit-msg hook 安装完成"
    } else {
        warn "git commit-msg hook 已存在，跳过"
    }
}

# Codex hooks
$codexExists = ($null -ne (Get-Command codex -ErrorAction SilentlyContinue)) -or
               (Test-Path "$TargetDir\.codex\config.toml")
if ($codexExists) {
    New-Item -ItemType Directory -Path "$TargetDir\.codex" -Force | Out-Null
    Copy-IfNew "$ScriptDir\.codex\codex-hooks.json"  "$TargetDir\.codex\hooks.json"
    Copy-IfNew "$ScriptDir\.codex\codex-config.toml" "$TargetDir\.codex\config.toml"
}

# OpenCode plugin
$opencodeExists = ($null -ne (Get-Command opencode -ErrorAction SilentlyContinue)) -or
                  (Test-Path "$TargetDir\.opencode\opencode.json")
if ($opencodeExists) {
    New-Item -ItemType Directory -Path "$TargetDir\.opencode\plugin" -Force | Out-Null
    Copy-IfNew "$ScriptDir\.opencode\plugin\harness-opencode-plugin.ts" `
               "$TargetDir\.opencode\plugin\harness-opencode-plugin.ts"
}

Write-Host ""
Write-Host "安装完成。下一步：" -ForegroundColor Green
Write-Host ""
Write-Host '  claude "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"'
Write-Host ""

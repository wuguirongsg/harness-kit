@echo off
chcp 65001 > nul
:: upgrade.bat — harness-kit 修复 & 更新脚本（Windows 版）
::
:: 用法：
::   cd your-project
::   upgrade.bat                          从当前目录升级
::   upgrade.bat C:\path\to\your-project  升级指定项目
::
:: 策略：
::   更新：协议文件（SESSION_START/END、hooks、tool configs）
::   保留：数据目录（product/ state/ registry/ AGENTS.md）

setlocal enabledelayedexpansion

:: ── 确定脚本目录 ─────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
set "TMPL=!SCRIPT_DIR!\template"

:: ── 确定目标目录 ─────────────────────────────────────────────────
if "%~1"=="" (
    set "TARGET_DIR=%CD%"
) else (
    pushd "%~1" 2>nul || (
        echo [ERROR] 目标目录不存在：%~1
        exit /b 1
    )
    set "TARGET_DIR=%CD%"
    popd
)

set "HARNESS_DIR=!TARGET_DIR!\.harness"

:: ── 检查是否在项目目录 ────────────────────────────────────────────
set IS_PROJECT=0
if exist "!TARGET_DIR!\.git"         set IS_PROJECT=1
if exist "!TARGET_DIR!\package.json" set IS_PROJECT=1
if exist "!TARGET_DIR!\Cargo.toml"   set IS_PROJECT=1
if exist "!TARGET_DIR!\go.mod"       set IS_PROJECT=1
if exist "!TARGET_DIR!\.harness"     set IS_PROJECT=1

if "!IS_PROJECT!"=="0" (
    echo [ERROR] 未找到项目标识（.git、package.json 等），请在项目根目录下运行
    exit /b 1
)

:: ── 读取版本 ──────────────────────────────────────────────────────
if not exist "!TMPL!\.harness\VERSION" (
    echo [ERROR] harness-kit 源包缺少 VERSION 文件，请检查安装包完整性
    exit /b 1
)
for /f "usebackq delims=" %%v in ("!TMPL!\.harness\VERSION") do set "TARGET_VERSION=%%v"

set "CURRENT_VERSION=未知"
if exist "!HARNESS_DIR!\VERSION" (
    for /f "usebackq delims=" %%v in ("!HARNESS_DIR!\VERSION") do set "CURRENT_VERSION=%%v"
)

echo.
echo ================================================
echo   Harness Kit 修复 ^& 更新
echo   当前版本：!CURRENT_VERSION!  -^>  目标版本：!TARGET_VERSION!
echo ================================================
echo.
echo   将无条件更新所有协议文件至 !TARGET_VERSION!
echo   你的数据文件（product/ state/ registry/ AGENTS.md）不会被修改
echo.

set /p "CONFIRM=确认执行？[Y/n]: "
if "!CONFIRM!"=="" set "CONFIRM=Y"
if /i not "!CONFIRM!"=="y" (
    echo 已取消
    exit /b 0
)
echo.

:: ── 备份（用 wmic 获取与 locale 无关的时间戳）─────────────────────
set "TIMESTAMP="
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value 2^>nul') do (
    if not "%%a"=="" set "_raw=%%a"
)
if defined _raw set "TIMESTAMP=!_raw:~0,8!-!_raw:~8,6!"
if "!TIMESTAMP!"=="" set "TIMESTAMP=backup"

set "BACKUP_DIR=!HARNESS_DIR!\backup\!TIMESTAMP!"
md "!BACKUP_DIR!" >nul 2>&1

echo [INFO] 备份现有协议文件 -^> !BACKUP_DIR!
if exist "!HARNESS_DIR!\SESSION_START.md"       copy /Y "!HARNESS_DIR!\SESSION_START.md"       "!BACKUP_DIR!\" >nul
if exist "!HARNESS_DIR!\SESSION_END.md"         copy /Y "!HARNESS_DIR!\SESSION_END.md"         "!BACKUP_DIR!\" >nul
if exist "!HARNESS_DIR!\hooks"                  xcopy /E /I /Q "!HARNESS_DIR!\hooks"           "!BACKUP_DIR!\hooks" >nul
if exist "!TARGET_DIR!\.claude\settings.json"   copy /Y "!TARGET_DIR!\.claude\settings.json"   "!BACKUP_DIR!\claude-settings.json" >nul
if exist "!TARGET_DIR!\.cursor\hooks.json"      copy /Y "!TARGET_DIR!\.cursor\hooks.json"      "!BACKUP_DIR!\cursor-hooks.json" >nul
if exist "!TARGET_DIR!\.codex\hooks.json"       copy /Y "!TARGET_DIR!\.codex\hooks.json"       "!BACKUP_DIR!\codex-hooks.json" >nul
echo [OK] 备份完成
echo.

:: ── 无条件替换协议文件 ────────────────────────────────────────────
echo [INFO] 更新协议文件...
if not exist "!HARNESS_DIR!\hooks" md "!HARNESS_DIR!\hooks"

call :force_copy "!TMPL!\.harness\SESSION_START.md"  "!HARNESS_DIR!\SESSION_START.md"  "SESSION_START.md"
call :force_copy "!TMPL!\.harness\SESSION_END.md"    "!HARNESS_DIR!\SESSION_END.md"    "SESSION_END.md"
call :force_copy "!TMPL!\HARNESS_SETUP.md"           "!TARGET_DIR!\HARNESS_SETUP.md"   "HARNESS_SETUP.md"

xcopy /E /I /Y /Q "!TMPL!\.harness\hooks" "!HARNESS_DIR!\hooks" >nul && echo [OK] hooks/
call :force_copy "!TMPL!\.harness\gitignore" "!HARNESS_DIR!\.gitignore" ".harness\.gitignore"

if not exist "!TARGET_DIR!\.claude"       md "!TARGET_DIR!\.claude"
if not exist "!TARGET_DIR!\.cursor"       md "!TARGET_DIR!\.cursor"
if not exist "!TARGET_DIR!\.cursor\rules" md "!TARGET_DIR!\.cursor\rules"
call :force_copy "!TMPL!\.claude\settings.json"  "!TARGET_DIR!\.claude\settings.json"  ".claude\settings.json"
call :force_copy "!TMPL!\.cursor\hooks.json"     "!TARGET_DIR!\.cursor\hooks.json"     ".cursor\hooks.json"
call :force_copy "!TMPL!\.cursor\rules\karpathy-guidelines.mdc" "!TARGET_DIR!\.cursor\rules\karpathy-guidelines.mdc" ".cursor\rules\karpathy-guidelines.mdc"

if exist "!TARGET_DIR!\.codex" (
    call :force_copy "!TMPL!\.codex\codex-hooks.json"  "!TARGET_DIR!\.codex\hooks.json"  ".codex\hooks.json"
    call :force_copy "!TMPL!\.codex\codex-config.toml" "!TARGET_DIR!\.codex\config.toml" ".codex\config.toml"
)

if exist "!TARGET_DIR!\.opencode" (
    if not exist "!TARGET_DIR!\.opencode\plugin" md "!TARGET_DIR!\.opencode\plugin"
    call :force_copy "!TMPL!\.opencode\plugin\harness-opencode-plugin.ts" "!TARGET_DIR!\.opencode\plugin\harness-opencode-plugin.ts" ".opencode\plugin\harness-opencode-plugin.ts"
)

:: git commit-msg hook（用 Python3 确保 LF 行尾）
if exist "!TARGET_DIR!\.git" (
    if not exist "!TARGET_DIR!\.git\hooks" md "!TARGET_DIR!\.git\hooks"
    python3 -c "s=open(r'!TMPL!\.harness\hooks\commit-msg','rb').read().replace(b'\r\n',b'\n');open(r'!TARGET_DIR!\.git\hooks\commit-msg','wb').write(s)" >nul 2>&1 && echo [OK] git commit-msg hook
)

echo.

:: ── 修复缺失的数据目录（只创建，不覆盖）──────────────────────────
echo [INFO] 检查并修复缺失的数据目录...

if not exist "!HARNESS_DIR!\registry\sessions"  md "!HARNESS_DIR!\registry\sessions"
if not exist "!HARNESS_DIR!\registry\decisions" md "!HARNESS_DIR!\registry\decisions"
if not exist "!HARNESS_DIR!\state"              md "!HARNESS_DIR!\state"

for %%d in (requirements design releases) do (
    if not exist "!TARGET_DIR!\docs\%%d" (
        md "!TARGET_DIR!\docs\%%d"
        type nul > "!TARGET_DIR!\docs\%%d\.gitkeep"
        echo [OK] docs\%%d\ 已创建
    )
)

call :create_if_missing "!TMPL!\.harness\registry\_index.md"       "!HARNESS_DIR!\registry\_index.md"       ".harness\registry\_index.md"
call :create_if_missing "!TMPL!\.harness\state\features.json"      "!HARNESS_DIR!\state\features.json"      ".harness\state\features.json"
call :create_if_missing "!TMPL!\.harness\state\current-sprint.md"  "!HARNESS_DIR!\state\current-sprint.md"  ".harness\state\current-sprint.md"

set "PRODUCT_NEEDS_INIT="
if not exist "!HARNESS_DIR!\product" (
    md "!HARNESS_DIR!\product"
    copy /Y "!TMPL!\.harness\product\backlog.md" "!HARNESS_DIR!\product\backlog.md" >nul
    echo [OK] .harness\product\ 已创建（下次对话将自动初始化内容）
    set "PRODUCT_NEEDS_INIT=1"
)

echo.

:: ── 更新 VERSION ──────────────────────────────────────────────────
echo !TARGET_VERSION! > "!HARNESS_DIR!\VERSION"
echo [OK] VERSION -^> !TARGET_VERSION!
echo.

:: ── git commit ────────────────────────────────────────────────────
if exist "!TARGET_DIR!\.git" (
    set /p "DO_COMMIT=是否 git commit 本次更新？[Y/n]: "
    if "!DO_COMMIT!"=="" set "DO_COMMIT=Y"
    if /i "!DO_COMMIT!"=="y" (
        cd /d "!TARGET_DIR!"
        git add "!HARNESS_DIR!\SESSION_START.md" "!HARNESS_DIR!\SESSION_END.md" "!HARNESS_DIR!\hooks" "!HARNESS_DIR!\VERSION" HARNESS_SETUP.md .claude .cursor 2>nul
        if exist "!HARNESS_DIR!\product"  git add "!HARNESS_DIR!\product"  2>nul
        if exist "!HARNESS_DIR!\state"    git add "!HARNESS_DIR!\state"    2>nul
        if exist "!HARNESS_DIR!\registry" git add "!HARNESS_DIR!\registry" 2>nul
        if exist ".codex"    git add .codex    2>nul
        if exist ".opencode" git add .opencode 2>nul
        git commit -m "chore: 更新 harness-kit 至 !TARGET_VERSION!" 2>nul && (
            echo [OK] git commit 完成
        ) || (
            echo [WARN] 没有需要提交的变更
        )
    )
)

:: ── 完成 ──────────────────────────────────────────────────────────
echo.
echo ================================================
echo   完成 -^> !TARGET_VERSION!
echo ================================================
echo.
echo   已更新：协议文件（SESSION_START/END、hooks、tool configs）
echo   未修改：product/ state/ registry/ AGENTS.md
echo   备份于：!BACKUP_DIR!
echo.
if "!PRODUCT_NEEDS_INIT!"=="1" (
    echo   注意：product/ 目录是首次创建，下次打开 Claude Code 时
    echo         AI 会自动根据项目信息填写 backlog.md
    echo.
)
exit /b 0

:: ════════════════════════════════════════════════════════════════
:: 子程序
:: ════════════════════════════════════════════════════════════════

:force_copy
set "_src=%~1"
set "_dst=%~2"
set "_lbl=%~3"
copy /Y "!_src!" "!_dst!" >nul 2>&1 && echo [OK] !_lbl! || echo [ERROR] !_lbl! 复制失败
exit /b 0

:create_if_missing
set "_src=%~1"
set "_dst=%~2"
set "_lbl=%~3"
if not exist "!_dst!" (
    copy /Y "!_src!" "!_dst!" >nul 2>&1 && echo [OK] !_lbl! ^(已修复^) || echo [ERROR] !_lbl! 创建失败
)
exit /b 0

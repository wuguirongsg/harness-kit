@echo off
:: install.bat
:: 把 harness-kit-v2 的文件复制到目标项目
::
:: 用法：
::   install.bat                          安装到当前目录
::   install.bat C:\path\to\your-project  安装到指定目录
::
:: 前置依赖：
::   Git for Windows（提供 bash，hooks 需要）
::   Python3（hooks 脚本依赖）

setlocal enabledelayedexpansion

:: ── 前置依赖检查 ─────────────────────────────────────────────────
where python3 >nul 2>&1 || (
    echo [ERROR] 需要 Python3，请先安装 python3（hooks 脚本依赖）
    exit /b 1
)

:: ── 确定脚本目录 ─────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

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

:: ── 检查是否像项目根目录 ─────────────────────────────────────────
set IS_PROJECT=0
if exist "!TARGET_DIR!\.git"         set IS_PROJECT=1
if exist "!TARGET_DIR!\package.json" set IS_PROJECT=1
if exist "!TARGET_DIR!\Cargo.toml"   set IS_PROJECT=1
if exist "!TARGET_DIR!\go.mod"       set IS_PROJECT=1

if "!IS_PROJECT!"=="0" (
    echo [WARN] 目标目录 !TARGET_DIR! 似乎不是项目根目录，确认要在这里安装吗？ [y/N]
    set /p "CONFIRM= "
    if /i not "!CONFIRM!"=="y" exit /b 1
)

echo 安装目标：!TARGET_DIR!
echo.

:: ── 协议文件 ─────────────────────────────────────────────────────
call :copy_file "!SCRIPT_DIR!\template\HARNESS_SETUP.md"  "!TARGET_DIR!\HARNESS_SETUP.md"
call :copy_file "!SCRIPT_DIR!\template\AGENTS.md"          "!TARGET_DIR!\AGENTS.md"

:: ── .harness 模板（从 template/ 分发，不携带本项目运行时状态）────
if not exist "!TARGET_DIR!\.harness\registry\sessions"  md "!TARGET_DIR!\.harness\registry\sessions"
if not exist "!TARGET_DIR!\.harness\registry\decisions" md "!TARGET_DIR!\.harness\registry\decisions"
if not exist "!TARGET_DIR!\.harness\state"              md "!TARGET_DIR!\.harness\state"

call :copy_file "!SCRIPT_DIR!\template\.harness\SESSION_START.md"   "!TARGET_DIR!\.harness\SESSION_START.md"
call :copy_file "!SCRIPT_DIR!\template\.harness\SESSION_END.md"     "!TARGET_DIR!\.harness\SESSION_END.md"
call :copy_dir  "!SCRIPT_DIR!\template\.harness\hooks"              "!TARGET_DIR!\.harness\hooks"
call :copy_file "!SCRIPT_DIR!\template\.harness\registry\_index.md" "!TARGET_DIR!\.harness\registry\_index.md"

:: ── product 目录（需求管理层）─────────────────────────────────────
if not exist "!TARGET_DIR!\.harness\product" (
    md "!TARGET_DIR!\.harness\product"
    copy /Y "!SCRIPT_DIR!\template\.harness\product\vision.md"  "!TARGET_DIR!\.harness\product\vision.md" >nul
    copy /Y "!SCRIPT_DIR!\template\.harness\product\backlog.md" "!TARGET_DIR!\.harness\product\backlog.md" >nul
    copy /Y "!SCRIPT_DIR!\template\.harness\product\changes.md" "!TARGET_DIR!\.harness\product\changes.md" >nul
    echo [OK] .harness\product\ 需求管理目录
)

:: ── docs/ 骨架（设计/需求/发布文档目录）──────────────────────────
for %%d in (requirements design releases) do (
    if not exist "!TARGET_DIR!\docs\%%d" (
        md "!TARGET_DIR!\docs\%%d"
        type nul > "!TARGET_DIR!\docs\%%d\.gitkeep"
    )
)
echo [OK] docs/ 骨架创建完成（requirements/ design/ releases/）

:: ── 版本标记 ────────────────────────────────────────────────────
set "VERSION_SRC=!SCRIPT_DIR!\template\.harness\VERSION"
if exist "!VERSION_SRC!" (
    for /f "usebackq delims=" %%v in ("!VERSION_SRC!") do set "HARNESS_VERSION=%%v"
) else (
    echo [WARN] VERSION 文件缺失，使用 'unknown'
    set "HARNESS_VERSION=unknown"
)
echo !HARNESS_VERSION! > "!TARGET_DIR!\.harness\VERSION"
echo [OK] 写入版本标记：!HARNESS_VERSION!

:: ── Hook 配置 ────────────────────────────────────────────────────
if not exist "!TARGET_DIR!\.claude" md "!TARGET_DIR!\.claude"
if not exist "!TARGET_DIR!\.cursor" md "!TARGET_DIR!\.cursor"
if not exist "!TARGET_DIR!\.cursor\rules" md "!TARGET_DIR!\.cursor\rules"
call :copy_file "!SCRIPT_DIR!\template\.claude\settings.json" "!TARGET_DIR!\.claude\settings.json"
call :copy_file "!SCRIPT_DIR!\template\.cursor\hooks.json"    "!TARGET_DIR!\.cursor\hooks.json"
call :copy_file "!SCRIPT_DIR!\template\.cursor\rules\karpathy-guidelines.mdc" "!TARGET_DIR!\.cursor\rules\karpathy-guidelines.mdc"

:: ── CLAUDE.md 和 .cursorrules ────────────────────────────────────
call :copy_file "!TARGET_DIR!\AGENTS.md" "!TARGET_DIR!\CLAUDE.md"
call :copy_file "!TARGET_DIR!\AGENTS.md" "!TARGET_DIR!\.cursorrules"

echo [OK] Windows 无需设置脚本执行权限

:: ── git commit-msg hook ──────────────────────────────────────────
:: 用 Python3 复制模板并确保 LF 行尾（Git Bash 解析 hook 需要）
if exist "!TARGET_DIR!\.git" (
    if not exist "!TARGET_DIR!\.git\hooks" md "!TARGET_DIR!\.git\hooks"
    if not exist "!TARGET_DIR!\.git\hooks\commit-msg" (
        python3 -c "s=open(r'!SCRIPT_DIR!\template\.harness\hooks\commit-msg','rb').read().replace(b'\r\n',b'\n');open(r'!TARGET_DIR!\.git\hooks\commit-msg','wb').write(s)"
        echo [OK] git commit-msg hook 安装完成
    ) else (
        echo [WARN] git commit-msg hook 已存在，跳过
    )
)

:: ── Codex hooks ──────────────────────────────────────────────────
set CODEX_OK=0
where codex >nul 2>&1 && set CODEX_OK=1
if exist "!TARGET_DIR!\.codex\config.toml" set CODEX_OK=1
if "!CODEX_OK!"=="1" (
    if not exist "!TARGET_DIR!\.codex" md "!TARGET_DIR!\.codex"
    call :copy_file "!SCRIPT_DIR!\template\.codex\codex-hooks.json"  "!TARGET_DIR!\.codex\hooks.json"
    call :copy_file "!SCRIPT_DIR!\template\.codex\codex-config.toml" "!TARGET_DIR!\.codex\config.toml"
)

:: ── OpenCode plugin ──────────────────────────────────────────────
set OC_OK=0
where opencode >nul 2>&1 && set OC_OK=1
if exist "!TARGET_DIR!\.opencode\opencode.json" set OC_OK=1
if "!OC_OK!"=="1" (
    if not exist "!TARGET_DIR!\.opencode\plugin" md "!TARGET_DIR!\.opencode\plugin"
    call :copy_file "!SCRIPT_DIR!\template\.opencode\plugin\harness-opencode-plugin.ts" "!TARGET_DIR!\.opencode\plugin\harness-opencode-plugin.ts"
)

echo.
echo 安装完成。下一步：
echo.
echo   claude "请读取 HARNESS_SETUP.md 并按步骤初始化这个项目的 harness"
echo.
exit /b 0

:: ════════════════════════════════════════════════════════════════
:: 子程序
:: ════════════════════════════════════════════════════════════════

:copy_file
:: %1=src  %2=dst
set "_src=%~1"
set "_dst=%~2"
set "_name=%~nx2"
if not exist "!_dst!" (
    for %%F in ("!_dst!") do if not exist "%%~dpF" md "%%~dpF" >nul 2>&1
    copy /Y "!_src!" "!_dst!" >nul 2>&1 && (
        echo [OK] !_name!
    ) || (
        echo [ERROR] !_name! 复制失败
    )
) else (
    echo [WARN] !_name! 已存在，跳过
)
exit /b 0

:copy_dir
:: %1=src_dir  %2=dst_dir
set "_src=%~1"
set "_dst=%~2"
set "_name=%~nx2"
if not exist "!_dst!\" (
    xcopy /E /I /Q "!_src!" "!_dst!" >nul 2>&1 && (
        echo [OK] !_name!\
    ) || (
        echo [ERROR] !_name!\ 复制失败
    )
) else (
    echo [WARN] !_name!\ 已存在，跳过
)
exit /b 0

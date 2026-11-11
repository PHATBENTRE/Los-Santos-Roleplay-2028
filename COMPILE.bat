@echo off
setlocal
cd /d "%~dp0"
title LS:RP - Compile

set "OMP_PAWN_COMPILER=%~dp0qawno\pawncc.exe"
if not exist "%OMP_PAWN_COMPILER%" (
    echo [ERROR] Khong tim thay qawno\pawncc.exe trong goi open.mp
    pause
    exit /b 1
)

if not exist "qawno\include\a_mysql.inc" goto deps
if not exist "qawno\include\samp_bcrypt.inc" goto deps
if not exist "qawno\include\YSI_Coding\y_hooks.inc" goto deps
goto compile

:deps
echo Dang cai dependency...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_dependencies.ps1"
if errorlevel 1 (
    echo [ERROR] Khong cai duoc dependency.
    pause
    exit /b 1
)

:compile
echo.
echo ===== COMPILE LS:RP BASE =====
"%OMP_PAWN_COMPILER%" "gamemodes\main.pwn" -i"qawno\include" -i"gamemodes" -o"gamemodes\main.amx"
if errorlevel 1 (
    echo.
    echo [FAILED] Compile co loi. Gui log compiler cho ChatGPT.
    pause
    exit /b 1
)

if not exist "gamemodes\main.amx" (
    echo [ERROR] Khong tao duoc gamemodes\main.amx
    pause
    exit /b 1
)

echo.
echo [OK] gamemodes\main.amx
pause
exit /b 0

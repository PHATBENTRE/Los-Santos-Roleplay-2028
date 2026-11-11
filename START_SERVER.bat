@echo off
setlocal
cd /d "%~dp0"
title LS:RP Development Server

if not exist "mysql.ini" (
    echo [ERROR] Khong tim thay mysql.ini.
    echo Copy mysql.ini.example thanh mysql.ini va nhap thong tin MySQL.
    pause
    exit /b 1
)

if not exist "plugins\mysql.dll" goto deps
if not exist "plugins\samp_bcrypt.dll" goto deps
if not exist "qawno\include\a_mysql.inc" goto deps
if not exist "qawno\include\samp_bcrypt.inc" goto deps
if not exist "qawno\include\YSI_Coding\y_hooks.inc" goto deps
goto build

:deps
echo [SETUP] Dang tai/cai dependencies lan dau...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_dependencies.ps1"
if errorlevel 1 (
    echo [ERROR] Dependency setup that bai.
    pause
    exit /b 1
)

:build
if not exist "qawno\pawncc.exe" (
    echo [ERROR] Khong tim thay qawno\pawncc.exe.
    echo Hay cap nhat day du thu muc qawno tu ban open.mp moi nhat.
    pause
    exit /b 1
)
if not exist "gamemodes\main.pwn" (
    echo [ERROR] Khong tim thay gamemodes\main.pwn.
    pause
    exit /b 1
)

echo [BUILD] Dang compile gamemodes\main.pwn bang compiler open.mp...
"qawno\pawncc.exe" "gamemodes\main.pwn" -i"qawno\include" -i"gamemodes" -o"gamemodes\main.amx"
if errorlevel 1 (
    echo [ERROR] Compile that bai. Server khong chay AMX cu.
    pause
    exit /b 1
)
if not exist "gamemodes\main.amx" (
    echo [ERROR] Compile xong nhung khong thay gamemodes\main.amx.
    pause
    exit /b 1
)

if not exist "omp-server.exe" (
    echo [ERROR] Khong tim thay omp-server.exe.
    pause
    exit /b 1
)

echo.
echo ================================================
echo LS:RP Development
echo Local server: 127.0.0.1:7777
echo Database cfg : mysql.ini
echo Gamemode     : compiled on every start
echo ================================================
echo.
"omp-server.exe"
pause

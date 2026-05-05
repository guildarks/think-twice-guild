@echo off
setlocal enabledelayedexpansion

REM Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ============================================
    echo   ADMINISTRATOR PERMISSION REQUIRED
    echo ============================================
    echo.
    echo A new window will open with a User Account Control (UAC) prompt.
    echo.
    echo CLICK "YES" to allow PowerShell to run setup-scheduler.ps1
    echo.
    echo ============================================
    echo.
    timeout /t 3
    powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File E:\\cerveaux\ claude\\setup-scheduler.ps1 -NoExit'"
    exit /b
)

echo Setup completed successfully!
pause

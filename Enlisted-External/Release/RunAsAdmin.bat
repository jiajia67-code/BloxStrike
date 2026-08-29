@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================
echo   Enlisted External — Dagor Engine 6.x
echo ============================================
echo [*] Running as Administrator
echo.
cd /d "%~dp0"
"Enlisted External.exe"
pause

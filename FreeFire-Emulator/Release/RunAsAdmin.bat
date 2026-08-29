@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting admin rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
echo Starting FreeFire Emulator as Admin...
"FreeFire Emulator.exe"
pause

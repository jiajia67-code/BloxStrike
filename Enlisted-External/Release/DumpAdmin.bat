@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd /d "C:\Users\fff92\Desktop\GameCheats\Enlisted-External"
echo Running dumper...
dotnet run -c Release -- --dump
pause

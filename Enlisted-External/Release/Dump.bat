@echo off
cd /d "%~dp0"
dotnet run -c Release -- --dump > dump_output.txt 2>&1
echo Done! Check dump_output.txt
pause

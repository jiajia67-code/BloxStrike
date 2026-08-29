@echo off
cd /d "%~dp0"
echo Starting memory dump...
dotnet "Enlisted External.dll" --dump > dump_output.txt 2>&1
echo Output saved to dump_output.txt

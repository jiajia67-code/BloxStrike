@echo off
title FreeFire Emulator v2.0
echo 正在以管理員身份啟動...
powershell -Command "Start-Process '%~dp0FreeFire Emulator.exe' -Verb RunAs"

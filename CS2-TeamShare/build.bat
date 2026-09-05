@echo off
setlocal
set CS2_TS_DIR=%~dp0
set CS2_TS_DIR=%CS2_TS_DIR:~0,-1%

where g++ >nul 2>&1 || (
    echo [ERROR] g++ not found. Install MinGW-w64 or add to PATH.
    exit /b 1
)

echo [CS2-TeamShare] Compiling with g++ (D3D9 overlay enabled)...

g++ -shared -o CS2-TeamShare.dll ^
    src/dllmain.cpp ^
    -I"%CS2_TS_DIR%\..\CS2-Offsets" ^
    -lws2_32 -ld3d9 ^
    -static -O2 -std=c++17

if %ERRORLEVEL% EQU 0 (
    echo [CS2-TeamShare] Build succeeded: CS2-TeamShare.dll
) else (
    echo [CS2-TeamShare] Build FAILED
)
endlocal

@echo off
echo ============================================
echo    CS2 Hook DLL Build Script
echo ============================================
echo.

REM Find g++
where g++ >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] g++ not found in PATH
    echo Install MinGW or add to PATH
    echo Location: C:\Users\fff92\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin
    pause
    exit /b 1
)

echo [1/3] Compiling hook.cpp...
g++ -shared -o hook.dll hook.cpp -lole32 -loleaut32 -static -std=c++17 -O2
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed
    pause
    exit /b 1
)

echo [2/3] Checking output...
if not exist hook.dll (
    echo [ERROR] hook.dll not created
    pause
    exit /b 1
)

echo [3/3] Copying to Titled-Gui-CS2...
copy /Y hook.dll "C:\Users\fff92\Desktop\GameCheats\Titled-Gui-CS2\hook.dll" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo    Build SUCCESS!
    echo ============================================
    echo    hook.dll created and copied to:
    echo    C:\Users\fff92\Desktop\GameCheats\Titled-Gui-CS2\hook.dll
    echo.
    echo    To use:
    echo    1. Start Titled-Gui-CS2.exe
    echo    2. Start CS2 and enter a match
    echo    3. DLL will auto-inject and hook CreateMove
    echo    4. Press DELETE in-game to unload
    echo ============================================
) else (
    echo [WARNING] Copy failed, hook.dll is in current directory
)

echo.
pause

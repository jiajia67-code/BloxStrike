@echo off
echo ========================================
echo   CS2 Silent Aim DLL Build Script
echo ========================================
echo.

:: Check if Visual Studio is available
where cl >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] MSVC compiler not found!
    echo Please run this from a Visual Studio Developer Command Prompt.
    echo Or install Visual Studio Build Tools.
    echo.
    echo Alternative: Use CMake with Visual Studio generator.
    goto :end
)

echo [INFO] Found MSVC compiler
echo.

:: Create output directory
if not exist "bin" mkdir bin

echo [INFO] Compiling CS2-SilentAim.dll...
echo.

:: Compile with MSVC
cl /EHsc /O2 /LD /Fe:"bin\CS2-SilentAim.dll" ^
    src\dllmain.cpp ^
    /I src ^
    kernel32.lib psapi.lib

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Compilation failed!
    goto :end
)

echo.
echo ========================================
echo   Build successful!
echo ========================================
echo.
echo Output: bin\CS2-SilentAim.dll
echo.
echo To use:
echo   1. Copy CS2-SilentAim.dll to your cheat directory
echo   2. Run the external program (Titled GUI CS2)
echo   3. Start CS2
echo   4. Inject the DLL (or it auto-injects)
echo.
echo Features:
echo   - CreateMove hook (silent aim)
echo   - Anti-aim support
echo   - IPC with external program
echo   - DELETE key to unload
echo.

:end
pause

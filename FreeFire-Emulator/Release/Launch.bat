@echo off
echo ========================================
echo    FreeFire Emulator - Auto Launch
echo ========================================
echo.
echo [*] Starting Auto-Injector...
echo [*] Please ensure:
echo     1. Emulator is running (BlueStacks/LDPlayer/Nox/MEmu/GameLoop)
echo     2. Free Fire is installed in the emulator
echo.
echo [*] The injector will automatically:
echo     - Find the emulator process
echo     - Find Free Fire process
echo     - Inject the DLL
echo     - Start all features
echo.
cd /d "%~dp0"
FreeFire-Injector.exe
pause

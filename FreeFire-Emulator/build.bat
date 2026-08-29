@echo off
echo ========================================
echo    FreeFire Emulator Build Script
echo ========================================
echo.

:: 設定路徑
set PROJECT_DIR=%~dp0
set OUTPUT_DIR=%PROJECT_DIR%Release
set INJECTOR_DIR=%PROJECT_DIR%Injector
set MAIN_DLL=%OUTPUT_DIR%\FreeFire_Emulator.dll
set INJECTOR_EXE=%OUTPUT_DIR%\FreeFire-Injector.exe

:: 清除舊的建置
echo [1/5] 清除舊的建置...
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

:: 建置主專案 (DLL)
echo [2/5] 建置主專案 (DLL)...
cd "%PROJECT_DIR%"
dotnet build -c Release -o "%OUTPUT_DIR%"
if errorlevel 1 (
    echo [ERROR] 主專案建置失敗！
    pause
    exit /b 1
)
echo [OK] 主專案建置成功！

:: 建置注入器 (EXE)
echo [3/5] 建置注入器 (EXE)...
cd "%INJECTOR_DIR%"
dotnet build -c Release -o "%OUTPUT_DIR%"
if errorlevel 1 (
    echo [ERROR] 注入器建置失敗！
    pause
    exit /b 1
)
echo [OK] 注入器建置成功！

:: 複製必要檔案
echo [4/5] 複製必要檔案...
copy "%PROJECT_DIR%freefire_bypass.js" "%OUTPUT_DIR%\" >nul 2>&1
copy "%PROJECT_DIR%FreeFireBypass-v1.0.0.zip" "%OUTPUT_DIR%\" >nul 2>&1
copy "%PROJECT_DIR%README.md" "%OUTPUT_DIR%\" >nul 2>&1

:: 建立啟動腳本
echo [5/5] 建立啟動腳本...
echo @echo off > "%OUTPUT_DIR%\Launch.bat"
echo echo ======================================== >> "%OUTPUT_DIR%\Launch.bat"
echo echo    FreeFire Emulator - Auto Launch >> "%OUTPUT_DIR%\Launch.bat"
echo echo ======================================== >> "%OUTPUT_DIR%\Launch.bat"
echo echo. >> "%OUTPUT_DIR%\Launch.bat"
echo echo [*] 正在啟動注入器... >> "%OUTPUT_DIR%\Launch.bat"
echo echo [*] 請確保模擬器和 Free Fire 已開啟 >> "%OUTPUT_DIR%\Launch.bat"
echo echo. >> "%OUTPUT_DIR%\Launch.bat"
echo cd /d "%%~dp0" >> "%OUTPUT_DIR%\Launch.bat"
echo FreeFire-Injector.exe >> "%OUTPUT_DIR%\Launch.bat"
echo pause >> "%OUTPUT_DIR%\Launch.bat"

:: 顯示完成訊息
echo.
echo ========================================
echo    Build 完成！
echo ========================================
echo.
echo 輸出目錄: %OUTPUT_DIR%
echo.
echo 檔案清單:
echo - FreeFire-Injector.exe  (自動注入器)
echo - FreeFire_Emulator.dll  (主程式)
echo - freefire_bypass.js     (Frida 腳本)
echo - FreeFireBypass-v1.0.0.zip (Magisk 模組)
echo - Launch.bat             (啟動腳本)
echo.
echo 使用方式:
echo 1. 開啟 FreeFire-Injector.exe
echo 2. 等待自動找到模擬器
echo 3. 等待自動注入
echo 4. 開始遊戲！
echo.
pause

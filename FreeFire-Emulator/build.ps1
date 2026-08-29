# FreeFire Emulator Build Script (PowerShell)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   FreeFire Emulator Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set paths
$ProjectDir = $PSScriptRoot
$OutputDir = Join-Path $ProjectDir "Release"
$InjectorDir = Join-Path $ProjectDir "Injector"

# Clean old build
Write-Host "[1/5] Cleaning old build..." -ForegroundColor Yellow
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Build main project (DLL)
Write-Host "[2/5] Building main project (DLL)..." -ForegroundColor Yellow
Set-Location $ProjectDir
dotnet build -c Release -o $OutputDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Main project build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Main project built successfully!" -ForegroundColor Green

# Build injector (EXE)
Write-Host "[3/5] Building injector (EXE)..." -ForegroundColor Yellow
Set-Location $InjectorDir
dotnet build -c Release -o $OutputDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Injector build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Injector built successfully!" -ForegroundColor Green

# Copy files
Write-Host "[4/5] Copying files..." -ForegroundColor Yellow
$FilesToCopy = @("freefire_bypass.js", "FreeFireBypass-v1.0.0.zip", "README.md")
foreach ($File in $FilesToCopy) {
    $Source = Join-Path $ProjectDir $File
    if (Test-Path $Source) { Copy-Item $Source $OutputDir -Force }
}

# Create launch script
Write-Host "[5/5] Creating launch script..." -ForegroundColor Yellow
$LaunchScript = @"
@echo off
echo ========================================
echo    FreeFire Emulator - Auto Launch
echo ========================================
echo.
echo [*] Starting injector...
echo [*] Please ensure emulator and Free Fire are running
echo.
cd /d "%~dp0"
FreeFire-Injector.exe
pause
"@
$LaunchScript | Out-File -FilePath (Join-Path $OutputDir "Launch.bat") -Encoding ASCII

# Compress to ZIP
Write-Host "[*] Compressing to ZIP..." -ForegroundColor Yellow
$ZipPath = Join-Path $ProjectDir "FreeFire-Emulator-Release.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path $OutputDir -DestinationPath $ZipPath

# Show completion
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output: $OutputDir" -ForegroundColor Cyan
Write-Host "ZIP: $ZipPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files:" -ForegroundColor White
Write-Host "  - FreeFire-Injector.exe  (Auto Injector)" -ForegroundColor White
Write-Host "  - FreeFire_Emulator.dll  (Main)" -ForegroundColor White
Write-Host "  - freefire_bypass.js     (Frida Script)" -ForegroundColor White
Write-Host "  - Launch.bat             (Launch Script)" -ForegroundColor White

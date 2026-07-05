@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ===================================================
echo             gInk Release Packaging Script
echo ===================================================

:: 1. Extract version from AssemblyInfo.cs
set "VERSION="
if exist "src\Properties\AssemblyInfo.cs" (
    for /f "tokens=2 delims=()" %%i in ('findstr "AssemblyVersion" src\Properties\AssemblyInfo.cs') do (
        set "VAL=%%~i"
        set "VAL=!VAL:"=!"
        for /f "tokens=1,2,3 delims=." %%a in ("!VAL!") do (
            set "VERSION=%%a.%%b.%%c"
        )
    )
)

if not defined VERSION (
    echo [Warning] Could not extract version from AssemblyInfo.cs, checking changelog.txt...
    if exist "changelog.txt" (
        for /f "tokens=1,2 delims=v(" %%a in ('findstr /R "^v[0-9]" changelog.txt') do (
            set "VAL=%%a"
            :: Trim spaces
            set "VAL=!VAL: =!"
            if not defined VERSION (
                set "VERSION=!VAL!"
            )
        )
    )
)

if not defined VERSION (
    set "VERSION=unknown"
)

echo [Info] Target version: !VERSION!

:: 2. Set up directories
set "BIN_DIR=%~dp0bin"
set "STAGING_DIR=%~dp0build\release_staging"
set "RELEASE_DIR=%~dp0release"

if not exist "!BIN_DIR!\gInk.exe" (
    echo [Error] gInk.exe not found in '!BIN_DIR!'. 
    echo Please run build.bat first to build the executable.
    exit /b 1
)

echo [Info] Cleaning up old staging directory...
if exist "!STAGING_DIR!" rmdir /s /q "!STAGING_DIR!"
mkdir "!STAGING_DIR!"

:: 3. Copying binaries & dependencies
echo [Info] Copying binaries and dependencies...
xcopy /y "!BIN_DIR!\gInk.exe" "!STAGING_DIR!\" >nul
xcopy /y "!BIN_DIR!\Microsoft.Ink.dll" "!STAGING_DIR!\" >nul
if exist "!BIN_DIR!\gInk.exe.config" (
    xcopy /y "!BIN_DIR!\gInk.exe.config" "!STAGING_DIR!\" >nul
)
if exist "!BIN_DIR!\config_default.ini" (
    xcopy /y "!BIN_DIR!\config_default.ini" "!STAGING_DIR!\" >nul
)
if exist "!BIN_DIR!\hotkeys.ini" (
    xcopy /y "!BIN_DIR!\hotkeys.ini" "!STAGING_DIR!\" >nul
)
if exist "!BIN_DIR!\pens.ini" (
    xcopy /y "!BIN_DIR!\pens.ini" "!STAGING_DIR!\" >nul
)
if exist "!BIN_DIR!\icon_red.ico" (
    xcopy /y "!BIN_DIR!\icon_red.ico" "!STAGING_DIR!\" >nul
)
if exist "!BIN_DIR!\icon_white.ico" (
    xcopy /y "!BIN_DIR!\icon_white.ico" "!STAGING_DIR!\" >nul
)

:: Copy localization
if exist "!BIN_DIR!\lang" (
    echo [Info] Copying translations...
    mkdir "!STAGING_DIR!\lang"
    xcopy /y /s "!BIN_DIR!\lang\*.*" "!STAGING_DIR!\lang\" >nul
)

:: Copy root documents
echo [Info] Copying documentation...
if exist "%~dp0readme.md" xcopy /y "%~dp0readme.md" "!STAGING_DIR!\" >nul
if exist "%~dp0license.txt" xcopy /y "%~dp0license.txt" "!STAGING_DIR!\" >nul
if exist "%~dp0changelog.txt" xcopy /y "%~dp0changelog.txt" "!STAGING_DIR!\" >nul

:: 4. Creating ZIP archive
if not exist "!RELEASE_DIR!" mkdir "!RELEASE_DIR!"
set "ZIP_PATH=!RELEASE_DIR!\gInk_v!VERSION!.zip"

if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!"

echo [Info] Compressing to "!ZIP_PATH!"...
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('!STAGING_DIR!', '!ZIP_PATH!')"

if %ERRORLEVEL% equ 0 (
    echo ---------------------------------------------------
    echo [Success] Release archive created successfully!
    echo [Success] Path: !ZIP_PATH!
) else (
    echo [Error] Failed to create ZIP archive.
)

:: 5. Clean up
echo [Info] Cleaning up staging directory...
if exist "!STAGING_DIR!" rmdir /s /q "!STAGING_DIR!"

echo Done.
endlocal

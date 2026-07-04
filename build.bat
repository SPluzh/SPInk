@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo               gInk Build Script
echo ===================================================

:: Check for vswhere.exe
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "MSBUILD_PATH="

if exist "%VSWHERE%" (
    echo [Info] Locating MSBuild using vswhere...
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set "VS_PATH=%%i"
    )
    if defined VS_PATH (
        if exist "!VS_PATH!\MSBuild\Current\Bin\MSBuild.exe" (
            set "MSBUILD_PATH=!VS_PATH!\MSBuild\Current\Bin\MSBuild.exe"
        ) else if exist "!VS_PATH!\MSBuild\15.0\Bin\MSBuild.exe" (
            set "MSBUILD_PATH=!VS_PATH!\MSBuild\15.0\Bin\MSBuild.exe"
        )
    )
)

:: Fallback to common installation directories if vswhere didn't find it
if not defined MSBUILD_PATH (
    echo [Info] MSBuild not found via vswhere, checking default paths...
    
    :: VS 2022 (64-bit)
    for %%e in (Enterprise Professional Community BuildTools) do (
        if exist "%ProgramFiles%\Microsoft Visual Studio\2022\%%e\MSBuild\Current\Bin\MSBuild.exe" (
            set "MSBUILD_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\%%e\MSBuild\Current\Bin\MSBuild.exe"
        )
    )
    
    :: VS 2019/2017 / older 32-bit folders
    if not defined MSBUILD_PATH (
        for %%v in (2022 2019 2017) do (
            for %%e in (Enterprise Professional Community BuildTools) do (
                if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\%%v\%%e\MSBuild\Current\Bin\MSBuild.exe" (
                    set "MSBUILD_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\%%v\%%e\MSBuild\Current\Bin\MSBuild.exe"
                )
            )
        )
    )
)

if not defined MSBUILD_PATH (
    echo [Error] MSBuild.exe was not found. 
    echo Please ensure Visual Studio or Build Tools are installed.
    exit /b 1
)

echo [Info] Found MSBuild at: "%MSBUILD_PATH%"

:: Set Configuration (default: Release)
set "CONFIG=Release"
if "%~1"=="debug" set "CONFIG=Debug"
if "%~1"=="Debug" set "CONFIG=Debug"

echo [Info] Building configuration: %CONFIG% (Platform: x86)
echo ---------------------------------------------------

:: Build the solution
"%MSBUILD_PATH%" gInk.sln /t:Rebuild /p:Configuration=%CONFIG% /p:Platform=x86

if %ERRORLEVEL% equ 0 (
    echo ---------------------------------------------------
    echo [Success] gInk compiled successfully!
    echo [Success] Executable and dependencies are in the 'bin' folder.
) else (
    echo ---------------------------------------------------
    echo [Error] Build failed with error code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

endlocal

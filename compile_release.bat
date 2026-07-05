@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ===================================================
echo             gInk Release Compilation Script
echo ===================================================

:: Check for vswhere.exe to locate MSBuild
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

:: Fallback to default installation paths if vswhere did not find it
if not defined MSBUILD_PATH (
    echo [Info] MSBuild not found via vswhere, checking default paths...
    
    :: VS 2022
    for %%e in (Enterprise Professional Community BuildTools) do (
        if exist "%ProgramFiles%\Microsoft Visual Studio\2022\%%e\MSBuild\Current\Bin\MSBuild.exe" (
            set "MSBUILD_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\%%e\MSBuild\Current\Bin\MSBuild.exe"
        )
    )
    
    :: VS 2019/2017
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
    echo [Error] MSBuild.exe was not found on this system.
    echo Please make sure Visual Studio 2017/2019/2022 or MSBuild Build Tools are installed.
    exit /b 1
)

echo [Info] MSBuild located at: "!MSBUILD_PATH!"
echo [Info] Cleaning previous build outputs...

:: Remove existing build artifacts from bin
if exist "bin\gInk.exe" del /f /q "bin\gInk.exe"
if exist "bin\gInk.pdb" del /f /q "bin\gInk.pdb"

:: Compile the solution for Release (x86 is mandatory for Microsoft.Ink.dll compatibility)
echo [Info] Compiling Release (x86)...
echo ---------------------------------------------------
"!MSBUILD_PATH!" gInk.sln /t:Rebuild /p:Configuration=Release /p:Platform=x86 /v:m

if %ERRORLEVEL% equ 0 (
    echo ---------------------------------------------------
    echo [Success] gInk Release compiled successfully!
    echo [Success] Binary output: %~dp0bin\gInk.exe
) else (
    echo ---------------------------------------------------
    echo [Error] Compilation failed with error code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

endlocal

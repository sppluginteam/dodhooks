@echo off
REM ============================================================
REM DODHooks - Windows Build Script
REM
REM Builds the extension for Windows x86 (32-bit) AND x86_64 (64-bit)
REM in a single run, then stages everything into a release-ready
REM "dist" folder and a .zip archive.
REM
REM Requirements:
REM   - Visual Studio 2019/2022 with "Desktop development with C++"
REM   - Python 3.8+ with AMBuild installed (pip install ambuild)
REM   - Git
REM
REM Usage:
REM   build.bat
REM   build.bat --no-zip
REM ============================================================

setlocal EnableDelayedExpansion
echo [START] DODHooks Windows Build
echo.

set SCRIPT_DIR=%~dp0
if "%SCRIPT_DIR:~-1%"=="\" set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

set DO_ZIP=1
if /I "%~1"=="--no-zip" set DO_ZIP=0

echo ============================================
echo   DODHooks Windows Build
echo ============================================

REM ---------- Dependency detection ----------
REM Candidates (in order): deps\<name>, <name> (inside repo),
REM   ..\<name> (sibling of the repo, e.g. D:\dhooks\sourcemod).
set "SM_PATH="
if exist "%SCRIPT_DIR%\deps\sourcemod\core\logic\ExtensionSys.cpp" set "SM_PATH=%SCRIPT_DIR%\deps\sourcemod"
if not defined SM_PATH if exist "%SCRIPT_DIR%\sourcemod\core\logic\ExtensionSys.cpp" set "SM_PATH=%SCRIPT_DIR%\sourcemod"
if not defined SM_PATH if exist "%SCRIPT_DIR%\..\sourcemod\core\logic\ExtensionSys.cpp" set "SM_PATH=%SCRIPT_DIR%\..\sourcemod"

set "MMS_PATH="
if exist "%SCRIPT_DIR%\deps\mmsource\core\metamod_plugins.cpp" set "MMS_PATH=%SCRIPT_DIR%\deps\mmsource"
if not defined MMS_PATH if exist "%SCRIPT_DIR%\mmsource\core\metamod_plugins.cpp" set "MMS_PATH=%SCRIPT_DIR%\mmsource"
if not defined MMS_PATH if exist "%SCRIPT_DIR%\..\mmsource\core\metamod_plugins.cpp" set "MMS_PATH=%SCRIPT_DIR%\..\mmsource"

set "HL2_ROOT="
if exist "%SCRIPT_DIR%\deps\hl2sdk-dods\public" set "HL2_ROOT=%SCRIPT_DIR%\deps"
if not defined HL2_ROOT if exist "%SCRIPT_DIR%\hl2sdk-dods\public" set "HL2_ROOT=%SCRIPT_DIR%\"
if not defined HL2_ROOT if exist "%SCRIPT_DIR%\..\hl2sdk-dods\public" set "HL2_ROOT=%SCRIPT_DIR%\.."

echo   SourceMod : %SM_PATH%
echo   Metamod   : %MMS_PATH%
echo   HL2SDK    : %HL2_ROOT% (sdk: dods)
echo.

REM ---------- Verify dependency presence ----------
if not defined SM_PATH (
  echo [ERROR] SourceMod not found.
  echo         Tried: deps\sourcemod, sourcemod, ..\sourcemod
  echo         Clone it:
  echo           git clone --depth 1 -b 1.12-dev https://github.com/alliedmodders/sourcemod.git sourcemod
  goto :error
)
if not exist "%SM_PATH%\core\logic\ExtensionSys.cpp" (
  echo [ERROR] SourceMod not found at %SM_PATH%\core\logic\ExtensionSys.cpp
  goto :error
)
if not defined MMS_PATH (
  echo [ERROR] Metamod:Source not found.
  echo         Tried: deps\mmsource, mmsource, ..\mmsource
  goto :error
)
if not exist "%MMS_PATH%\core\metamod_plugins.cpp" (
  echo [ERROR] Metamod:Source not found at %MMS_PATH%\core\metamod_plugins.cpp
  goto :error
)
if not defined HL2_ROOT (
  echo [ERROR] hl2sdk-dods not found.
  echo         Tried: deps\hl2sdk-dods, hl2sdk-dods, ..\hl2sdk-dods
  goto :error
)
if not exist "%HL2_ROOT%\hl2sdk-dods\public" (
  echo [ERROR] hl2sdk-dods public/ not found at %HL2_ROOT%\hl2sdk-dods\public
  goto :error
)

REM ---------- Locate vcvarsall.bat ----------
set "VCBAT="
for %%P in (
  "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
  "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
) do (
  if exist %%P if not defined VCBAT set "VCBAT=%%~P"
)
if not defined VCBAT (
  echo [ERROR] vcvarsall.bat not found.
  echo         Install Visual Studio 2019/2022 with "Desktop development with C++".
  goto :error
)
echo   Using: %VCBAT%
echo.

REM ---------- Check Python ----------
python --version 2>&1
if errorlevel 1 (
  echo [ERROR] python not found on PATH.
  echo         Install Python 3.8+ from https://www.python.org/downloads/
  echo         Make sure to check "Add Python to PATH" during installation.
  goto :error
)

REM ---------- Ensure AMBuild is installed ----------
python -c "import ambuild" >nul 2>&1
if errorlevel 1 (
  echo [INFO] AMBuild not found, installing...
  python -m pip install --upgrade ambuild
  if errorlevel 1 (
    echo [ERROR] Failed to install AMBuild. Try manually:
    echo           python -m pip install ambuild
    goto :error
  )
)

REM ---------- Locate ambuild command ----------
set "AMBUILD_CMD=ambuild"
echo   ambuild: ambuild (PATH)
echo.

REM ---------- Build both architectures ----------
echo.
echo ============================================
echo   Building x86 (32-bit) and x64 (64-bit)
echo ============================================

REM ---------- Ensure gamedata is available for AMBuild ----------
if not exist "%SCRIPT_DIR%\gamedata\dodhooks.txt" (
  if exist "%SCRIPT_DIR%\sourcemod\gamedata\dodhooks.txt" (
    echo [INFO] gamedata\dodhooks.txt not found in repo root, copying from sourcemod/gamedata
    if not exist "%SCRIPT_DIR%\gamedata" mkdir "%SCRIPT_DIR%\gamedata"
    copy /Y "%SCRIPT_DIR%\sourcemod\gamedata\dodhooks.txt" "%SCRIPT_DIR%\gamedata\dodhooks.txt" >nul
  )
)

call :build_one x86 x86
if errorlevel 1 (
  echo.
  echo [ERROR] x86 build failed.
  goto :error
)
call :build_one x64 x64
if errorlevel 1 (
  echo.
  echo [ERROR] x64 build failed.
  goto :error
)

REM ---------- Stage distribution ----------
echo.
echo [STAGE] Assembling release folder...
set "DIST=%SCRIPT_DIR%\dist"
if exist "%DIST%" rmdir /s /q "%DIST%"
mkdir "%DIST%\addons\sourcemod\extensions\x64" 2>nul
mkdir "%DIST%\addons\sourcemod\gamedata" 2>nul
mkdir "%DIST%\addons\sourcemod\scripting\include" 2>nul

REM 32-bit binary (default)
if exist "%SCRIPT_DIR%\build_x86\package\addons\sourcemod\extensions\dodhooks.ext.2.dods.dll" (
  copy /Y "%SCRIPT_DIR%\build_x86\package\addons\sourcemod\extensions\dodhooks.ext.2.dods.dll" "%DIST%\addons\sourcemod\extensions\" >nul
  echo   [OK] 32-bit DLL
) else (
  echo [ERROR] 32-bit build output missing.
  goto :error
)

REM 64-bit binary (x64 subfolder)
if exist "%SCRIPT_DIR%\build_x64\package\addons\sourcemod\extensions\x64\dodhooks.ext.2.dods.dll" (
  copy /Y "%SCRIPT_DIR%\build_x64\package\addons\sourcemod\extensions\x64\dodhooks.ext.2.dods.dll" "%DIST%\addons\sourcemod\extensions\x64\" >nul
  echo   [OK] 64-bit DLL
) else (
  echo [ERROR] 64-bit build output missing.
  goto :error
)

REM GameData (accept file in repo root or fallback to sourcemod/gamedata)
if exist "%SCRIPT_DIR%\gamedata\dodhooks.txt" (
  copy /Y "%SCRIPT_DIR%\gamedata\dodhooks.txt" "%DIST%\addons\sourcemod\gamedata\" >nul
  echo   [OK] GameData
) else if exist "%SCRIPT_DIR%\sourcemod\gamedata\dodhooks.txt" (
  copy /Y "%SCRIPT_DIR%\sourcemod\gamedata\dodhooks.txt" "%DIST%\addons\sourcemod\gamedata\" >nul
  echo   [OK] GameData (from sourcemod/gamedata)
) else (
  echo [ERROR] gamedata\dodhooks.txt not found.
  goto :error
)

REM SourcePawn include (auto-loads the extension via "public Extension")
if exist "%SCRIPT_DIR%\sourcemod\scripting\include\dodhooks.inc" (
  copy /Y "%SCRIPT_DIR%\sourcemod\scripting\include\dodhooks.inc" "%DIST%\addons\sourcemod\scripting\include\" >nul
  echo   [OK] dodhooks.inc
) else (
  echo   [WARN] sourcemod\scripting\include\dodhooks.inc not found, skipping.
)

REM ---------- Version ----------
set "VERSION=1.0"
for /f "tokens=3 delims= " %%V in ('findstr /R /C:"SMEXT_CONF_VERSION" "%SCRIPT_DIR%\smsdk_config.h"') do (
  set "RAW=%%V"
)
if defined RAW (
  set "RAW=!RAW:"=!"
  set "VERSION=!RAW!"
)
echo   Version: %VERSION%

REM ---------- Zip ----------
if "%DO_ZIP%"=="1" (
  echo.
  echo [ZIP] Creating archive...
  set "ARCHIVE=DODHooks-%VERSION%-sm1.12-windows.zip"
  if exist "%SCRIPT_DIR%\!ARCHIVE!" del /q "%SCRIPT_DIR%\!ARCHIVE!"
  powershell -NoProfile -Command "Compress-Archive -Path '%DIST%\*' -DestinationPath '%SCRIPT_DIR%\DODHooks-%VERSION%-sm1.12-windows.zip' -Force"
  if errorlevel 1 (
    echo [WARN] Zip creation failed.
  ) else (
    echo   Created: DODHooks-%VERSION%-sm1.12-windows.zip
  )
)

echo.
echo ============================================
echo   Build complete!
echo ============================================
echo.
echo   dist\           -> %DIST%
echo   Upload to server -> addons\sourcemod\extensions\
echo.
echo   Contents:
dir /B /S "%DIST%"
echo.
goto :done

REM ============================================================
:build_one
set "ARCH=%1"
set "VCVARS=%2"
echo.
echo ----------------------------------------
echo   Building for %ARCH% (%VCVARS%)
echo ----------------------------------------
if exist "%SCRIPT_DIR%\build_%ARCH%" rmdir /s /q "%SCRIPT_DIR%\build_%ARCH%"
mkdir "%SCRIPT_DIR%\build_%ARCH%"
call "%VCBAT%" %VCVARS%
if errorlevel 1 (
  echo [ERROR] vcvarsall.bat failed for %VCVARS%.
  exit /b 1
)
cd /d "%SCRIPT_DIR%\build_%ARCH%"
echo   configure.py --arch=%ARCH% ...
python "%SCRIPT_DIR%\configure.py" --sm-path "%SM_PATH%" --mms-path "%MMS_PATH%" --hl2sdk-root "%HL2_ROOT%" --sdks=dods --enable-optimize --arch=%ARCH%
if errorlevel 1 (
  echo [ERROR] configure.py failed for %ARCH%.
  exit /b 1
)
echo   ambuild ...
%AMBUILD_CMD%
if errorlevel 1 (
  echo [ERROR] ambuild failed for %ARCH%.
  exit /b 1
)
cd /d "%SCRIPT_DIR%"
echo   [OK] %ARCH% build complete.
exit /b 0

:error
echo.
echo ============================================
echo   BUILD FAILED!
echo ============================================
echo.
:done
echo Press any key to exit...
pause >nul
endlocal
exit /b 1

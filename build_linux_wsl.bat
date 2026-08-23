@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  DODHooks - Build Linux (x86 + x64) on Windows via WSL
REM  (no Docker - compiles natively inside your WSL distro)
REM ============================================================
REM
REM  This drives the existing build_linux.sh inside WSL. WSL mounts
REM  your Windows drives automatically, so the Windows-side dependencies
REM  (D:\dhooks\sourcemod, mmsource, hl2sdk-dods) are seen by Linux at
REM  /mnt/d/dhooks/... and the resulting dist/ + tarball land back on
REM  the Windows filesystem where you can grab them directly.
REM
REM  Prerequisites inside your WSL distro (Ubuntu/Debian example):
REM    sudo apt-get update
REM    sudo apt-get install -y build-essential gcc-multilib g++-multilib \
REM         python3 python3-pip git
REM    python3 -m pip install --user --upgrade ambuild
REM
REM  Usage:
REM    build_linux_wsl.bat
REM    build_linux_wsl.bat --no-archive
REM ============================================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "EXTRA="
if /I "%~1"=="--no-archive" set "EXTRA=--no-archive"

REM ---------- WSL availability ----------
where wsl >nul 2>nul
if errorlevel 1 (
  echo [ERROR] WSL is not installed or not in PATH.
  echo         Enable WSL and install a Linux distro (e.g. "wsl --install").
  echo         Alternatively use build_linux.bat (Docker) or build.bat on Windows.
  goto :pause_exit
)

wsl --status >nul 2>nul
if errorlevel 1 (
  echo [ERROR] WSL does not have a default distribution. Run "wsl --install" first.
  goto :pause_exit
)

REM ---------- Translate Windows path to WSL path ----------
set "WSL_DIR="
for /f "usebackq delims=" %%p in (`wsl wslpath -a "%SCRIPT_DIR%"`) do set "WSL_DIR=%%p"
if "%WSL_DIR%"=="" (
  echo [ERROR] Could not map "%SCRIPT_DIR%" to a WSL path.
  goto :pause_exit
)

echo [+] Building DODHooks for Linux via WSL in: %WSL_DIR%
echo [+] (using Windows-side dependencies under the same tree)
echo.

wsl bash -c "set -e; cd '%WSL_DIR%' && chmod +x ./build_linux.sh && ./build_linux.sh %EXTRA%"
if errorlevel 1 (
  echo [ERROR] Linux build failed inside WSL. Check the output above.
  goto :pause_exit
)

echo.
echo ============================================
echo   Linux build complete (via WSL)!
echo ============================================
echo   dist\           -> %SCRIPT_DIR%dist
echo   tarball         -> %SCRIPT_DIR%DODHooks-*-sm1.12-linux.tar.gz
echo.
echo   To extract on the Linux server:
echo     tar -xzf DODHooks-*-sm1.12-linux.tar.gz -C /path/to/game
goto :done

:pause_exit
echo.
echo Press any key to exit...
pause >nul
exit /b 1

:done
echo.
echo Press any key to exit...
pause >nul
exit /b 0

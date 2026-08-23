@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  DODHooks - One-click build of Linux (x86 + x64) on Windows
REM ============================================================
REM
REM  Auto-selects a backend, in priority order:
REM    1. Docker     (needs Docker Desktop running)
REM    2. WSL        (needs a default WSL distro + Linux build deps)
REM
REM  If neither is available it prints install instructions and exits.
REM  Pass --no-archive to skip creating the .tar.gz.
REM
REM  Usage:
REM    build_linux.bat
REM    build_linux.bat --no-archive
REM ============================================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "EXTRA="
if /I "%~1"=="--no-archive" set "EXTRA=--no-archive"

set "DOCKER_OK=0"
where docker >nul 2>nul
if not errorlevel 1 (
  docker info >nul 2>nul
  if not errorlevel 1 (
    set "DOCKER_OK=1"
  ) else (
    echo [i] Docker is installed but its daemon is not running - will try WSL instead.
  )
)

if "%DOCKER_OK%"=="1" (
  echo [+] Docker detected - using Docker backend.
  call "%SCRIPT_DIR%\build_linux_docker.bat" %EXTRA%
  goto :eof
)

where wsl >nul 2>nul
if not errorlevel 1 (
  wsl --status >nul 2>nul
  if not errorlevel 1 (
    echo [+] WSL detected - using WSL backend.
    call "%SCRIPT_DIR%\build_linux_wsl.bat" %EXTRA%
    goto :eof
  )
)

echo [ERROR] Neither Docker nor WSL is available to build Linux on this machine.
echo.
echo Install ONE of the following, then re-run this script:
echo.
echo   A) Docker Desktop (recommended, zero Linux setup):
echo      https://www.docker.com/products/docker-desktop/
echo      -> install, launch it, wait for the daemon to be ready.
echo.
echo   B) WSL (uses your existing Windows-side dependencies):
echo      > wsl --install
echo      (restart when prompted, then open the distro and run:)
echo      > sudo apt-get update
echo      > sudo apt-get install -y build-essential gcc-multilib g++-multilib python3 python3-pip git
echo      > python3 -m pip install --user --upgrade ambuild
echo.
pause
exit /b 1

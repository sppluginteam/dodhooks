@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  DODHooks - Build Linux (x86 + x64) on Windows via Docker
REM  (backend invoked by build_linux.bat - use that for one-click)
REM ============================================================
REM
REM  Compiles the Linux binaries of DODHooks using the official
REM  AlliedModders build container. No Linux toolchain on the host
REM  required - only Docker Desktop for Windows.
REM
REM  Dependencies (sourcemod / mmsource / hl2sdk-dods) are cloned
REM  once into a Docker volume "dodhooks-linux-deps" so they are
REM  reused on later builds and never pollute your Windows repo.
REM
REM  Output (on Windows):
REM    dist\                         -> staged addons\sourcemod\...
REM    DODHooks-<ver>-sm1.12-linux.tar.gz
REM
REM  Usage:
REM    build_linux_docker.bat
REM    build_linux_docker.bat --no-archive
REM ============================================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "IMAGE=ghcr.io/alliedmodders/build-containers/debian11-clang22:latest"
set "DEPS_VOL=dodhooks-linux-deps"

set "EXTRA="
if /I "%~1"=="--no-archive" set "EXTRA=--no-archive"

REM ---------- Docker availability ----------
where docker >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Docker is not installed or not in PATH.
  echo         Install Docker Desktop for Windows and ensure it is running.
  goto :pause_exit
)

docker info >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Docker daemon is not running. Start Docker Desktop first.
  goto :pause_exit
)

echo [+] Pulling build image (first run may take a while)...
docker pull "%IMAGE%" 2>nul || echo [WARN] Pull failed - will try an already cached image.

echo [+] Building DODHooks for Linux inside Docker...
docker run --rm ^
  -v "%SCRIPT_DIR%:/work/dodhooks" ^
  -v "%DEPS_VOL%:/deps" ^
  -w /work/dodhooks ^
  "%IMAGE%" ^
  bash -c "set -e; sed -i 's/\r$//' build.sh 2>/dev/null || true; pip3 install --upgrade ambuild 2>/dev/null || true; if [ ! -d /deps/sourcemod ]; then git clone --depth 1 --branch 1.12-dev https://github.com/alliedmodders/sourcemod.git /deps/sourcemod; fi; if [ ! -d /deps/mmsource ]; then git clone --depth 1 --branch 1.12-dev --recurse-submodules https://github.com/alliedmodders/metamod-source.git /deps/mmsource; fi; if [ ! -d /deps/hl2sdk-dods ]; then git clone --depth 1 --branch dods https://github.com/ValveSoftware/hl2sdk.git /deps/hl2sdk-dods; fi; SM_PATH=/deps/sourcemod MMS_PATH=/deps/mmsource HL2_ROOT=/deps ./build.sh %EXTRA%"

if errorlevel 1 (
  echo [ERROR] Linux build failed inside Docker.
  goto :pause_exit
)

echo.
echo ============================================
echo   Linux build complete!
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

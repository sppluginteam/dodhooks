#!/usr/bin/env bash
# ============================================================
# DODHooks - Docker Linux Build Script
#
# Builds DODHooks for Linux x86 + x64 inside the official
# AlliedModders build container. No host toolchain required
# beyond Docker.
#
# Usage:
#   ./build_linux_docker.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v docker &>/dev/null; then
  echo "[ERROR] Docker is not installed." >&2
  exit 1
fi

# The Allies build container already provides gcc/clang, multilib,
# git and Python. AMBuild is installed at runtime.
IMAGE="ghcr.io/alliedmodders/build-containers/debian11-clang22:latest"

echo "[+] Pulling build image (this may take a while)..."
docker pull "${IMAGE}" || true

echo "[+] Building DODHooks for Linux in Docker..."
docker run --rm \
  -v "${SCRIPT_DIR}:/work/dodhooks" \
  -w /work/dodhooks \
  "${IMAGE}" \
  bash -c '
    set -euo pipefail
    echo "[+] Installing AMBuild..."
    pip3 install --upgrade ambuild 2>/dev/null || pip3 install --user --upgrade ambuild 2>/dev/null || true

    echo "[+] Cloning dependencies into deps/ ..."
    if [ ! -d deps ]; then mkdir deps; fi
    if [ ! -d deps/sourcemod ]; then
      git clone --depth 1 --branch 1.12-dev https://github.com/alliedmodders/sourcemod.git deps/sourcemod
    fi
    if [ ! -d deps/mmsource ]; then
      git clone --depth 1 --branch 1.12-dev --recurse-submodules https://github.com/alliedmodders/metamod-source.git deps/mmsource
    fi
    if [ ! -d deps/hl2sdk-dods ]; then
      git clone --depth 1 --branch dods https://github.com/ValveSoftware/hl2sdk.git deps/hl2sdk-dods
    fi

    echo "[+] Running build.sh ..."
    ./build.sh
  '

echo "[+] Done. Output is in: ${SCRIPT_DIR}/dist"
echo "[+] Archive: ${SCRIPT_DIR}/DODHooks-*-sm1.12-linux.tar.gz"

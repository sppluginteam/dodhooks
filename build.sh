#!/usr/bin/env bash
# ============================================================
#  DODHooks - Linux native build (Linux compiles Linux)
#
#  Builds the extension for Linux x86 (32-bit) AND x86_64 (64-bit)
#  on a Linux host, then stages everything into a release-ready
#  "dist" folder and a .tar.gz archive.
#
#  Requirements:
#    - gcc / g++ (with multilib for 32-bit: gcc-multilib g++-multilib)
#    - Python 3.8+ with AMBuild (pip install ambuild)
#    - Git
#    - Dependencies (auto-detected): sourcemod, mmsource, hl2sdk-dods
#        search order: deps/ , ./ , ../ , or env SM_PATH/MMS_PATH/HL2_ROOT
#
#  Usage:
#    ./build_linux.sh
#    ./build_linux.sh --no-archive
#    SM_PATH=/p MMS_PATH=/p HL2_ROOT=/p ./build_linux.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_ARCHIVE=1
if [[ "${1:-}" == "--no-archive" ]]; then
  DO_ARCHIVE=0
fi

echo "============================================"
echo "  DODHooks Linux Build (native)"
echo "============================================"

# ---------- Dependency detection ----------
if [[ -d "${SCRIPT_DIR}/deps/sourcemod" ]]; then
  SM_PATH="${SM_PATH:-${SCRIPT_DIR}/deps/sourcemod}"
elif [[ -d "${SCRIPT_DIR}/sourcemod" ]]; then
  SM_PATH="${SM_PATH:-${SCRIPT_DIR}/sourcemod}"
elif [[ -d "${SCRIPT_DIR}/../sourcemod" ]]; then
  SM_PATH="${SM_PATH:-${SCRIPT_DIR}/../sourcemod}"
fi

if [[ -d "${SCRIPT_DIR}/deps/mmsource" ]]; then
  MMS_PATH="${MMS_PATH:-${SCRIPT_DIR}/deps/mmsource}"
elif [[ -d "${SCRIPT_DIR}/mmsource" ]]; then
  MMS_PATH="${MMS_PATH:-${SCRIPT_DIR}/mmsource}"
elif [[ -d "${SCRIPT_DIR}/../mmsource" ]]; then
  MMS_PATH="${MMS_PATH:-${SCRIPT_DIR}/../mmsource}"
fi

if [[ -d "${SCRIPT_DIR}/deps/hl2sdk-dods/public" ]]; then
  HL2_ROOT="${HL2_ROOT:-${SCRIPT_DIR}/deps}"
elif [[ -d "${SCRIPT_DIR}/hl2sdk-dods/public" ]]; then
  HL2_ROOT="${HL2_ROOT:-${SCRIPT_DIR}}"
elif [[ -d "${SCRIPT_DIR}/../hl2sdk-dods/public" ]]; then
  HL2_ROOT="${HL2_ROOT:-${SCRIPT_DIR}/..}"
fi

echo "  SourceMod : ${SM_PATH}"
echo "  Metamod   : ${MMS_PATH}"
echo "  HL2SDK    : ${HL2_ROOT} (sdk: dods)"
echo

if [[ ! -f "${SM_PATH}/core/logic/ExtensionSys.cpp" ]]; then
  echo "[ERROR] SourceMod not found at ${SM_PATH}" >&2
  exit 1
fi
if [[ ! -f "${MMS_PATH}/core/metamod_plugins.cpp" ]]; then
  echo "[ERROR] Metamod:Source not found at ${MMS_PATH}" >&2
  exit 1
fi
if [[ ! -d "${HL2_ROOT}/hl2sdk-dods/public" ]]; then
  echo "[ERROR] hl2sdk-dods not found under ${HL2_ROOT}/hl2sdk-dods" >&2
  exit 1
fi

# ---------- Ensure gamedata is available for AMBuild ----------
if [[ ! -f "${SCRIPT_DIR}/gamedata/dodhooks.txt" ]]; then
  if [[ -f "${SCRIPT_DIR}/sourcemod/gamedata/dodhooks.txt" ]]; then
    echo "[INFO] gamedata/dodhooks.txt not found in repo root, copying from sourcemod/gamedata"
    mkdir -p "${SCRIPT_DIR}/gamedata"
    cp "${SCRIPT_DIR}/sourcemod/gamedata/dodhooks.txt" "${SCRIPT_DIR}/gamedata/dodhooks.txt"
  fi
fi

# ---------- Ensure AMBuild ----------
if ! python3 -c "import ambuild" 2>/dev/null; then
  echo "[INFO] Installing AMBuild..."
  python3 -m pip install --user --upgrade ambuild
fi

# ---------- Install 32-bit toolchain if needed (best effort) ----------
if [[ "$(uname -m)" == "x86_64" ]]; then
  if ! echo 'int main(){return 0;}' | gcc -m32 -x c - -o /tmp/_t32 2>/dev/null; then
    echo "[INFO] 32-bit toolchain missing; attempting to install (needs root)..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -qq && sudo apt-get install -y -qq gcc-multilib g++-multilib libstdc++6:i386 2>/dev/null || \
        echo "[WARN] Could not install multilib automatically. Install gcc-multilib g++-multilib manually for 32-bit builds."
    else
      echo "[WARN] Could not detect apt-get. Install 32-bit toolchain manually for 32-bit builds."
    fi
  fi
fi

# ---------- Build both architectures ----------
build_one() {
  local arch="$1"
  local build_dir="${SCRIPT_DIR}/build_${arch}"
  echo
  echo "----------------------------------------"
  echo "  Building for ${arch}"
  echo "----------------------------------------"
  rm -rf "${build_dir}"
  mkdir -p "${build_dir}"
  (
    cd "${build_dir}"
    python3 "${SCRIPT_DIR}/configure.py" \
      --sm-path "${SM_PATH}" \
      --mms-path "${MMS_PATH}" \
      --hl2sdk-root "${HL2_ROOT}" \
      --sdks=dods \
      --enable-optimize \
      --arch="${arch}"
    ambuild
  )
}

build_one x86
build_one x64

# ---------- Stage distribution ----------
echo
echo "[STAGE] Assembling release folder..."
DIST="${SCRIPT_DIR}/dist"
rm -rf "${DIST}"
mkdir -p "${DIST}/addons/sourcemod/extensions/x64"
mkdir -p "${DIST}/addons/sourcemod/gamedata"

if [[ -f "${SCRIPT_DIR}/build_x86/package/addons/sourcemod/extensions/dodhooks.ext.2.dods.so" ]]; then
  cp -v "${SCRIPT_DIR}/build_x86/package/addons/sourcemod/extensions/dodhooks.ext.2.dods.so" \
        "${DIST}/addons/sourcemod/extensions/"
else
  echo "[ERROR] 32-bit build output missing." >&2
  exit 1
fi

if [[ -f "${SCRIPT_DIR}/build_x64/package/addons/sourcemod/extensions/x64/dodhooks.ext.2.dods.so" ]]; then
  cp -v "${SCRIPT_DIR}/build_x64/package/addons/sourcemod/extensions/x64/dodhooks.ext.2.dods.so" \
        "${DIST}/addons/sourcemod/extensions/x64/"
else
  echo "[ERROR] 64-bit build output missing." >&2
  exit 1
fi

if [[ -f "${SCRIPT_DIR}/gamedata/dodhooks.txt" ]]; then
  cp -v "${SCRIPT_DIR}/gamedata/dodhooks.txt" "${DIST}/addons/sourcemod/gamedata/"
else
  echo "[ERROR] gamedata/dodhooks.txt not found." >&2
  exit 1
fi

if [[ -f "${SCRIPT_DIR}/sourcemod/scripting/include/dodhooks.inc" ]]; then
  mkdir -p "${DIST}/addons/sourcemod/scripting/include"
  cp -v "${SCRIPT_DIR}/sourcemod/scripting/include/dodhooks.inc" \
        "${DIST}/addons/sourcemod/scripting/include/"
else
  echo "[WARN] sourcemod/scripting/include/dodhooks.inc not found."
fi

# ---------- Version ----------
VERSION="$(grep -oP 'SMEXT_CONF_VERSION\s+"\K[^"]+' "${SCRIPT_DIR}/smsdk_config.h" || echo 1.0)"

# ---------- Archive ----------
if [[ "${DO_ARCHIVE}" == "1" ]]; then
  echo
  echo "[ARCHIVE] Creating tarball..."
  ARCHIVE="${SCRIPT_DIR}/DODHooks-${VERSION}-sm1.12-linux.tar.gz"
  rm -f "${ARCHIVE}"
  tar -czf "${ARCHIVE}" -C "${DIST}" addons
  echo "  Created: ${ARCHIVE}"
fi

echo
echo "============================================"
echo "  Build complete!"
echo "============================================"
echo "  dist/  -> ${DIST}"
echo "  Upload -> addons/sourcemod/extensions/"
echo
ls -la "${DIST}/addons/sourcemod/extensions"

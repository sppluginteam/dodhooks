#!/usr/bin/env bash
# ============================================================
#  DODHooks - Cross-compile Windows (.dll) from Linux (Linux compiles Windows)
#
#  Uses the MinGW-w64 toolchain to build the Windows x86 + x64 binaries
#  from a Linux host. The SourceMod SDK normally targets the host OS, so
#  this script:
#    1. points CC/CXX at the MinGW-w64 compilers, and
#    2. sets DHOOKS_TARGET_PLATFORM=windows so AMBuildScript builds .dll
#       files and applies the Windows code path (WIN32/_WINDOWS defines,
#       MSVC import libraries from hl2sdk-dods/lib/public/<arch>/).
#
#  The SDK's MSVC-only flags (/MT, /SUBSYSTEM:WINDOWS, ...) live in
#  configure_msvc, which is only used when the compiler vendor is "msvc".
#  With MinGW (gcc) those are skipped automatically and GCC flags are used.
#
#  REQUIREMENTS (on the Linux host):
#    - mingw-w64: i686-w64-mingw32-gcc/g++ AND x86_64-w64-mingw32-gcc/g++
#        Debian/Ubuntu:  apt-get install -y gcc-mingw-w64-i686 g++-mingw-w64-i686 \
#                                          gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64
#    - Python 3.8+ with AMBuild (pip install ambuild)
#    - Git
#    - Dependencies (same as the Linux build): sourcemod, mmsource, hl2sdk-dods
#
#  NOTE: This is EXPERIMENTAL. MinGW cross-linking against the MSVC import
#  libraries in hl2sdk-dods/lib/public/<arch>/*.lib generally works, but you
#  may need to tweak linker flags (e.g. -Wl,--allow-multiple-definition) for
#  your specific toolchain. For guaranteed-correct Windows binaries, prefer
#  build.bat (native Windows) or the CI Windows job.
#
#  Usage:
#    ./build_windows_cross.sh
#    ./build_windows_cross.sh --no-archive
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_ARCHIVE=1
if [[ "${1:-}" == "--no-archive" ]]; then
  DO_ARCHIVE=0
fi

echo "============================================"
echo "  DODHooks Windows Cross-Build (Linux -> Windows, MinGW-w64)"
echo "============================================"

# ---------- MinGW toolchain check ----------
MINGW_X86=i686-w64-mingw32-gcc
MINGW_X64=x86_64-w64-mingw32-gcc
if ! command -v "$MINGW_X86" >/dev/null 2>&1 || ! command -v "$MINGW_X64" >/dev/null 2>&1; then
  echo "[ERROR] MinGW-w64 not found (need $MINGW_X86 and $MINGW_X64)." >&2
  echo "        Debian/Ubuntu: apt-get install -y gcc-mingw-w64-i686 g++-mingw-w64-i686 \\" >&2
  echo "                                    gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64" >&2
  exit 1
fi

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

# The Windows import libraries live here:
if [[ ! -f "${HL2_ROOT}/hl2sdk-dods/lib/public/x86/tier0.lib" ]]; then
  echo "[WARN] Windows import libs not found at ${HL2_ROOT}/hl2sdk-dods/lib/public/x86/." >&2
  echo "        The cross link step will fail without them." >&2
fi

# ---------- Ensure AMBuild ----------
if ! python3 -c "import ambuild" 2>/dev/null; then
  echo "[INFO] Installing AMBuild..."
  python3 -m pip install --user --upgrade ambuild
fi

# ---------- Build both architectures (MinGW) ----------
build_one() {
  local arch="$1"
  local cc="$2"
  local cxx="$3"
  local build_dir="${SCRIPT_DIR}/build_cross_${arch}"

  echo
  echo "----------------------------------------"
  echo "  Building Windows/${arch} (MinGW: ${cxx})"
  echo "----------------------------------------"
  rm -rf "${build_dir}"
  mkdir -p "${build_dir}"
  (
    cd "${build_dir}"
    export CC="${cc}"
    export CXX="${cxx}"
    export DHOOKS_TARGET_PLATFORM=windows
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

build_one x86  "${MINGW_X86}"  "${MINGW_X86/gcc/g++}"
build_one x64  "${MINGW_X64}"  "${MINGW_X64/gcc/g++}"

# ---------- Stage distribution ----------
echo
echo "[STAGE] Assembling release folder..."
DIST="${SCRIPT_DIR}/dist_windows"
rm -rf "${DIST}"
mkdir -p "${DIST}/addons/sourcemod/extensions/x64"
mkdir -p "${DIST}/addons/sourcemod/gamedata"

if [[ -f "${SCRIPT_DIR}/build_cross_x86/package/addons/sourcemod/extensions/dodhooks.ext.2.dods.dll" ]]; then
  cp -v "${SCRIPT_DIR}/build_cross_x86/package/addons/sourcemod/extensions/dodhooks.ext.2.dods.dll" \
        "${DIST}/addons/sourcemod/extensions/"
else
  echo "[ERROR] 32-bit Windows (.dll) build output missing." >&2
  exit 1
fi

if [[ -f "${SCRIPT_DIR}/build_cross_x64/package/addons/sourcemod/extensions/x64/dodhooks.ext.2.dods.dll" ]]; then
  cp -v "${SCRIPT_DIR}/build_cross_x64/package/addons/sourcemod/extensions/x64/dodhooks.ext.2.dods.dll" \
        "${DIST}/addons/sourcemod/extensions/x64/"
else
  echo "[ERROR] 64-bit Windows (.dll) build output missing." >&2
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
  ARCHIVE="${SCRIPT_DIR}/DODHooks-${VERSION}-sm1.12-windows-cross.tar.gz"
  rm -f "${ARCHIVE}"
  tar -czf "${ARCHIVE}" -C "${DIST}" addons
  echo "  Created: ${ARCHIVE}"
fi

echo
echo "============================================"
echo "  Cross build complete!"
echo "============================================"
echo "  dist_windows/  -> ${DIST}"
echo "  Upload -> addons/sourcemod/extensions/"
echo
ls -la "${DIST}/addons/sourcemod/extensions"

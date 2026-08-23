#!/bin/bash
#
# DODHooks - Setup Dependencies Script
#
# Clones SourceMod and Metamod:Source as siblings for building.
# Run this once before building.
#
# Usage:
#   chmod +x setup_dependencies.sh
#   ./setup_dependencies.sh [sm_branch]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SM_BRANCH="${1:-1.12-dev}"

echo "=========================================="
echo " DODHooks - Setup Dependencies"
echo "=========================================="
echo " SourceMod branch: ${SM_BRANCH}"
echo " Directory: ${SCRIPT_DIR}"
echo "=========================================="
echo ""

# --- Metamod:Source ---
if [ ! -d "${SCRIPT_DIR}/mmsource" ]; then
    echo "[1/2] Cloning Metamod:Source (${SM_BRANCH})..."
    git clone --depth 1 --recurse-submodules -j8 --shallow-submodules \
        -b "${SM_BRANCH}" https://github.com/alliedmodders/metamod-source.git \
        "${SCRIPT_DIR}/mmsource"
    echo "  Done!"
else
    echo "[1/2] Metamod:Source already exists, updating..."
    cd "${SCRIPT_DIR}/mmsource"
    git fetch --depth 1 origin "${SM_BRANCH}" 2>/dev/null || true
    git checkout "${SM_BRANCH}" 2>/dev/null || true
    git pull --ff-only 2>/dev/null || true
    cd "${SCRIPT_DIR}"
    echo "  Done!"
fi

# --- SourceMod ---
if [ ! -d "${SCRIPT_DIR}/sourcemod" ]; then
    echo "[2/2] Cloning SourceMod (${SM_BRANCH})..."
    git clone --depth 1 --recurse-submodules -j8 --shallow-submodules \
        -b "${SM_BRANCH}" https://github.com/alliedmodders/sourcemod.git \
        "${SCRIPT_DIR}/sourcemod"
    echo "  Done!"
else
    echo "[2/2] SourceMod already exists, updating..."
    cd "${SCRIPT_DIR}/sourcemod"
    git fetch --depth 1 origin "${SM_BRANCH}" 2>/dev/null || true
    git checkout "${SM_BRANCH}" 2>/dev/null || true
    git pull --ff-only 2>/dev/null || true
    cd "${SCRIPT_DIR}"
    echo "  Done!"
fi

# --- Symlink public headers ---
echo ""
echo "[3/3] Setting up public headers symlink..."

# The build system expects sourcemod/public/ at certain paths
# Create a symlink so the AMBuildScript can find CDetour, libudis86, etc.
if [ ! -e "${SCRIPT_DIR}/sourcemod/public/smsdk_ext.h" ]; then
    echo "  Warning: sourcemod/public/smsdk_ext.h not found!"
    echo "  The SourceMod clone may be incomplete. Try:"
    echo "    cd ${SCRIPT_DIR}/sourcemod && git submodule update --init --recursive"
else
    echo "  SourceMod public headers found at: ${SCRIPT_DIR}/sourcemod/public/"
fi

# Symlink for convenience (sourcemod/public -> ../../sourcemod/public)
LINK_TARGET="${SCRIPT_DIR}/sourcemod/public"
LINK_NAME="${SCRIPT_DIR}/sourcemod/public"

if [ -e "${LINK_TARGET}/smsdk_ext.h" ]; then
    echo "  Public headers are available."
    echo "  CDetour: $(ls ${LINK_TARGET}/CDetour/ 2>/dev/null | head -3)"
    echo "  libudis86: $(ls ${LINK_TARGET}/libudis86/ 2>/dev/null | head -3)"
fi

echo ""
echo "=========================================="
echo " Setup complete!"
echo "=========================================="
echo ""
echo " Next steps:"
echo "   Linux:  ./build.sh"
echo "   Windows: build.bat"
echo "   Docker: ./build_linux_docker.sh"
echo ""

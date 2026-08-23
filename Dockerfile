# DODHooks - Linux Build Container
#
# Based on the official AlliedModders build container, which already
# provides the full 32-bit / 64-bit toolchains, git and Python.
#
# Usage:
#   docker build -t dodhooks-builder .
#
#   docker run --rm -v $(pwd):/work/dodhooks -w /work/dodhooks \
#     dodhooks-builder bash -c "pip3 install --upgrade ambuild; ./build.sh"

FROM ghcr.io/alliedmodders/build-containers/debian11-clang22:latest

# Install AMBuild (the build driver used by SourceMod extensions).
RUN pip3 install --upgrade ambuild || pip3 install --user --upgrade ambuild || true

WORKDIR /work/dodhooks

# Default command: run the Linux build.
CMD ["bash", "-c", "pip3 install --upgrade ambuild 2>/dev/null; ./build.sh"]

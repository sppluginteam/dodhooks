#!/usr/bin/env bash
# DODHooks - Linux native build entry point.
# Delegates to build_linux.sh (Linux compiles Linux).
# Use bash to invoke build_linux.sh so the wrapper doesn't require the target file to be executable
# (fixes CI runs where the executable bit is not preserved).
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build_linux.sh" "$@"

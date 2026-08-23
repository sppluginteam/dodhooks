#!/usr/bin/env bash
# DODHooks - Linux native build entry point.
# Delegates to build_linux.sh (Linux compiles Linux).
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build_linux.sh" "$@"

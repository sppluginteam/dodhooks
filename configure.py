# vim: set sts=2 sw=2 tw=99 noet:
"""
DODHooks - Configure script

Supports:
  - SourceMod 1.12 / 1.13
  - Metamod:Source 1.12 / 1.13
  - 32-bit (x86) builds for Day of Defeat: Source
"""

import sys
from ambuild2 import run

try:
    from ambuild2 import run
except ImportError:
    sys.stderr.write('AMBuild 2 is required to build this project.\n')
    sys.exit(1)

builder = run.PrepareBuild(sourcePath=sys.path[0])

builder.options.add_option('--hl2sdk-root', type=str, dest='hl2sdk_root', default=None,
                           help='Root search folder for HL2SDKs')
builder.options.add_option('--mms-path', type=str, dest='mms_path', default=None,
                           help='Path to Metamod:Source')
builder.options.add_option('--sm-path', type=str, dest='sm_path', default=None,
                           help='Path to SourceMod')
builder.options.add_option('--enable-debug', action='store_const', const='1', dest='debug',
                           help='Enable debugging symbols')
builder.options.add_option('--enable-optimize', action='store_const', const='1', dest='opt',
                           help='Enable optimization')
builder.options.add_option('-s', '--sdks', default='dods', dest='sdks',
                           help='Build against specified SDKs; valid args are "all", "present", or '
                                'comma-delimited list of engine names (default: %default)')
builder.options.add_option('--arch', default='x86', dest='arch',
                           choices=['x86', 'x64'],
                           help='Target architecture (default: %default)')

builder.Configure()

# Changelog

All notable changes to DODHooks are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.6.0/),
and this project follows SourceMod-style versioning where the extension is
built against SourceMod 1.12.

## [1.6.0] - 2026-08-23

### Added
- Auto-load via the SourcePawn include: `dodhooks.inc` now declares
  `public Extension __ext_dodhooks`, so any plugin that
  `#include <dodhooks>` makes SourceMod automatically load `dodhooks.ext`
  (`dodhooks.ext.2.dods`) at runtime. No `.autoload` marker file or manual
  `sm exts load` is required.
- Single-command builds for both architectures:
  - `build.bat` (Windows) builds x86 + x64 and produces
    `DODHooks-<ver>-sm1.12-windows.zip`.
  - `build.sh` (Linux) builds x86 + x64 and produces
    `DODHooks-<ver>-sm1.12-linux.tar.gz`.
  - `build_linux_docker.sh` runs the Linux build inside the official
    AlliedModders build container.
- Release packaging:
  - 32-bit binary in `extensions/` (default).
  - 64-bit binary in `extensions/x64/` subfolder.
  - GameData copied from repository `gamedata/dodhooks.txt`.
  - `dodhooks.inc` packaged into `scripting/include/`.
- GitHub Actions workflow that builds Windows (x86+x64) and Linux (x86+x64)
  and publishes three release archives on tags:
  - `DODHooks-<tag>-sm1.12-windows.zip`
  - `DODHooks-<tag>-sm1.12-linux.zip`
  - `DODHooks-<tag>-source.zip`
- Bilingual documentation (`README.md` / `README_zh.md`) and this changelog.

### Fixed
- Correct `configure.py` flags: `--arch=x86|x64` (was `--target`) and
  `--sdks=dods` (was `dod`) across all build scripts, `Dockerfile` and CI.
- `PackageScript` now copies GameData from the repository's
  `gamedata/dodhooks.txt` and the include from
  `sourcemod/scripting/include/dodhooks.inc` (previously referenced the wrong
  paths).

### Changed
- Consolidated build scripts; removed the broken Windows→Linux cross-compile
  attempt and redundant `docker/`, `scripts/`, `build_linux.sh` files.
- GameData default section documented as targeting Day of Defeat: Source
  (game folder `dod`).

### Compatibility
- SourceMod 1.12 / 1.13
- Metamod:Source 1.11 / 1.12
- Windows and Linux, 32-bit and 64-bit

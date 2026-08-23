# DODHooks

> **Day of Defeat: Source 的 SourceMod 扩展（提供函数钩子与原生函数）**

[![CI](https://github.com/kittenks/dodhooks/workflows/CI/badge.svg)](https://github.com/kittenks/dodhooks/actions)

## 关于

DODHooks 是一个面向 **Day of Defeat: Source（胜利之日：起源）** 的 SourceMod 扩展，提供：

- **钩子（Detours）**：对关键游戏函数进行拦截，例如语音命令、加入兵种、头盔弹飞、重生、波次时间、获胜队伍、回合状态、玩家状态以及炸弹目标状态。
- **原生函数（Natives）**：供 SourcePawn 插件控制玩家兵种、控制点图标、回合计时器以及游戏规则。
- **转发（Forwards）**：允许插件拦截并修改游戏事件的钩子。

本版本是一个持续维护的分支，具备以下特性：

- 支持 **SourceMod 1.12 与 1.13**
- 支持 **Metamod:Source 1.12 与 1.13**
- 同时编译 **32 位（x86）与 64 位（x86_64）** 架构
- 可在 **Windows 与 Linux** 上运行
- 使用最新的 **AMBuild 2.x** 构建系统
- 修复了旧版本中存在的服务器崩溃问题
- 采用现代 C++17 编译器标志

## 要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| SourceMod | 1.12 / 1.13 | 构建时需要源代码 |
| Metamod:Source | 1.12 / 1.13 | 构建时需要源代码 |
| AMBuild | 2.2+ | 基于 Python 的构建系统 |
| Python | 3.8+ | AMBuild 所需 |
| 编译器 | GCC 9+ / Clang 10+ / MSVC 2019+ | 需支持 C++17 |

## 构建依赖

### Linux

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y build-essential clang-22 python3 python3-pip git

# 安装 AMBuild
pip3 install --upgrade git+https://github.com/alliedmodders/ambuild.git
```

### Windows

```powershell
# 从 python.org 安装 Python 3.12+
# 安装 Visual Studio 2019+（社区版即可）
# 从 git-scm.com 安装 Git

# 安装 AMBuild
python -m pip install --upgrade git+https://github.com/alliedmodders/ambuild.git
```

## 构建

一次运行即可同时产出 32 位（x86）与 64 位（x64）二进制文件，并暂存到可直接发布的 `dist/` 目录（扩展通过 SourcePawn 头文件实现自动加载）。

### 快速开始（Linux）

```bash
# 克隆仓库
git clone https://github.com/kittenks/dodhooks.git
cd dodhooks

# 克隆依赖
git clone --depth 1 --recurse-submodules -b 1.12-dev https://github.com/alliedmodders/metamod-source.git mmsource
git clone --depth 1 --recurse-submodules -b 1.12-dev https://github.com/alliedmodders/sourcemod.git sourcemod

# 同时构建 32 位 + 64 位，然后暂存到 dist/ 并生成 .tar.gz
./build.sh
```

产物位于 `dist/addons/sourcemod/extensions/`，其中包含 32 位的 `.so`、存放 64 位 `.so` 的 `x64/` 子目录、随附的 `dodhooks.inc` 头文件，以及 `dist/addons/sourcemod/gamedata/dodhooks.txt`。

### Windows 构建

```powershell
# 打开“VS 开发人员命令提示符”（或任意终端，脚本会自动定位 vcvarsall.bat）

git clone https://github.com/kittenks/dodhooks.git
cd dodhooks

git clone --depth 1 --recurse-submodules -b 1.12-dev https://github.com/alliedmodders/metamod-source.git mmsource
git clone --depth 1 --recurse-submodules -b 1.12-dev https://github.com/alliedmodders/sourcemod.git sourcemod

# 同时构建 32 位 + 64 位，然后暂存到 dist/ 并生成 .zip
build.bat
```

### 手动 / 进阶（原生 AMBuild）

如果希望手动构建单一架构：

```bash
mkdir build && cd build
python3 ../configure.py \
    --sm-path ../sourcemod \
    --mms-path ../mmsource \
    --arch=x86 \
    --enable-optimize
ambuild
# 64 位：使用 --arch=x64
```

> **注意：** configure 参数为 `--arch=x86` / `--arch=x64`（而非 `--target`）。SDK 选择参数为 `--sdks=dods`。

### 生成 Visual Studio 工程（Windows）

```powershell
python ..\configure.py `
    --sm-path ..\sourcemod `
    --mms-path ..\mmsource `
    --arch=x86 `
    --enable-optimize `
    --gen=vs
```

## Docker 构建

仓库提供了 `Dockerfile` 与一键封装脚本（`build_linux_docker.sh`），可用于简单、可复现的 Linux 构建（无需本机工具链）：

```bash
# 在官方 AlliedModders 容器内构建（依赖会克隆到 deps/）：
./build_linux_docker.sh

# 或手动执行：
docker build -t dodhooks-builder .
docker run --rm -v $(pwd):/work/dodhooks -w /work/dodhooks dodhooks-builder \
    bash -c "pip3 install --upgrade ambuild; ./build.sh"
```

## 安装到服务器

构建完成后，将 `dist/` 目录的内容复制到游戏服务器的根目录：

```
addons/
└── sourcemod/
    ├── extensions/
    │   ├── dodhooks.ext.2.dods.dll        (Windows 32 位)
    │   ├── dodhooks.ext.2.dods.so         (Linux 32 位)
    │   └── x64/
    │       ├── dodhooks.ext.2.dods.dll    (Windows 64 位)
    │       └── dodhooks.ext.2.dods.so     (Linux 64 位)
    ├── gamedata/
    │   └── dodhooks.txt
    └── scripting/
        └── include/
            └── dodhooks.inc
```

### 加载扩展

该扩展采用**自动加载**：任何 `#include <dodhooks>` 的插件都会让 SourceMod 在运行时自动加载 `dodhooks.ext`（解析为 `dodhooks.ext.2.dods`）。这一机制由 `dodhooks.inc` 中的 `public Extension __ext_dodhooks` 代码块实现，因此**无需** `.autoload` 标记文件或手动命令。

如需手动加载（例如调试），可使用：

```
sm exts load dodhooks
```

> 不要使用 `meta load` —— 该命令用于 Metamod:Source 插件，对扩展的 `.dll`/`.so` 会提示 “File type not supported”。

## 可用原生函数

| 原生函数 | 说明 |
|----------|------|
| `DOD_GetPlayerClass(client)` | 获取玩家当前兵种 |
| `DOD_SetPlayerClass(client, class)` | 设置玩家当前兵种 |
| `DOD_GetDesiredPlayerClass(client)` | 获取期望的玩家兵种 |
| `DOD_SetDesiredPlayerClass(client, class)` | 设置期望的玩家兵种 |
| `DOD_PopHelmet(client, velocity[3], origin[3])` | 强制头盔弹飞 |
| `DOD_SetNumControlPoints(num)` | 设置控制点数量 |
| `DOD_PrecacheCPIcon(material)` | 预缓存控制点图标材质 |
| `DOD_SetCPIcons(index, ...)` | 设置控制点的图标 |
| `DOD_SetCPVisible(index, visible)` | 显示/隐藏控制点 |
| `DOD_PauseTimer(timer)` | 暂停回合计时器 |
| `DOD_ResumeTimer(timer)` | 恢复回合计时器 |
| `DOD_SetTimeRemaining(timer, seconds)` | 设置计时器剩余时间 |
| `DOD_GetTimeRemaining(timer)` | 获取计时器剩余时间 |
| `DOD_RespawnPlayer(client, useClass)` | 强制玩家重生 |
| `DOD_AddWaveTime(team, delay)` | 为某队伍增加波次时间 |
| `DOD_SetWinningTeam(team)` | 设置获胜队伍 |
| `DOD_SetRoundState(state)` | 设置回合状态 |
| `DOD_SetPlayerState(client, state)` | 设置玩家状态 |
| `DOD_SetBombTargetState(entity, state)` | 设置炸弹目标状态 |

## 可用转发（钩子）

| 转发 | 说明 |
|------|------|
| `OnVoiceCommand(client, &voiceCommand)` | 使用语音命令时调用 |
| `OnJoinClass(client, &playerClass)` | 玩家加入兵种时调用 |
| `OnPopHelmet(client, velocity[3], origin[3])` | 头盔弹飞时调用 |
| `OnPlayerRespawn(client)` | 玩家即将重生时调用 |
| `OnAddWaveTime(team, &delay)` | 增加波次时间时调用 |
| `OnSetWinningTeam(team)` | 设置获胜队伍时调用 |
| `OnEnterRoundState(&roundState)` | 回合状态改变时调用 |
| `OnEnterPlayerState(client, &playerState)` | 玩家状态改变时调用 |
| `OnEnterBombTargetState(entity, &bombState)` | 炸弹目标状态改变时调用 |

## 与原版的区别

- **SourceMod 1.12/1.13 兼容** —— 更新了 API 与构建系统
- **64 位支持** —— 可在 64 位服务器上编译并运行
- **现代 C++17** —— 更新了编译器标志与标准
- **修复崩溃** —— 解决了多处服务器崩溃场景：
  - 钩子回调中的 NULL 指针检查
  - 64 位 ThisCall 调用约定下的正确栈对齐
  - 更安全的 gamedata 签名解析并附带更清晰的错误信息
  - 防止无效的实体引用
- **改进错误处理** —— 针对缺失 gamedata 或签名给出更清晰的错误信息
- **GitHub Actions CI** —— 自动构建 4 种平台组合（Win/Linux × x86/x64）
- **Docker 支持** —— 通过容器化实现可复现构建

## 许可

GPL v2 —— 详见 [LICENSE](LICENSE) 文件。

## 致谢

- **Andersso** —— 原始作者
- **ChesterSmitty** —— 前任维护者
- **Apfelwurm** —— CI 改进
- **DNA-styx** —— Gamedata 文件
- **Kittenks** —— 当前维护者（1.12/1.13 更新、构建与打包）—— https://github.com/kittenks/dodhooks
- **AlliedModders** —— SourceMod、Metamod:Source、AMBuild

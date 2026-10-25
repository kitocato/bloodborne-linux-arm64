# Bloodborne on Linux ARM64 (Bloodborne-Android port, desktop Linux build)

An unofficial Linux aarch64 build of [ducvd89/Bloodborne-Android](https://github.com/ducvd89/Bloodborne-Android) 2.0.0 (commit `ab06215`).
That port runs the game's own code as native ARM64, compiled ahead of time on a PC, and renders through shadPS4's Vulkan renderer.
Upstream targets Android. This repository shows how to build and run it on a regular glibc Linux on ARM.

It was tested on an **AYN Odin 3** (Snapdragon 8 Elite, Adreno 830, Turnip / Mesa 26.2) running **Armada OS** (Fedora 44), in Steam Game Mode (gamescope).

> This is not an official release of the port and is not affiliated with its author, with bloodborne_pc, or with FromSoftware / Sony.
> No game files and no game code are distributed here.
> Built and written up with the help of an AI assistant (Claude).

## What you need

- A decrypted dump of Bloodborne **CUSA03173 (EU), version 01.09**: the game folder with `eboot.bin` and `sce_module/`. Use your own disc.
- `libbbaot.so`, the game's code compiled to ARM64. **You build it yourself** on a PC (Windows or Linux x86-64 with AVX2) with the free
  [Bloodborne Android Rebuild Tool](https://github.com/ducvd89/Bloodborne-android-rebuild-tool) (`bb-recomp`, v1.0.0, ABI 1), from your own PKGs or game files.
  It is derived from the game, so it cannot be shared. Take `aot/libbbaot.so` and `aot/libbbaot.json` from its output.
- Linux aarch64 with Vulkan 1.3+. Built and tested with Fedora 44 libraries in a toolbox.

## Install (prebuilt)

1. Unpack the release archive, for example to `~/Games/bloodborne-linux-arm64/`.
2. Put the game dump into `game/` (so that `game/eboot.bin` exists), or set `BB_GAME_DIR`.
3. Put `libbbaot.so` and `libbbaot.json` into `aot/`.
4. Run `./bloodborne.sh`. The first start prepares the image in `data/out/` and takes a while. Saves and `bbport.ini` live in `data/`.

For Steam Game Mode, add `bloodborne.sh` as a non-Steam game.
- Leave "Start in" **unquoted**.
- On Armada, the launch option `/usr/libexec/armada/armada-game-launch %command%` is fine.

The in-game port menu is on **L3+R3** (or Insert).

## Build it yourself

On an aarch64 Fedora-based system with `toolbox`:

```bash
git clone https://github.com/kitocato/bloodborne-linux-arm64
cd bloodborne-linux-arm64
bash build-odin.sh          # sources in ~/src, output in dist/bloodborne-linux-arm64/
```

What the script does, on top of upstream `build.sh`:
- **Vulkan-Headers v1.4.363 and magic_enum v0.9.7 headers:** Fedora 44's `vulkan.hpp` (1.4.341) lacks types the renderer uses, and its magic_enum has no `magic_enum/` include dir.
- **`shims/cmake/Zydis`:** Fedora's zydis ships no CMake config, so this provides `Zydis::Zydis` from pkg-config.
- **`patches/build-sh-no-werror.patch`:** GCC 16 raises a format-truncation warning in `src/probe.c`, which `-Werror` turns into an error.
- **`shims/bionic-libm`:** bb-recomp builds `libbbaot.so` with the Android NDK. It imports `sin cos tan exp2 log2 atan2 fmod remainder` with bionic's symbol version `LIBC`, which glibc's libm doesn't have. This small `libm.so` defines that version and forwards to glibc.
- **Bundled `lib/`:** the toolbox's newer `libstdc++.so.6` (GLIBCXX_3.4.36) and `libgcc_s`, plus `miniz` and `Zydis`/`Zycore`, so the binaries run on the host.

## Settings and performance (Odin 3)

The GPU is the limit, and CPU threads stay below 60%. Settings that were used:
- GSR 2 upscaler, Balanced or Quality preset;
- 720p output;
- model detail 1;
- DoF, SSAO, dynamic-light shadows and the game's AA off.

This gives a locked **30 FPS** with good input response.

## Known issues

- **Startup resolution patch → AOT stop.** With `output_res` other than 1080p and `live_resolution=0`, the port patches the scene size into game code. `libbbaot.so` has no variant for that function, and the game stops with `native code for a patched or hooked function has no variant at +0x1d969f0`. `bloodborne.sh` sets `BB_LIVE_RES=1` to avoid it.
- **The in-game menu rewrites the whole `bbport.ini`.** It writes its in-memory values on every change, and only list resolutions (720p, 1080p, 1440p, 2160p) are kept. Edit the file only while the game is closed.
- **60 FPS limit.** At 60, the GPU-bound game queues frames and input lags. `bloodborne.sh` defaults to `BB_FPS=30`; set `BB_FPS=60` to try.
- **lsfg-vk (external Vulkan layer) frame generation.** It drops the game from 30 to about 19 real FPS here, whatever the present mode, window size or flow scale. The Android build has its own integrated frame generation (Bloodframe), which is not available on desktop Linux yet.
- **Steam Game Mode Quick Access Menu** can hang while the game runs, because the CEF GPU raster backlog piles up behind the GPU-heavy game. Killing the hung `steamwebhelper` renderer process restores it.

## License

The port is GPL-2.0, see `LICENSE` (copied from upstream). The build scripts and shims here are under the same license.
Third-party libraries bundled in the release are listed in `THIRD_PARTY.md`.
Source for the binaries:
- upstream [Bloodborne-Android @ ab06215](https://github.com/ducvd89/Bloodborne-Android/tree/ab062151caf5969478f8ed5da20d2060520701c1) and its submodules;
- plus `patches/` and `shims/` from this repository.

Credits go to ducvd89 (Bloodborne-Android), deadinside28 ([bloodborne_pc](https://github.com/deadinside28/bloodborne_pc)), MaSieS4Fun (ARM_bloodborne_pc), the shadPS4 and FEX-Emu projects, and everyone listed upstream.

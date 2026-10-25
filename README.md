# Bloodborne on Linux ARM64 (Bloodborne-Android port, desktop Linux build)

An unofficial Linux aarch64 build of [ducvd89/Bloodborne-Android](https://github.com/ducvd89/Bloodborne-Android) 2.0.1 (commit `f141387`).
That port runs the game's own code as native ARM64, compiled ahead of time on a PC, and renders through shadPS4's Vulkan renderer.
Upstream targets Android. This repository shows how to build and run it on a regular glibc Linux on ARM.

It was tested on an **AYN Odin 3** (Snapdragon 8 Elite, Adreno 830, Turnip / Mesa 26.2) running **Armada OS** (Fedora 44), in Steam Game Mode (gamescope).

> This is not an official release of the port and is not affiliated with its author, with bloodborne_pc, or with FromSoftware / Sony.
> No game files and no game code are distributed here.
> Built and written up with the help of an AI assistant (Claude).

## What you need

- A decrypted dump of Bloodborne **CUSA03173 (EU), version 01.09**: the game folder with `eboot.bin` and `sce_module/`. Use your own disc.
- `libbbaot.so`, the game's code compiled to ARM64. **You build it yourself** on a PC (Windows or Linux x86-64 with AVX2) with the free
  [Bloodborne Android Rebuild Tool](https://github.com/ducvd89/Bloodborne-android-rebuild-tool) (`bb-recomp`, v1.0.0 or 1.1.0, ABI 1), from your own PKGs or extracted game.
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
- For frame generation, see the section below.

The in-game port menu is on **L3+R3** (or Insert).

**The Old Hunters:** since 2.0.1 the port reports the DLC as installed (its data ships with patch 1.09). If you don't own it, i.e. you have the plain edition rather than Game of the Year, set `BB_DLC=0` (for example in `tune.env` next to `bloodborne.sh`).

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

## Frame generation (30 → 60)

The release includes the **lsfg-vk 1.0.0** Vulkan layer (MIT, built with clang) in `lsfg1/`. It needs your own `Lossless.dll` from Lossless Scaling.

`bloodborne.sh` turns it on when the game is started through the wrapper of the [LSFG-VK 2 ARM64 Decky plugin](https://github.com/razoomnik/lsfg-vk2-arm64-odin3), i.e. when `LSFGVK_PROFILE` is set.
- The launch option is `/usr/libexec/armada/armada-game-launch ~/.local/bin/lsfg-vk2-arm64 %command%`.
- The plugin's 2.0 layer is switched off for this game only (`DISABLE_LSFGVK=1`). The 1.0 layer from `lsfg1/` runs instead.
- It runs with the **immediate** present mode and follows the plugin's settings (`dll`, `multiplier`, `flow_scale`, `performance_mode` from `~/.config/decky-lsfg-vk2-arm64/conf.toml`) **while the game runs**.
  - The launcher mirrors them into `lsfg1/conf.toml` once a second.
  - lsfg-vk reloads that file, so a change in the plugin applies within a second or two.
- Multiplier 1 turns it off: frames pass through. Other games keep using the plugin's 2.0 layer as usual.
- `VK_IMPLICIT_LAYER_PATH` is set to `lsfg1/` plus `~/.local/share/vulkan/implicit_layer.d`, so the user's own implicit layers stay active.

Measured on the Odin 3, x2 with a 30 FPS cap, standing still in the same spot each time:

| Layer | Time inside `vkQueuePresentKHR` | Real FPS | Shown |
|---|---|---|---|
| lsfg-vk 2.0-dev (plugin) | ~14 ms | ~19 | ~38 |
| lsfg-vk 1.0, FIFO | ~19 ms | 19–23 | jittery |
| the port's FSR 3.1 FG (`BB_FRAME_GEN=1`) | n/a | ~18 | smears the UI |
| **lsfg-vk 1.0, immediate** | **0.4 ms** | **30** | **~60** |

- **x3** costs too much GPU time: the present waits again, at about 28 real FPS.
- **An uncapped game** (`BB_FPS=60`) stays at about 30 real FPS with frame generation, so the cap costs nothing.

The port holds its submission lock across `vkQueuePresentKHR`, so a layer that waits there for vblank or for the GPU stalls the game's command submission.

## Known issues

- **Startup resolution patch → AOT stop.** With `output_res` other than 1080p and `live_resolution=0`, the port patches the scene size into game code. `libbbaot.so` has no variant for that function, and the game stops with `native code for a patched or hooked function has no variant at +0x1d969f0`. `bloodborne.sh` sets `BB_LIVE_RES=1` to avoid it.
- **The in-game menu rewrites the whole `bbport.ini`.** It writes its in-memory values on every change, and only list resolutions (720p, 1080p, 1440p, 2160p) are kept. Edit the file only while the game is closed.
- **60 FPS limit.** At 60, the GPU-bound game queues frames and input lags. `bloodborne.sh` defaults to `BB_FPS=30`; set `BB_FPS=60` to try.
- **The lsfg-vk 2.0 layer** drops the game to about 19 real FPS. Use the bundled 1.0 layer instead, as described above.

## License

The port is GPL-2.0, see `LICENSE` (copied from upstream). The build scripts and shims here are under the same license.
Third-party libraries bundled in the release are listed in `THIRD_PARTY.md`.
Source for the binaries:
- upstream [Bloodborne-Android @ f141387](https://github.com/ducvd89/Bloodborne-Android/tree/f141387d5fb96cc31b1addc15d43b0d96e5dd28e) and its submodules;
- plus `patches/` and `shims/` from this repository.


Credits go to ducvd89 (Bloodborne-Android), deadinside28 ([bloodborne_pc](https://github.com/deadinside28/bloodborne_pc)), MaSieS4Fun (ARM_bloodborne_pc), the shadPS4 and FEX-Emu projects, and everyone listed upstream.

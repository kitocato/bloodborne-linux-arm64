#!/bin/bash
# Bloodborne through the Bloodborne-Android port (ducvd89, GPL-2.0) built for Linux aarch64.
# The game's code runs as native ARM64 from aot/libbbaot.so, which you build yourself on a PC
# with bb-recomp from your own copy of the game. Log: launch.log next to this script.
B=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
exec >>"$B/launch.log" 2>&1
echo "=== $(date) args: $*"
# Steam gives non-Steam shortcuts a reduced PATH.
export PATH=/usr/bin:$PATH
# lib/: a newer libstdc++ and miniz/Zydis than the host has, and the bionic libm shim that
# libbbaot.so needs (bb-recomp builds it for Android: it imports math functions @LIBC).
export LD_LIBRARY_PATH=$B/lib:$B/app/bin/gpu:$B/app/bin/cpu
export BB_PREBUILT=1
export BB_DATA_DIR=$B/data
# The game folder: the decrypted CUSA03173 (EU) 01.09 dump with eboot.bin and sce_module/.
export BB_GAME_DIR=${BB_GAME_DIR:-$B/game}
export BB_AOT=${BB_AOT:-$B/aot/libbbaot.so}
# 30: when the GPU is the limit at 60, frames queue up and input lags; 30 is the game's own rate.
export BB_FPS=${BB_FPS:-30}
# Outputs other than 1080p must use live resolution changes: the startup resolution patch edits
# game code that libbbaot.so has no variant for, and the game stops (AOT miss at +0x1d969f0).
export BB_LIVE_RES=1
# Frame generation: when started through the Decky lsfg-vk plugin's wrapper (LSFGVK_PROFILE set), use the
# lsfg-vk 1.0 layer in lsfg1/ (PancakeTAS v1.0.0, built with clang) instead of the plugin's 2.0 layer. The 2.0
# layer waits ~14 ms inside every vkQueuePresentKHR, which drops the game from 30 to ~19 real FPS; 1.0 with
# the immediate present mode does not wait (30 real, 60 shown at x2). Its settings are read from the plugin's
# conf.toml at launch; multiplier 1 turns it off.
if [ -n "$LSFGVK_PROFILE" ] && [ -f "$B/lsfg1/liblsfg-vk.so" ]; then
    conf=${LSFGVK_CONFIG:-$HOME/.config/decky-lsfg-vk2-arm64/conf.toml}
    conf_value() { sed -n "s/^$1 *= *\"\{0,1\}\([^\"]*\)\"\{0,1\} *$/\1/p" "$conf" | head -1; }
    lsfg_dll=$(conf_value dll) lsfg_mult=$(conf_value multiplier)
    export DISABLE_LSFGVK=1
    if [ "${lsfg_mult:-1}" -ge 2 ] 2>/dev/null && [ -f "$lsfg_dll" ]; then
        unset DISABLE_LSFG
        export VK_IMPLICIT_LAYER_PATH=$B/lsfg1 BB_LSFG=1 BB_PRESENT_MODE=${BB_PRESENT_MODE:-Fifo}
        export LSFG_LEGACY=1 LSFG_DLL_PATH="$lsfg_dll" LSFG_MULTIPLIER=$lsfg_mult \
            LSFG_FLOW_SCALE=$(conf_value flow_scale) LSFG_EXPERIMENTAL_PRESENT_MODE=immediate \
            LSFG_PERFORMANCE_MODE=$([ "$(conf_value performance_mode)" = true ] && echo 1 || echo 0)
        echo "Frame generation: lsfg-vk 1.0 x$lsfg_mult, flow scale $LSFG_FLOW_SCALE"
    fi
fi
# Optional per-install overrides (A/B tests).
[ -f "$B/tune.env" ] && . "$B/tune.env"
if [ ! -f "$BB_AOT" ]; then echo "No $BB_AOT: build it with bb-recomp (see README)." >&2; exit 1; fi
cd "$B/app"
exec bash run.sh "$@"

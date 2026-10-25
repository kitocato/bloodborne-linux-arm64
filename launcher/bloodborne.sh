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
# the immediate present mode does not wait (30 real, 60 shown at x2). Its settings follow the plugin's conf.toml
# while the game runs: lsfg1/conf.toml is rewritten when they change, and the layer reloads it (multiplier 1:
# off, frames pass through).
if [ -n "$LSFGVK_PROFILE" ] && [ -f "$B/lsfg1/liblsfg-vk.so" ]; then
    conf=${LSFGVK_CONFIG:-$HOME/.config/decky-lsfg-vk2-arm64/conf.toml}
    conf_value() { sed -n "s/^$1 *= *\"\{0,1\}\([^\"]*\)\"\{0,1\} *$/\1/p" "$conf" | head -1; }
    lsfg_conf() {
        local mult flow perf
        mult=$(conf_value multiplier) flow=$(conf_value flow_scale) perf=$(conf_value performance_mode)
        printf 'version = 1\n\n[global]\ndll = "%s"\n\n[[game]]\nexe = "bb-probe"\nmultiplier = %s\n' \
            "$(conf_value dll)" "${mult:-1}"
        printf 'flow_scale = %s\nperformance_mode = %s\nexperimental_present_mode = "immediate"\n' \
            "${flow:-1.0}" "$([ "$perf" = true ] && echo true || echo false)"
    }
    lsfg_sync() {
        local new
        new=$(lsfg_conf)
        [ "$new" = "$(cat "$B/lsfg1/conf.toml" 2>/dev/null)" ] && return
        printf '%s\n' "$new" > "$B/lsfg1/conf.toml.tmp" && mv -f "$B/lsfg1/conf.toml.tmp" "$B/lsfg1/conf.toml"
    }
    export DISABLE_LSFGVK=1
    if [ -f "$(conf_value dll)" ]; then
        unset DISABLE_LSFG
        lsfg_sync
        export LSFG_CONFIG=$B/lsfg1/conf.toml
        # The user's implicit layers stay visible (VK_ADD_IMPLICIT_LAYER_PATH is ignored once this is set).
        export VK_IMPLICIT_LAYER_PATH=$B/lsfg1:${XDG_DATA_HOME:-$HOME/.local/share}/vulkan/implicit_layer.d
        export BB_LSFG=1 BB_PRESENT_MODE=${BB_PRESENT_MODE:-Fifo}
        echo "Frame generation: lsfg-vk 1.0 x$(conf_value multiplier), flow scale $(conf_value flow_scale); follows the plugin"
        # This shell's PID becomes the game's (exec below); follow the plugin until the game exits.
        game=$$
        (while kill -0 "$game" 2>/dev/null; do lsfg_sync; sleep 1; done) &
    fi
fi
# Optional per-install overrides (A/B tests).
[ -f "$B/tune.env" ] && . "$B/tune.env"
if [ ! -f "$BB_AOT" ]; then echo "No $BB_AOT: build it with bb-recomp (see README)." >&2; exit 1; fi
cd "$B/app"
exec bash run.sh "$@"

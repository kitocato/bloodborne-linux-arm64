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
# Optional per-install overrides (A/B tests).
[ -f "$B/tune.env" ] && . "$B/tune.env"
if [ ! -f "$BB_AOT" ]; then echo "No $BB_AOT: build it with bb-recomp (see README)." >&2; exit 1; fi
cd "$B/app"
exec bash run.sh "$@"

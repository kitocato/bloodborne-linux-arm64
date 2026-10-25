#!/usr/bin/env bash
# Build the Bloodborne-Android port (ducvd89, GPL-2.0) for Linux aarch64 inside a Fedora toolbox
# (tested on Armada OS / Fedora 44 on an AYN Odin 3) and package the runtime into dist/.
# Usage: ./build-odin.sh            (SRC=~/src, BOX=bbport-build by default)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
src=${SRC:-$HOME/src}
box=${BOX:-bbport-build}
commit=ab062151caf5969478f8ed5da20d2060520701c1   # Bloodborne-Android 2.0.0 (Beta 1)
fork=$src/Bloodborne-Android
dist=$here/dist/bloodborne-linux-arm64
mkdir -p "$src"

# 1. Build container with the toolchain and libraries.
if ! toolbox list -c | awk 'NR > 1 { print $2 }' | grep -qx "$box"; then
    toolbox create -y "$box"
fi
toolbox run -c "$box" sudo dnf install -y --skip-unavailable \
    gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config python3 binutils git zlib-devel \
    vulkan-headers vulkan-loader-devel SDL3-devel \
    libavcodec-free-devel libavformat-free-devel libavutil-free-devel libswresample-free-devel libswscale-free-devel \
    boost-devel fmt-devel magic_enum-devel robin-map-devel xxhash-devel VulkanMemoryAllocator-devel \
    glslang glslang-devel spirv-cross spirv-cross-devel spirv-headers-devel spirv-tools-devel zydis-devel miniz-devel \
    libX11-devel libxcb-devel xorg-x11-proto-devel wayland-devel

# 2. Sources: the port at the tested commit, and newer headers than Fedora 44 ships
#    (vulkan.hpp 1.4.341 lacks types the renderer uses; the port expects <magic_enum/magic_enum.hpp>).
[ -d "$fork/.git" ] || git clone https://github.com/ducvd89/Bloodborne-Android "$fork"
git -C "$fork" checkout -q "$commit"
git -C "$fork" submodule update --init --recursive
[ -d "$src/Vulkan-Headers" ] || git clone -q --depth 1 --branch v1.4.363 https://github.com/KhronosGroup/Vulkan-Headers.git "$src/Vulkan-Headers"
[ -d "$src/magic_enum" ] || git clone -q --depth 1 --branch v0.9.7 https://github.com/Neargye/magic_enum.git "$src/magic_enum"

# 3. bb-probe is built with -Werror; GCC 16 warns (format-truncation) in src/probe.c.
if ! git -C "$fork" apply --reverse --check "$here/patches/build-sh-no-werror.patch" 2>/dev/null; then
    git -C "$fork" apply "$here/patches/build-sh-no-werror.patch"
fi

# 4. Build. Fedora's zydis has no CMake config: shims/cmake provides Zydis::Zydis from pkg-config.
(cd "$fork" && toolbox run -c "$box" env BB_LTO=OFF CMAKE_PREFIX_PATH="$here/shims/cmake" \
    CXXFLAGS="-I$src/Vulkan-Headers/include -I$src/magic_enum/include" bash build.sh)

# 5. Package: the layout bloodborne.sh expects.
rm -rf "$dist" && mkdir -p "$dist"/{app/bin/gpu,app/bin/cpu,app/logs,lib,aot,data,game}
cp "$fork/run.sh" "$dist/app/" && cp -r "$fork/scripts" "$fork/patches" "$dist/app/"
install -m755 "$fork/out/bb-probe" "$fork/out/bb-gpu-capabilities" "$dist/app/bin/"
install -m755 "$fork/out/gpu/libbbgpu.so" "$dist/app/bin/gpu/"
install -m755 "$fork/out/cpu/libbbcpu.so" "$dist/app/bin/cpu/"
toolbox run -c "$box" strip "$dist/app/bin/bb-probe" "$dist/app/bin/gpu/libbbgpu.so" "$dist/app/bin/cpu/libbbcpu.so"
toolbox run -c "$box" sh -c "cp -L /usr/lib64/libstdc++.so.6 /usr/lib64/libgcc_s.so.1 /usr/lib64/libminiz.so.3 \
    /usr/lib64/libZydis.so.5 /usr/lib64/libZycore.so.1 '$dist/lib/'"
toolbox run -c "$box" gcc -O2 -fPIC -shared -fno-builtin -Wl,-soname,libm.so \
    -Wl,--version-script="$here/shims/bionic-libm/bionic_libm.map" "$here/shims/bionic-libm/bionic_libm.c" -o "$dist/lib/libm.so"
install -m755 "$here/launcher/bloodborne.sh" "$dist/"
cp "$fork/LICENSE" "$dist/LICENSE"
cp "$here/README.md" "$here/THIRD_PARTY.md" "$dist/"
echo "Packaged $dist"

# Third-party components in the release archive

| File | Project | License |
|---|---|---|
| `app/` (run.sh, scripts, patches, bin/) | [ducvd89/Bloodborne-Android](https://github.com/ducvd89/Bloodborne-Android) @ ab06215 and its submodules (shadPS4 renderer, FSR-Vulkan, Snapdragon GSR, imgui, LibAtrac9, sirit, …) | GPL-2.0 (port); submodules under their own licenses, see upstream |
| `lib/libstdc++.so.6`, `lib/libgcc_s.so.1` | GCC 16 runtime from Fedora 44 | GPL-3.0 with the GCC Runtime Library Exception |
| `lib/libminiz.so.3` | [miniz](https://github.com/richgel999/miniz), Fedora 44 package | MIT |
| `lib/libZydis.so.5`, `lib/libZycore.so.1` | [Zydis](https://github.com/zyantific/zydis) / [Zycore](https://github.com/zyantific/zycore-c), Fedora 44 packages | MIT |
| `lsfg1/liblsfg-vk.so` | [lsfg-vk](https://github.com/PancakeTAS/lsfg-vk) v1.0.0 by PancakeTAS (with its submodules dxbc, pe-parse, toml11, volk); `lsfg1/LICENSE.md` | MIT |
| `lib/libm.so` | `shims/bionic-libm` in this repository | GPL-2.0 |

No game files and no `libbbaot.so` are included.

# Fedora ships zydis with pkg-config only; the project wants a CMake package with Zydis::Zydis.
find_package(PkgConfig REQUIRED)
pkg_check_modules(ZYDIS_PC REQUIRED IMPORTED_TARGET zydis)
if(NOT TARGET Zydis::Zydis)
  add_library(Zydis::Zydis INTERFACE IMPORTED)
  target_link_libraries(Zydis::Zydis INTERFACE PkgConfig::ZYDIS_PC Zycore)
endif()
set(Zydis_FOUND TRUE)

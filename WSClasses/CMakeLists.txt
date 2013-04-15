cmake_minimum_required(VERSION 2.8)


# Dev tool directories
set(WS_LLVM_BIN_DIR ${WiiStep_BINARY_DIR}/llvm/bin)
set(WS_DKPPC_BIN_DIR ${WiiStep_BINARY_DIR}/devkitPPC/bin)

# PPC include/lib directories
set(WS_PPC_INCLUDE_DIRS ${WiiStep_BINARY_DIR}/devkitPPC/powerpc-eabi/include;${WiiStep_BINARY_DIR}/libogc/include;${WiiStep_SOURCE_DIR}/gnustep-libobjc2;${WiiStep_SOURCE_DIR}/gnustep-base/Headers)
set(WS_PPC_LIB_DIRS ${WiiStep_BINARY_DIR}/devkitPPC/powerpc-eabi/lib;${WiiStep_BINARY_DIR}/libogc/lib/wii)

# Objective-C runtime built files
set(WS_PPC_OBJC_LLVM ${WiiStep_BINARY_DIR}/libobjc-wii.bc)
set(WS_PPC_OBJC_ELF ${WiiStep_BINARY_DIR}/libobjc-wii-asm.a)

# Compile support files
set(WS_PPC_PCH ${WiiStep_SOURCE_DIR}/wii-prefix.pch)
set(WS_PPC_SUPPORT_C "-I${WiiStep_BINARY_DIR}/libogc/include ${WiiStep_SOURCE_DIR}/wii-support.c")


# Include WiiStep CMake macros
include(${WiiStep_SOURCE_DIR}/cmake/WiiStepProjectMacros.cmake)

# Include Headers
include_directories(WiiStep)

# WSClasses Target
add_wii_library(wsclasses-wii WSPlatform.m wiilight.c)

# Install headers
file(GLOB WS_CLASSES_HEADERS WiiStep/*.h)
install(FILES ${WS_CLASSES_HEADERS} DESTINATION "${INSTALL_WS_DIR}/${PPC_WII_DIR}/include/WiiStep")

# Install library
install(TARGETS wsclasses-wii
  EXPORT WiiStepTargets
  ARCHIVE DESTINATION "${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib"
  COMPONENT dev)

cmake_minimum_required(VERSION 2.8)
project(WiiStep)

# CMake install stuff

set(CMAKE_MODULE_PATH cmake)


# Default install prefix
if(WIN32 AND NOT CYGWIN)
  set(DEF_CMAKE_INSTALL_PREFIX /)
else()
  set(DEF_CMAKE_INSTALL_PREFIX /opt)
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX ${DEF_CMAKE_INSTALL_PREFIX} 
    CACHE PATH "Installation prefix (system-wide) directory for WiiStep" FORCE)
endif()

set(INSTALL_WS_DIR wiistep CACHE PATH 
  "Installation directory for WiiStep within CMAKE_INSTALL_PREFIX")

set(INSTALL_CMAKE_DIR wiistep/cmake CACHE PATH
  "Installation directory for CMake files")
 
# Make relative paths absolute (needed later on)
foreach(p WS CMAKE)
  set(var INSTALL_${p}_DIR)
  if(NOT IS_ABSOLUTE "${${var}}")
    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
  endif()
endforeach()

set(PPC_WII_DIR ppc-wii)

# Clang and LLVM

set(LLVM_DIR ${PROJECT_BINARY_DIR}/llvm/bin)
set(CLANG_DIR ${LLVM_DIR})

add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/llvm 
COMMAND mkdir ARGS -p ${PROJECT_BINARY_DIR}/llvm)

add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/llvm-built  
WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/llvm
COMMAND cmake ARGS -DCMAKE_INSTALL_PREFIX=${INSTALL_WS_DIR} -DLLVM_DEFAULT_TARGET_TRIPLE="powerpc-generic-eabi" -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_BUILD_RUNTIME=OFF ${CMAKE_SOURCE_DIR}/llvm
COMMAND make
COMMAND touch ARGS ${PROJECT_BINARY_DIR}/llvm-built 
MAIN_DEPENDENCY ${PROJECT_BINARY_DIR}/llvm
COMMENT "Building llvm and clang; This could take awhile...")


install(CODE "execute_process(COMMAND make install WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}/llvm\")")



# Install devkitPPC, libogc and libfat

set(DEVKITPPC_DIR ${PROJECT_BINARY_DIR}/devkitPPC)
file(GLOB DEVKITPPC_BIN_LIST ${DEVKITPPC_DIR}/bin/*)
install(PROGRAMS ${DEVKITPPC_BIN_LIST} DESTINATION ${INSTALL_WS_DIR}/bin)
install(DIRECTORY ${DEVKITPPC_DIR}/powerpc-eabi/include DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR})
file(GLOB_RECURSE DEVKITPPC_LIB_LIST ${DEVKITPPC_DIR}/powerpc-eabi/lib/*.a)
install(FILES ${DEVKITPPC_LIB_LIST} DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib)

set(LIBOGC_DIR ${PROJECT_BINARY_DIR}/libogc)
install(DIRECTORY ${LIBOGC_DIR}/include DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR})
file(GLOB LIBOGC_LIB_LIST ${LIBOGC_DIR}/lib/wii/*.a)
install(FILES ${LIBOGC_LIB_LIST} DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib)

set(LIBFAT_DIR ${PROJECT_BINARY_DIR}/libfat)
install(DIRECTORY ${LIBFAT_DIR}/include DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR})
file(GLOB LIBFAT_LIB_LIST ${LIBFAT_DIR}/lib/wii/*.a)
install(FILES ${LIBFAT_LIB_LIST} DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib)


# Add libobjc2 properties

add_subdirectory(gnustep-libobjc2 EXCLUDE_FROM_ALL)


# WiiStep definitions 

set(WIISTEP TRUE)
set(WIISTEP_PLATFORM "libogc" CACHE STRING 
  "Which Wii HW-abstraction software platform should be used: 'libogc' (default) or 'RVL_SDK'")


# Macro to quickly resolve gnustep-libobjc2 sources

macro(ws_resolve_sources list dir)
get_directory_property(${list} DIRECTORY ${dir} DEFINITION ${list})
foreach(source IN LISTS ${list})
list(APPEND ${list}_LIST "${dir}/${source}")
endforeach(source)
endmacro(ws_resolve_sources)


# Assemble our source lists

ws_resolve_sources(libobjc_C_SRCS gnustep-libobjc2)
ws_resolve_sources(libobjc_ASM_SRCS gnustep-libobjc2)
ws_resolve_sources(libobjc_OBJC_SRCS gnustep-libobjc2)
ws_resolve_sources(libobjc_CXX_SRCS gnustep-libobjc2)


# Now our objc target

add_library(objc-wii STATIC ${PROJECT_BINARY_DIR}/llvm-built devkitPPC libogc libfat ${libobjc_C_SRCS_LIST} ${libobjc_OBJC_SRCS_LIST} ${libobjc_CXX_SRCS_LIST})
set_target_properties(objc-wii PROPERTIES SUFFIX .bc)
add_library(objc-wii-asm STATIC ${PROJECT_BINARY_DIR}/llvm-built devkitPPC libogc libfat ${libobjc_ASM_SRCS_LIST})

include_directories("${CMAKE_BINARY_DIR}/devkitPPC/powerpc-eabi/include" "${CMAKE_BINARY_DIR}/libogc/include" "${CMAKE_BINARY_DIR}/libfat/include" "." "..")


# Debug symbols inclusion flag

if(CMAKE_BUILD_TYPE STREQUAL Release)
  set(CLANG_DBG_FLAG "")
else()
  set(CLANG_DBG_FLAG -g)
endif()


# Compiler rules

set(CMAKE_CXX_COMPILE_OBJECT "${CLANG_DIR}/clang -emit-llvm ${CLANG_DBG_FLAG} -c <FLAGS> -include ${CMAKE_SOURCE_DIR}/wii-prefix.pch -o <OBJECT> <SOURCE>")

set(CMAKE_C_COMPILE_OBJECT ${CMAKE_CXX_COMPILE_OBJECT})

set(CMAKE_ASM_COMPILE_OBJECT "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-gcc -c -I\"${CMAKE_BINARY_DIR}/libogc/include\" -I\"${CMAKE_BINARY_DIR}/libfat/include\" -x assembler-with-cpp -D __ppc__=1 -Wa,-m750cl -o <OBJECT> <SOURCE>")


# Linker Rules

set(CMAKE_CXX_CREATE_STATIC_LIBRARY 
  "${LLVM_DIR}/llvm-link -o <TARGET> <OBJECTS>"
  "${LLVM_DIR}/llc -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o <TARGET>.S <TARGET>"
  "${DEVKITPPC_DIR}/bin/powerpc-eabi-as -o <TARGET>-asm.o -m750cl <TARGET>.S"
  "${DEVKITPPC_DIR}/bin/powerpc-eabi-objcopy --remove-section=.debug_info <TARGET>-asm.o <TARGET>-asm-dbstrip.o")

set(CMAKE_ASM_CREATE_STATIC_LIBRARY "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-ar rs <TARGET> <OBJECTS>")


# Compiler flags

add_definitions(-target powerpc-generic-eabi)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -fexceptions -ffreestanding")
add_definitions( -DGNUSTEP -D__OBJC_RUNTIME_INTERNAL__=1)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_C_FLAGS} -fobjc-runtime=gnustep-1.7")

add_definitions( 
  -D __PPC__=1
  -D _BIG_ENDIAN=1
  -D WIISTEP=1
  -D NO_PTHREADS
  -D __TOY_DISPATCH__
  -D NO_LEGACY
  -D WS_LIBOBJC_INTERNAL=1
  -fno-builtin
  -Wno-deprecated-objc-isa-usage
  -Wno-objc-root-class
  -Wno-deprecated-declarations)

if(WIISTEP_PLATFORM STREQUAL "RVL_SDK")
  set(CONF_WS_PLATFORM_DEFS " -D WIISTEP_RVL_SDK=1 -D WIISTEP_LIBOGC=0")
elseif (WIISTEP_PLATFORM STREQUAL "libogc")
  set(CONF_WS_PLATFORM_DEFS " -D WIISTEP_RVL_SDK=0 -D WIISTEP_LIBOGC=1")
endif()

add_definitions(${CONF_WS_PLATFORM_DEFS})


# Install targets
install(TARGETS objc-wii objc-wii-asm
  EXPORT WiiStepTargets
  ARCHIVE DESTINATION "${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib"
  COMPONENT dev)

file(GLOB LIBOBJC2_PUB_HEADERS ${PROJECT_SOURCE_DIR}/gnustep-libobjc2/objc/*.h)
install(FILES ${LIBOBJC2_PUB_HEADERS}
  DESTINATION "${INSTALL_WS_DIR}/${PPC_WII_DIR}/include/objc" COMPONENT dev)

install(FILES ${PROJECT_SOURCE_DIR}/wii-prefix.pch ${PROJECT_SOURCE_DIR}/wii-support.c 
  DESTINATION ${INSTALL_WS_DIR}/${PPC_WII_DIR} COMPONENT dev)

# Register WiiStep with user's CMake
export(PACKAGE WiiStep)


# Now GNUstep-base
add_subdirectory(gnustep-base)


# WSClasses library
add_subdirectory(WSClasses)


# Export target list (for benefit of both build-set and external projects)
export(TARGETS objc-wii objc-wii-asm foundation-wii wsclasses-wii FILE ${PROJECT_BINARY_DIR}/WiiStepTargets.cmake)



# Create the WiiStepConfig.cmake file

# ... for the build tree
set(CONF_WS_LLVM_BIN_DIR "${PROJECT_BINARY_DIR}/llvm/bin")
set(CONF_WS_DKPPC_BIN_DIR "${PROJECT_BINARY_DIR}/devkitPPC/bin")
list(APPEND CONF_WS_PPC_INCLUDE_DIRS
  ${PROJECT_BINARY_DIR}/devkitPPC/powerpc-eabi/include
  ${PROJECT_BINARY_DIR}/libogc/include
  ${PROJECT_BINARY_DIR}/libfat/include
  ${PROJECT_SOURCE_DIR}/gnustep-libobjc2
  ${PROJECT_SOURCE_DIR}/gnustep-base/Headers
  ${PROJECT_SOURCE_DIR}/WSClasses)
list(APPEND CONF_WS_PPC_LIB_DIRS
  ${PROJECT_BINARY_DIR}/devkitPPC/powerpc-eabi/lib
  ${PROJECT_BINARY_DIR}/libogc/lib/wii
  ${PROJECT_BINARY_DIR}/libfat/lib/wii)
set(CONF_WS_PPC_OBJC_LLVM ${PROJECT_BINARY_DIR}/libobjc-wii.bc)
set(CONF_WS_PPC_OBJC_ELF ${PROJECT_BINARY_DIR}/libobjc-wii-asm.a)
set(CONF_WS_PPC_PCH ${PROJECT_SOURCE_DIR}/wii-prefix.pch)
set(CONF_WS_PPC_SUPPORT_C "-I${PROJECT_BINARY_DIR}/libogc/include ${PROJECT_SOURCE_DIR}/wii-support.c")
set(CONF_WS_MACROS_FILE "${PROJECT_SOURCE_DIR}/cmake/WiiStepProjectMacros.cmake")

configure_file(${CMAKE_MODULE_PATH}/WiiStepConfig.cmake.in
  "${PROJECT_BINARY_DIR}/WiiStepConfig.cmake" @ONLY)
  
# ... for the install tree
set(CONF_WS_LLVM_BIN_DIR "${INSTALL_WS_DIR}/bin")
set(CONF_WS_DKPPC_BIN_DIR "${INSTALL_WS_DIR}/bin")
set(CONF_WS_PPC_INCLUDE_DIRS "${INSTALL_WS_DIR}/${PPC_WII_DIR}/include")
set(CONF_WS_PPC_LIB_DIRS "${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib")
set(CONF_WS_PPC_OBJC_LLVM "${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib/libobjc-wii.bc")
set(CONF_WS_PPC_OBJC_ELF "${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib/libobjc-wii-asm.a")
set(CONF_WS_PPC_PCH "${INSTALL_WS_DIR}/${PPC_WII_DIR}/wii-prefix.pch")
set(CONF_WS_PPC_SUPPORT_C "-I${CONF_WS_PPC_INCLUDE_DIRS} ${INSTALL_WS_DIR}/${PPC_WII_DIR}/wii-support.c")
set(CONF_WS_MACROS_FILE "${INSTALL_CMAKE_DIR}/WiiStepProjectMacros.cmake")

configure_file(${CMAKE_MODULE_PATH}/WiiStepConfig.cmake.in
  "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/WiiStepConfig.cmake" @ONLY)
 
# Install the WiiStepConfig.cmake and WiiStepProjectMacros.cmake
install(FILES
  "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/WiiStepConfig.cmake"
  "${PROJECT_SOURCE_DIR}/cmake/WiiStepProjectMacros.cmake"
  DESTINATION "${INSTALL_CMAKE_DIR}" COMPONENT dev)

 
# Install the export set for use with the install-tree
install(EXPORT WiiStepTargets DESTINATION
  "${INSTALL_CMAKE_DIR}" COMPONENT dev)




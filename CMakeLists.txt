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

set(LLVM_DIR ${CMAKE_SOURCE_DIR}/llvm/build/bin)
set(CLANG_DIR ${LLVM_DIR})

add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/llvm-built 
WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
COMMAND mkdir ARGS -p llvm 
WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/llvm
COMMAND cmake ARGS -DCMAKE_INSTALL_PREFIX=${INSTALL_WS_DIR} -DLLVM_DEFAULT_TARGET_TRIPLE="powerpc-generic-eabi" -DLLVM_TARGETS_TO_BUILD="PowerPC" ${CMAKE_SOURCE_DIR}/llvm
COMMAND make
COMMAND touch ARGS ${PROJECT_BINARY_DIR}/llvm-built 

COMMENT "Building llvm and clang; This could take awhile...")

install(CODE "execute_process(COMMAND make install WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}/llvm\")")


# Add wsinstall target (or omit if requested)

set(NO_WSINSTALL FALSE CACHE BOOL 
	"Omit (if set) building/running `wsinstall`")
if(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
	set(NO_WSINSTALL TRUE) # Disable wsinstall on non-Mac platforms
endif()
if(NOT ${NO_WSINSTALL})
	add_subdirectory(wsinstall)

	# Add command to run wsinstall to download needed binaries

	if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
		add_custom_command(OUTPUT wsinstall-ran devkitPPC libogc 
		COMMAND ${PROJECT_SOURCE_DIR}/LaunchWSInstallOSX.sh ARGS $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ${PROJECT_BINARY_DIR}
		MAIN_DEPENDENCY wsinstall
		COMMENT "Now running wsinstall...")
	else()
		add_custom_command(OUTPUT wsinstall-ran devkitPPC libogc 
		COMMAND $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ARGS ${PROJECT_BINARY_DIR}
		MAIN_DEPENDENCY wsinstall
		COMMENT "Now running wsinstall...")
	endif()
else()
	add_custom_command(OUTPUT wsinstall-ran devkitPPC libogc 
	COMMAND touch wsinstall-ran
	COMMENT "Skipping wsinstall")
endif()


# Install devkitPPC and libogc

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

add_library(objc-wii STATIC ${PROJECT_BINARY_DIR}/llvm-built wsinstall-ran devkitPPC libogc ${libobjc_C_SRCS_LIST} ${libobjc_OBJC_SRCS_LIST} ${libobjc_CXX_SRCS_LIST})
set_target_properties(objc-wii PROPERTIES SUFFIX .bc)
add_library(objc-wii-asm STATIC ${PROJECT_BINARY_DIR}/llvm-built wsinstall-ran devkitPPC libogc ${libobjc_ASM_SRCS_LIST})

include_directories("${CMAKE_BINARY_DIR}/devkitPPC/powerpc-eabi/include" "${CMAKE_BINARY_DIR}/libogc/include" "." "..")


# Compiler rules

set(CMAKE_CXX_COMPILE_OBJECT "${CLANG_DIR}/clang -E -emit-llvm -c <FLAGS> -include ${CMAKE_SOURCE_DIR}/wii-prefix.pch -o <OBJECT>.c <SOURCE> && ${CLANG_DIR}/clang -emit-llvm -c <FLAGS> -include ${CMAKE_SOURCE_DIR}/wii-prefix.pch -o <OBJECT> <SOURCE>")

set(CMAKE_C_COMPILE_OBJECT ${CMAKE_CXX_COMPILE_OBJECT})

set(CMAKE_ASM_COMPILE_OBJECT "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-gcc -c -I\"${CMAKE_BINARY_DIR}/libogc/include\" -x assembler-with-cpp -D __ppc__=1 -Wa,-m750cl -o <OBJECT> <SOURCE>")


# Linker Rules

set(CMAKE_CXX_CREATE_STATIC_LIBRARY "${LLVM_DIR}/llvm-link -o <TARGET> <OBJECTS>")

set(CMAKE_ASM_CREATE_STATIC_LIBRARY "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-ar rs <TARGET> <OBJECTS>")

set(CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-gcc -o <TARGET> -mrvl -mhard-float -meabi -DGEKKO=1 <OBJECTS> <LINK_LIBRARIES>")


# Compiler flags

add_definitions(-target powerpc-generic-eabi)

list(APPEND CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -fexceptions")
add_definitions( -DGNUSTEP -D__OBJC_RUNTIME_INTERNAL__=1)
set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fobjc-runtime=gnustep-1.7")

add_definitions( 
-D __PPC__=1 
-D _BIG_ENDIAN=1 
-D WIISTEP=1 
-D NO_PTHREADS 
-D __TOY_DISPATCH__ 
-D NO_LEGACY 
-fno-builtin 
-Wno-deprecated-objc-isa-usage 
-Wno-objc-root-class
-Wno-deprecated-declarations) 

if (WIISTEP_PLATFORM STREQUAL "RVL_SDK")
	add_definitions( -D WIISTEP_RVL_SDK=1 -D WIISTEP_LIBOGC=0)
elseif (WIISTEP_PLATFORM STREQUAL "libogc")
	add_definitions( -D WIISTEP_RVL_SDK=0 -D WIISTEP_LIBOGC=1)
endif ()


# Temporary custom target to test custom command

# Aggregate target
#add_custom_target(WiiStep ALL DEPENDS objc-wii objc-wii-asm)

# Install targets
install(TARGETS objc-wii objc-wii-asm 
EXPORT WiiStepTargets 
ARCHIVE DESTINATION "${INSTALL_WS_DIR}/${PPC_WII_DIR}/lib"
COMPONENT dev)

# Export target list (for benefit of both build-set and external projects)
export(TARGETS objc-wii objc-wii-asm FILE ${PROJECT_BINARY_DIR}/WiiStepTargets.cmake)

# Register WiiStep with user's CMake
export(PACKAGE WiiStep)

# Create the WiiStepConfig.cmake file
file(RELATIVE_PATH REL_WS_DIR "${INSTALL_CMAKE_DIR}"
   "${INSTALL_WS_DIR}")
# ... for the build tree
set(CONF_WS_DIRS "${PROJECT_SOURCE_DIR}" "${PROJECT_BINARY_DIR}")
configure_file(${CMAKE_MODULE_PATH}/WiiStepConfig.cmake.in
  "${PROJECT_BINARY_DIR}/WiiStepConfig.cmake" @ONLY)
# ... for the install tree
set(CONF_WS_DIRS "\${WIISTEP_CMAKE_DIR}/${REL_WS_DIR}")
configure_file(${CMAKE_MODULE_PATH}/WiiStepConfig.cmake.in
  "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/WiiStepConfig.cmake" @ONLY)
 
# Install the WiiStepConfig.cmake and WiiStepConfigVersion.cmake
install(FILES
  "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/WiiStepConfig.cmake"
  DESTINATION "${INSTALL_CMAKE_DIR}" COMPONENT dev)
 
# Install the export set for use with the install-tree
install(EXPORT WiiStepTargets DESTINATION
  "${INSTALL_CMAKE_DIR}" COMPONENT dev)


cmake_minimum_required (VERSION 2.8)
project (WiiStep)

# Clang and LLVM

set(LLVM_DIR ${CMAKE_SOURCE_DIR}/llvm/build/bin)
set(CLANG_DIR ${LLVM_DIR})


# Add wsinstall target

add_subdirectory(wsinstall)


# Add command to run wsinstall to download needed binaries

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
add_custom_command(OUTPUT wsinstall-ran devkitPPC libogc COMMAND ${PROJECT_SOURCE_DIR}/LaunchWSInstallOSX.sh ARGS $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ${PROJECT_BINARY_DIR}
MAIN_DEPENDENCY wsinstall
COMMENT "Now running wsinstall...")
else()
add_custom_command(OUTPUT wsinstall-ran devkitPPC libogc COMMAND $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ARGS ${PROJECT_BINARY_DIR}
MAIN_DEPENDENCY wsinstall
COMMENT "Now running wsinstall...")
endif()


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

add_library(objc-wii STATIC wsinstall-ran devkitPPC libogc ${libobjc_C_SRCS_LIST} ${libobjc_OBJC_SRCS_LIST} ${libobjc_CXX_SRCS_LIST})
add_library(objc-wii-asm STATIC wsinstall-ran devkitPPC libogc ${libobjc_ASM_SRCS_LIST})

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

set(CMAKE_C_FLAGS "-std=gnu99 ${CMAKE_C_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fexceptions")
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

add_custom_target(WiiStep ALL DEPENDS objc-wii objc-wii-asm)



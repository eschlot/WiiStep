cmake_minimum_required (VERSION 2.8)
project (WiiStep)


# Add wsinstall target

add_subdirectory(wsinstall)


# Add command to run wsinstall to download needed binaries

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
add_custom_command(OUTPUT wsinstall-ran COMMAND ${PROJECT_SOURCE_DIR}/LaunchWSInstallOSX.sh ARGS $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ${PROJECT_BINARY_DIR}
MAIN_DEPENDENCY wsinstall
COMMENT "Now running wsinstall...")
else()
add_custom_command(OUTPUT wsinstall-ran $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ARGS ${PROJECT_BINARY_DIR}
MAIN_DEPENDENCY wsinstall
COMMENT "Now running wsinstall...")
endif()


# Add libobjc2 (and provide PPC-eabi rule-set)

set(WIISTEP TRUE)
set(WIISTEP_PLATFORM "libogc")
add_subdirectory(gnustep-libobjc2 EXCLUDE_FROM_ALL)


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

add_library(objc-wii STATIC wsinstall-ran ${libobjc_C_SRCS_LIST} ${libobjc_OBJC_SRCS_LIST} ${libobjc_CXX_SRCS_LIST})
add_library(objc-wii-asm STATIC wsinstall-ran ${libobjc_ASM_SRCS_LIST})

include_directories("${CMAKE_BINARY_DIR}/devkitPPC/powerpc-eabi/include" "${CMAKE_BINARY_DIR}/libogc/include" "." "..")


# Compiler rules

set(CMAKE_CXX_COMPILE_OBJECT "clang-mp-3.3 -E -emit-llvm -c <FLAGS> -include ${CMAKE_SOURCE_DIR}/wii-prefix.pch -o <OBJECT>.c <SOURCE> && clang-mp-3.3 -emit-llvm -c -include ${CMAKE_SOURCE_DIR}/wii-prefix.pch <FLAGS> -include ${CMAKE_SOURCE_DIR}/wii-prefix.pch -o <OBJECT> <SOURCE>")

set(CMAKE_C_COMPILE_OBJECT ${CMAKE_CXX_COMPILE_OBJECT})

set(CMAKE_ASM_COMPILE_OBJECT "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-gcc -c -I\"${CMAKE_BINARY_DIR}/libogc/include\" -x assembler-with-cpp -D __ppc__=1 -Wa,-m750cl -o <OBJECT> <SOURCE>")

set(CMAKE_CXX_CREATE_STATIC_LIBRARY "llvm-link-mp-3.3 -o <TARGET> <OBJECTS>")

set(CMAKE_ASM_CREATE_STATIC_LIBRARY "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-ar rs <TARGET> <OBJECTS>")

set(CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_BINARY_DIR}/devkitPPC/bin/powerpc-eabi-gcc -o <TARGET> -mrvl -mhard-float -meabi -DGEKKO=1 <OBJECTS> <LINK_LIBRARIES>")

add_definitions( -D WIISTEP=1 -D NO_PTHREADS -D __TOY_DISPATCH__ -D NO_LEGACY -fno-builtin -Wno-deprecated-objc-isa-usage -Wno-objc-root-class -fobjc-runtime=gnustep-1.7 -fobjc-exceptions)

if (WIISTEP_PLATFORM STREQUAL "RVL_SDK")
	add_definitions( -D WIISTEP_RVL_SDK=1 -D WIISTEP_LIBOGC=0)
elseif (WIISTEP_PLATFORM STREQUAL "libogc")
	add_definitions( -D WIISTEP_RVL_SDK=0 -D WIISTEP_LIBOGC=1)
endif ()


# Temporary custom target to test custom command

add_custom_target(WiiStep ALL DEPENDS objc-wii objc-wii-asm)

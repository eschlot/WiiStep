cmake_minimum_required(VERSION 2.8)


# Compiler rules

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -fexceptions")
set(CMAKE_CXX_FLAGS "${CMAKE_OBJC_FLAGS} ${CMAKE_C_FLAGS} -fobjc-runtime=gnustep-1.7 -fobjc-exceptions")

set(CMAKE_C_COMPILE_OBJECT "${WS_LLVM_BIN_DIR}/clang -emit-llvm -target powerpc-generic-eabi -c <FLAGS> -include ${WS_PPC_PCH} -o <OBJECT> <SOURCE>")

set(CMAKE_CXX_COMPILE_OBJECT "${WS_LLVM_BIN_DIR}/clang -emit-llvm -target powerpc-generic-eabi -c <FLAGS> -include ${WS_PPC_PCH} -o <OBJECT> <SOURCE>")


# Linker rules

set(CMAKE_CXX_CREATE_STATIC_LIBRARY "${WS_LLVM_BIN_DIR}/llvm-link -o <TARGET> <OBJECTS>")
set(CMAKE_C_CREATE_STATIC_LIBRARY ${CMAKE_CXX_CREATE_STATIC_LIBRARY})

set(CMAKE_ASM_CREATE_STATIC_LIBRARY "${WS_DKPPC_BIN_DIR}/powerpc-eabi-ar rs <TARGET> <OBJECTS>")


# Optimiser Flags
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(OBJC_OPT_LIB ${WS_LLVM_BIN_DIR}/../lib/libGNUObjCRuntime.dylib)
else()
  set(OBJC_OPT_LIB ${WS_LLVM_BIN_DIR}/../lib/libGNUObjCRuntime.so)
endif()
#set(LLVM_OPT_FLAGS "${LLVM_OPT_FLAGS} -load=${OBJC_OPT_LIB} -gnu-nonfragile-ivar -gnu-class-lookup-cache")
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  set(LLVM_OPT_FLAGS "${LLVM_OPT_FLAGS} -std-compile-opts")
endif()


# Executable link rule

macro(ws_set_link_rule)

  set(TARGET_LLVM_OBJECTS "")
  foreach(obj ${ARGN})
    set(TARGET_LLVM_OBJECTS "${TARGET_LLVM_OBJECTS} ${obj}")
  endforeach(obj)

  set(CMAKE_CXX_LINK_EXECUTABLE 
    "${WS_LLVM_BIN_DIR}/llvm-link -o <TARGET_BASE>-llvm.bc <OBJECTS> ${TARGET_LLVM_OBJECTS}" 
    "${WS_LLVM_BIN_DIR}/opt -o <TARGET_BASE>-llvm-opt.bc ${LLVM_OPT_FLAGS} <TARGET_BASE>-llvm.bc" 
    "${WS_LLVM_BIN_DIR}/llc -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o <TARGET_BASE>.S <TARGET_BASE>-llvm-opt.bc" 
    "${WS_DKPPC_BIN_DIR}/powerpc-eabi-gcc -o <TARGET> -mrvl -mhard-float -meabi -DGEKKO=1 <TARGET_BASE>.S <LINK_LIBRARIES> ${WS_PPC_SUPPORT_C}" 
    "${WS_DKPPC_BIN_DIR}/elf2dol <TARGET> <TARGET_BASE>.dol")
  
  set(CMAKE_C_LINK_EXECUTABLE ${CMAKE_CXX_LINK_EXECUTABLE})

endmacro(ws_set_link_rule)


# Compiler/Linker flags

include_directories(${WS_PPC_INCLUDE_DIRS})
link_directories(${WS_PPC_LIB_DIRS})

add_definitions( 
  -D __PPC__=1
  -D _BIG_ENDIAN=1
  -D WIISTEP=1
  -D GEKKO=1
  -D NO_PTHREADS
  -D __TOY_DISPATCH__
  -D NO_LEGACY
  -fno-builtin
  -Wno-deprecated-objc-isa-usage
  -Wno-objc-root-class
  -Wno-deprecated-declarations)
  


# Link LLVM bitcode libraries into target
macro(target_link_wii_llvm_libraries name)
  foreach(link ${ARGN})
    get_target_property(link_loc ${link} LOCATION)
    list(APPEND ${name}_LLVM_OBJECTS ${link_loc})
  endforeach(link)
  ws_set_link_rule(${${name}_LLVM_OBJECTS})
  add_dependencies(${name} ${ARGN})
endmacro(target_link_wii_llvm_libraries)


# Link ELF archives into target
macro(target_link_wii_dkppc_libraries name)
  target_link_libraries(${name} ${ARGN})
endmacro(target_link_wii_dkppc_libraries)


# Make LLVM bitcode library target
macro(add_wii_library name)
  add_library(${name} STATIC ${ARGN})
  set_target_properties(${name} PROPERTIES SUFFIX .bc TARGET llvm)
endmacro(add_wii_library)


# Make ELF/DOL Target
macro(add_wii_executable name)

  add_executable(${name} ${ARGN})
  target_link_wii_llvm_libraries(${name} objc-wii)  
  target_link_wii_dkppc_libraries(${name} ogc ${WS_PPC_OBJC_ELF})
  set_target_properties(${name} PROPERTIES SUFFIX .elf)
  
endmacro(add_wii_executable)


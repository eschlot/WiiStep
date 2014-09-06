cmake_minimum_required(VERSION 2.8)


# Debug symbols inclusion flag

if(CMAKE_BUILD_TYPE STREQUAL Release)
  set(CLANG_DBG_FLAG "")
else()
  set(CLANG_DBG_FLAG -g)
endif()


# Which HW-abstraction platforms are available
add_definitions(${WS_PLATFORM_DEFS})


# Assemble include string
foreach(obj ${WS_PPC_INCLUDE_DIRS})
  set(WS_PPC_INCLUDE_STR "${WS_PPC_INCLUDE_STR} -I ${obj}")
endforeach(obj)


# Compiler rules

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -fexceptions -ffreestanding")
set(CMAKE_CXX_FLAGS "${CMAKE_OBJC_FLAGS} ${CMAKE_C_FLAGS} -fobjc-runtime=gnustep-1.7 -fobjc-exceptions")

set(CMAKE_C_COMPILE_OBJECT "${WS_LLVM_BIN_DIR}/clang -emit-llvm ${CLANG_DBG_FLAG} -target powerpc-generic-eabi -c -include ${WS_PPC_PCH} <FLAGS> <DEFINES>  -o <OBJECT> <SOURCE>")

set(CMAKE_CXX_COMPILE_OBJECT "${WS_LLVM_BIN_DIR}/clang -emit-llvm ${CLANG_DBG_FLAG} -target powerpc-generic-eabi -c -include ${WS_PPC_PCH} <FLAGS> <DEFINES> -o <OBJECT> <SOURCE>")

set(CMAKE_ASM_COMPILE_OBJECT "${WS_DKPPC_BIN_DIR}/powerpc-eabi-gcc -c ${WS_PPC_INCLUDE_STR} -x assembler-with-cpp -D __ppc__=1 -Wa,-m750cl -o <OBJECT> <SOURCE>")

# Linker rules

set(CMAKE_CXX_CREATE_STATIC_LIBRARY
  "${WS_LLVM_BIN_DIR}/llvm-link -o <TARGET> <OBJECTS>"
  "${WS_LLVM_BIN_DIR}/llc -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o <TARGET>.S <TARGET>"
  "${WS_DKPPC_BIN_DIR}/powerpc-eabi-as -o <TARGET>-asm.o -m750cl <TARGET>.S"
  "${WS_DKPPC_BIN_DIR}/powerpc-eabi-objcopy --remove-section=.debug_info <TARGET>-asm.o <TARGET>-asm-dbstrip.o")
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

macro(ws_set_link_rule name)

  if(CMAKE_BUILD_TYPE STREQUAL "Release")

    set(TARGET_LLVM_OBJECTS "")
    foreach(obj ${ARGN})
      set(TARGET_LLVM_OBJECTS "${obj} ${TARGET_LLVM_OBJECTS}")
    endforeach(obj)

    set(CMAKE_CXX_LINK_EXECUTABLE 
      "${WS_LLVM_BIN_DIR}/llvm-link -o <TARGET_BASE>-llvm.bc <OBJECTS> ${TARGET_LLVM_OBJECTS}" 
      "${WS_LLVM_BIN_DIR}/opt -o <TARGET_BASE>-llvm-opt.bc ${LLVM_OPT_FLAGS} <TARGET_BASE>-llvm.bc" 
      "${WS_LLVM_BIN_DIR}/llc -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o <TARGET_BASE>.S <TARGET_BASE>-llvm-opt.bc"
      "${WS_DKPPC_BIN_DIR}/powerpc-eabi-gcc -o <TARGET> -mrvl -mhard-float -meabi -DGEKKO=1 -Wa,-m750cl <TARGET_BASE>.S <LINK_LIBRARIES> ${WS_PPC_INCLUDE_STR} ${WS_PPC_SUPPORT_C}"
      "${WS_DKPPC_BIN_DIR}/elf2dol <TARGET> <TARGET_BASE>.dol") 

  else()

    set(TARGET_LLVM_OBJECTS "")
    foreach(obj ${ARGN})
      set(TARGET_LLVM_OBJECTS "${obj}-asm-dbstrip.o ${TARGET_LLVM_OBJECTS}")
    endforeach(obj)

    set(CMAKE_CXX_LINK_EXECUTABLE 
      "${WS_LLVM_BIN_DIR}/llvm-link -o <TARGET_BASE>-llvm.bc <OBJECTS>" 
      "${WS_LLVM_BIN_DIR}/opt -o <TARGET_BASE>-llvm-opt.bc ${LLVM_OPT_FLAGS} <TARGET_BASE>-llvm.bc" 
      "${WS_LLVM_BIN_DIR}/llc -filetype=asm -asm-verbose -mtriple=powerpc-generic-eabi -mcpu=750 -float-abi=hard -relocation-model=static -o <TARGET_BASE>.S <TARGET_BASE>-llvm-opt.bc"
      "${WS_DKPPC_BIN_DIR}/powerpc-eabi-as -o <TARGET_BASE>-asm.o -m750cl <TARGET_BASE>.S"
      "${WS_DKPPC_BIN_DIR}/powerpc-eabi-objcopy --remove-section=.debug_info <TARGET_BASE>-asm.o <TARGET_BASE>-asm-dbstrip.o"
      "${WS_DKPPC_BIN_DIR}/powerpc-eabi-gcc -o <TARGET> -mrvl -mhard-float -meabi -DGEKKO=1 -Wa,-m750cl <TARGET_BASE>-asm-dbstrip.o ${TARGET_LLVM_OBJECTS} <LINK_LIBRARIES> ${WS_PPC_INCLUDE_STR} ${WS_PPC_SUPPORT_C}"
      "${WS_DKPPC_BIN_DIR}/elf2dol <TARGET> <TARGET_BASE>.dol")
      
  endif()  

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
  -D HW_RVL=1
  -D NO_PTHREADS
  -D __TOY_DISPATCH__
  -D NO_LEGACY
  -fno-builtin)

enable_language(ASM)


# Link LLVM bitcode libraries into target
macro(target_link_wii_llvm_libraries name)
  foreach(link ${ARGN})
    get_target_property(link_loc ${link} LOCATION)
    list(APPEND ${name}_LLVM_OBJECTS ${link_loc})
    list(APPEND ${name}_LLVM_OBJECTS ${${link}_LLVM_OBJECTS})
  endforeach(link)
  list(REMOVE_DUPLICATES ${name}_LLVM_OBJECTS)
  set(${name}_LLVM_OBJECTS ${${name}_LLVM_OBJECTS} CACHE INTERNAL "" FORCE)
  ws_set_link_rule(${name} ${${name}_LLVM_OBJECTS})
  add_dependencies(${name} ${ARGN})
  get_target_property(link_depends ${name} LINK_DEPENDS)
  if(link_depends STREQUAL link_depends-NOTFOUND)
    unset(link_depends)
  endif()
  list(APPEND link_depends ${${name}_LLVM_OBJECTS})
  list(REMOVE_DUPLICATES link_depends)
  #message("${link_depends}")
  set_target_properties(${name} PROPERTIES LINK_DEPENDS "${link_depends}")
endmacro(target_link_wii_llvm_libraries)


# Link ELF archives into target
macro(target_link_wii_dkppc_libraries name)
  target_link_libraries(${name} ${ARGN})
endmacro(target_link_wii_dkppc_libraries)


# Link Binary files into target
macro(target_link_wii_binary_files name)
  unset(bin_files)
  #get_target_property(bin_depends ${name} LINK_DEPENDS)
  #if(bin_depends STREQUAL bin_depends-NOTFOUND)
  #  unset(bin_depends)
  #endif()
  foreach(file ${ARGN})
    get_filename_component(full_file ${file} ABSOLUTE)
    if(NOT EXISTS ${full_file})
      file(WRITE ${full_file} "")
    endif()
    set(command_str "'${WS_DKPPC_BIN_DIR}/bin2s' '-a' '32' '${file}' > '${file}.s'")
    add_custom_command(OUTPUT ${file}.s
                       COMMAND sh ARGS -c "${command_str}"
                       MAIN_DEPENDENCY ${full_file}
                       VERBATIM)
    string(REPLACE "/" "_" target ${file})
    string(REPLACE "\\" "_" target ${target})
    add_library(${target}-bin STATIC ${file}.s)
    #get_target_property(link_loc ${target}-bin LOCATION)
    list(APPEND bin_files ${target}-bin)
    #list(APPEND bin_depends ${link_loc})
    #list(APPEND bin_depends ${full_file})
    #add_dependencies(${target}-bin ${full_file})
    #set_target_properties(${target}-bin PROPERTIES LINK_DEPENDS "${file}")

  endforeach(file)
  target_link_libraries(${name} ${bin_files})
  #message("${bin_depends}")
  #add_dependencies(${name} ${bin_depends})
  #set_target_properties(${name} PROPERTIES LINK_DEPENDS "${bin_depends}")
endmacro(target_link_wii_binary_files)


# Make LLVM bitcode library target
macro(add_wii_library name)
  add_library(${name} STATIC ${ARGN})
  set_target_properties(${name} PROPERTIES SUFFIX .bc)
endmacro(add_wii_library)


# Make ELF/DOL Target
macro(add_wii_executable name)
  add_executable(${name} ${ARGN})
  target_link_wii_llvm_libraries(${name} objc-wii)  
  target_link_wii_dkppc_libraries(${name} fat ogc objc-wii-asm m)
  set_target_properties(${name} PROPERTIES SUFFIX .elf)
endmacro(add_wii_executable)

# Use wiiload to run test
macro(add_wii_test testname Exename)
  get_target_property(target_loc ${Exename} LOCATION)
  get_filename_component(target_dir ${target_loc} PATH)
  get_filename_component(target_loc ${target_loc} NAME_WE)
  add_test(NAME ${testname}
           WORKING_DIRECTORY ${target_dir}
           COMMAND ${WS_DKPPC_BIN_DIR}/wiiload ${target_loc}.dol ${ARGN})
endmacro(add_wii_test)


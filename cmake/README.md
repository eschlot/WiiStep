Using CMake with WiiStep
========================

In order to allow WiiStep's development environment to build on as many platforms 
as possible, [CMake](http://cmake.org) has been chosen as its primary build method. 
Also, WiiStep's main dependencies (llvm, libobjc2) use CMake as their build systems;
making for a very consistent developer experience.

I recommend reading [LLVM's CMake tutorial](http://llvm.org/docs/CMake.html)
for a good primer in using CMake for the construction and use of developer 
tools. Additionally, WiiStep's various `cmake` files also use many of the 
principes used by LLVM. 


Building WiiStep with CMake
---------------------------

The standard route of making an empty directory, `cd`-ing into it, and running
`cmake` with a path to the WiiStep source works just fine. An example of this
in practice looks like the following:

```sh
cd <WiiStep source>
mkdir build
cd build
cmake ..
make
```


WiiStep CMake-Cache Variables
-----------------------------

CMake uses the concept of a *variable cache* to remember what the developer's 
build preferences are across repeated builds of a project. As an aside, a CMake
project's cache variables may be listed (along with usage help) with 
`cmake -LH`. 

The developer may override the default value of any cache variable with the
`-D` flag to the `cmake` command. For instance: 
`cmake -DWIISTEP_PLATFORM="RVL_SDK" ..`.

WiiStep has the following cache variables available:

### WIISTEP_PLATFORM

By nature of the Wii's software platform, there is no *dynamic linking* 
available to applications. Furthermore, as an 
[embedded system](http://en.wikipedia.org/wiki/Embedded_system), 
the Wii has no common kernel to load and manage driver code for platform 
hardware. 
This means that the OS, hardware drivers and third-party middleware must all 
be introduced ahead of time via 
*[static linking](http://en.wikipedia.org/wiki/Static_library)* 
into the final executable. 

It is beyond the scope of WiiStep to provide all this necessary code, 
so external runtime code is required. There are two main options for platform
abstraction (multitasking kernel 
([LWP](http://en.wikipedia.org/wiki/Light-weight_process)) and HW drivers):

* `-DWIISTEP_PLATFORM="libogc"` (the default)

This will cause WiiStep to utilise *[libogc](http://wiibrew.org/wiki/Libogc)* 
(which is downloaded from SourceForge automatically
by `wsinstall`) for platform abstraction. libogc is an open-source project
maintained by various Wii-hackers in the homebrew community.

* `-DWIISTEP_PLATFORM="RVL_SDK"`

This will cause WiiStep to utilise symbols provided by Nintendo's own *RVL_SDK 
v2.1*. At writing, only multithreading objects (threads and locks) are used
from the SDK. For obvious reasons, the SDK must be provided by the developer.
Simply place the `RVL_SDK` root into WiiStep's CMake build directory and 
specify "RVL_SDK" as the WIISTEP_PLATFORM to go this route.

### NO_WSINSTALL

Since `wsinstall` currently only builds and runs correctly on 
**OS X 10.7 and later**, users of other platforms may add 
`-DNO_WSINSTALL=TRUE` to the CMake command in order to omit 
`wsinstall` entirely. When set, CMake will still insert the `wsinstall-ran`
stub into the build directory for correct dependency resolution.

### CMAKE_BUILD_TYPE

This is actually a standard CMake built-in variable, but plays a key
role in determining the LLVM-to-ELF executable link behaviour.

When `-DCMAKE_BUILD_TYPE=Release` is specified, all LLVM-based targets
are linked together first, ran through a `-std-compile-opts` pass with 
LLVM's `opt`, then compiled to PPC assembly. The final ELF link uses
a single, monolithic assembly file to include LLVM-originated code.
This process is generally *very slow*.

If any other build type is specified (like the default `None`),
all target-linking occurs in the ELF stage. Individual LLVM targets are
linked as separate PPC assembly files. This process takes a fraction of the
time that the `Release` mode takes and is generally good for development.


Making A CMake Project Against WiiStep
--------------------------------------

CMake has a nifty 
[`find_package`](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:find_package) 
command that can be used to resolve WiiStep and load its settings and macros
into an external CMake project. CMake maintains a user package registry at `~/.cmake/packages/`.
Simply by building WiiStep (no install necessary), `find_package` may be invoked
and the external project will use the built WiiStep files in-place.

An example project's root `CMakeLists.txt` may look like the following:

```cmake
cmake_minimum_required(VERSION 2.8)
project(My-Awesome-ObjC-On-Wii-App)

find_package(WiiStep REQUIRED)

# Create targets and what-not down here. For example:

# A subdirectory named `AwesomeUI` containing the app's UI code (for instance)
# The `CMakeLists.txt` in the directory defines the `awesome-ui` target using `add_wii_library`
add_subdirectory(AwesomeUI)

# This will actually stage the creation of a .ELF/.DOL file pair in the app's CMake build directory
add_wii_executable(my-awesome-app 
  app_code.m
  more_app_code.m)

# We want the foundation framework too
target_link_wii_llvm_libraries(my-awesome-app awesome-ui foundation-wii)

# This will link the bluetooth-stack and wiimote-API into the app
# Please note that libogc (including kernel and GX API) is implicitly linked by WiiStep
target_link_wii_dkppc_libraries(my-awesome-app wiiuse bte)
```


Making A WiiStep Application With CMake
---------------------------------------

### add_wii_executable

```cmake
add_wii_executable(<name> [EXCLUDE_FROM_ALL]
                   source1 source2 ... sourceN)
```

Using a `CMakeLists.txt` like the one illustrated above, the `add_wii_executable`
macro is available to establish a target defining all sources (for LLVM to build) 
that should be present in the final .ELF and .DOL. 

`libogc` and `libobjc-wii` will implicitly be linked in this executable. Other
libraries-to-link must be specified using a combination of the following macros.

### target_link_wii_llvm_libraries

```cmake
target_link_wii_llvm_libraries(<target> 
                               item1 item2 ... itemN)
```

This macro will gather any **LLVM-bitcode** based library targets and 
stage them for a pre-optimisation `llvm-link`. This is the recommended
way to integrate libraries that directly interact with other LLVM-compiled
code components within the project. 

### target_link_wii_dkppc_libraries

```cmake
target_link_wii_dkppc_libraries(<target> 
                                item1 item2 ... itemN)
```

This macro will gather **ELF-archive** based library targets and stage
them for final .ELF application inclusion. Library names 
(whose file names follow the standard `lib<name>.a` convention) may be specified
in this macro. Note that libogc's wii library path is implicitly searched;
so library names like `bte` or `wiiuse` may be specified without performing
`link_directories`.

### target_link_wii_binary_files

```cmake
target_link_wii_binary_files(<target> 
                             file1 file2 ... fileN)
```

This macro provides a handy **binary data embedder**. The files provided will be converted into a *GCC assembly language* target that gets 32-byte-aligned and linked as a native devkitPPC library. Upon being linked, the raw binary data may be accessed from within C like so:

```c
// Sample C file of a wii executable linked using
// `target_link_wii_binary_files(<exe_target_name> test_data.bin)`

#include <stdlib.h>

extern uint8_t test_data_bin;
extern size_t test_data_bin_size;

int main(int argc, const char* argv[]) {
    void* test_data = (void*)&test_data_bin;
    printf("Data is %u bytes in length\n", test_data_bin_size);
    printf("First 4 bytes: %x %x %x %x\n", 
           test_data[0], test_data[1], test_data[2], test_data[3]);
    return 0;
}
```

**Please Note** that periods (`.`) are replaced with underscores (`_`) in the C-symbol names, so watch file extensions!


Live-testing a WiiStep Application with CTest
---------------------------------------------

A rapid means to **run development homebrew on a physical Wii** is to use a Homebrew Channel Wi-Fi loader like 
[`wiiload`](http://wiibrew.org/wiki/Wiiload). WiiStep includes a macro collect 
`add_wii_executable` targets to be *automatically uploaded to a Wii* when `make test` is called.

### Initial Setup

 Wiiload is packaged with *devkitPPC* and relies on the `WIILOAD` shell environment
 variable to be set to the hostname/IP address of an actual Wii on the local network.
 A lone Wii on a Wi-Fi network will assign itself the hostname "Wii". 
 As long as the router's local DNS zone is functioning correctly, the following
 command will acquaint `wiiload` with the Wii:

```sh
>$ export WIILOAD=tcp:Wii
```

### CTest Setup

To activate CMake's `make test` target, `enable_testing()` must be called in the root `CMakeLists.txt` file.

### Adding Test Targets

```cmake
add_wii_test(<test_name> <executable_target_name>)
```

Every target added via this macro will be enqueued for uploading. Note that 
the [Homebrew Channel](http://wiibrew.org/wiki/Homebrew_Channel) 
*must be running* when `make test` is called.

For multiple tests, if any test executables do not return to the Homebrew Channel in a timely
manner (or crash), later tests may cause Wiiload to *time-out*, preventing completion of the test-queue.


Making A WiiStep Middleware Library With CMake
----------------------------------------------

For those wishing to package WiiStep-using libraries for other developers 
(or simply for projects spanning multiple subdirectories), a simple macro
is available to easily accomplish this. 

### add_wii_library

```cmake
add_wii_library(<name> [EXCLUDE_FROM_ALL]
                source1 source2 ... sourceN)
```

This macro will produce a target generating a linked **LLVM-bitcode** (.bc) file
linkable with `target_link_wii_llvm_libraries`. 
Producing LLVM-based libraries ensure LLVM is able to comprehensively optimise
code in a unified manner (even *inlining* post-compiled routines together).


Some Handy CMake Built-in Commands
----------------------------------

### [add_subdirectory](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:add_subdirectory)

```cmake
add_subdirectory(source_dir [binary_dir] 
                 [EXCLUDE_FROM_ALL])
```

For large projects that would be most comfortable spread across multiple
subdirectories, this command may be used to string together a project's
subdirectories. Each subdirectory must contain its own `CMakeLists.txt` file.

### [include_directories](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:include_directories)

```cmake
include_directories([AFTER|BEFORE] dir1 dir2 ...)
```

Xcode users
may be familiar with the *project headers* section of the *Copy Headers*
build phase. `include_directories` is CMake's equivalent of it, and behaves
roughly the same way (although selected by directory and not individual headers). 
It ultimately allows `#include "someheader.h"` directives to reference header 
files in a project-wide manner, without concern of directory traversal.

### [link_directories](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:link_directories)

```cmake
link_directories(directory1 directory2 ...)
```

This allows the `target_link_wii_*_libraries` macros 
to resolve LLVM and ELF libraries by name without concern of their path
location. Note that this macro is not necessary for resolving external targets included
with `find_package` (like WiiStep itself).


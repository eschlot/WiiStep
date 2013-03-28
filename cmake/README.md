Using CMake with WiiStep
========================

In order to allow WiiStep to build on as many platforms as possible, 
[CMake](http://cmake.org) has been chosen as its primary build method. Also,
WiiStep's main dependencies (llvm, libobjc2) use CMake as their build systems;
making for a very consistent developer experience.

I recommend reading [LLVM's CMake tutorial](http://llvm.org/docs/CMake.html)
for a good primer in using CMake for the construction and use of developer 
tools. Additionally, WiiStep's `CMakeLists.txt` files also use many of the 
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


Making A CMake Project Against WiiStep
--------------------------------------

CMake has a nifty 
[`find_package`](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:find_package) 
command that can be used to resolve WiiStep and load its settings and macros
into an external CMake project. `find_package` requires the `CMAKE_MODULE_PATH` list
to include `<PATH TO WIISTEP SOURCE>/cmake`. After augmenting the module path list,
`find_package` may be invoked.

An example project's `CMakeLists.txt` may look like the following:

```cmake
cmake_minimum_required(VERSION 2.8)
project(My-Awesome-ObjC-On-Wii-App)

# Get WiiStep integrated (discovers within home dir by default)
set(MYPROJ_WS_PATH "~/WiiStep" CACHE PATH
	"Path my project uses to access WiiStep")
list(APPEND CMAKE_MODULE_PATH ${MYPROJ_WS_PATH}/cmake)

find_package(WiiStep MODULE REQUIRED)

# Create targets and what-not down here
```


Making A WiiStep Application With CMake
---------------------------------------

### [include_directories](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:include_directories)

```cmake
include_directories([AFTER|BEFORE] dir1 dir2 ...)
```

This is actually a CMake built-in function, though it plays a key role 
in WiiStep's build process and is worth drawing attention to. Xcode users
may be familiar with the *project headers* section of the *Copy Headers*
build phase. `include_directories` is CMake's equivalent of it, and behaves
roughly the same way. It ultimately allows `#include "someheader.h"` directives 
to reference header files in a project-wide manner, without concern of directory 
traversal.

### [link_directories](http://www.cmake.org/cmake/help/v2.8.10/cmake.html#command:link_directories)

```cmake
link_directories(directory1 directory2 ...)
```

Another CMake built-in. This allows the `target_link_wii_*_libraries` macros below
to resolve LLVM and ELF libraries by name without concern of their path
location. Note that this macro is not necessary for resolving external targets included
with `find_package` (like WiiStep itself).

### add_wii_executable

```cmake
add_wii_executable(<name> [EXCLUDE_FROM_ALL]
                   source1 source2 ... sourceN)
```

Using a `CMakeLists.txt` like the one illustrated above, the `add_wii_executable`
macro is available to establish a target defining all sources that should
be present in the final .ELF and .DOL. 

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


Making A WiiStep Middleware Library With CMake
----------------------------------------------

For those wishing to package WiiStep-using libraries for other developers 
(or simply for projects spanning multiple subdirectories), macros are available
to easily accomplish this. 

There are two options for specifying library targets: 

### add_wii_llvm_library

```cmake
add_wii_llvm_library(<name> [EXCLUDE_FROM_ALL]
                     source1 source2 ... sourceN)
```

This macro will produce a target generating a linked **LLVM-bitcode** (.bc) file
packaged as an archive (.a) and linkable with `target_link_wii_llvm_libraries`. 
Producing LLVM-based libraries ensure LLVM is able to comprehensively optimise
code in a unified manner (even *inlining* post-compiled routines together).

### add_wii_dkppc_library

```cmake
add_wii_dkppc_library(<name> [EXCLUDE_FROM_ALL]
                      source1 source2 ... sourceN)
```

For sources needing to be compiled and linked in the traditional GCC
manner, this macro will produce a target generating an **ELF-archive** (.a)
linkable with `target_link_wii_dkppc_libraries`. 

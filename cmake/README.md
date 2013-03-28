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


Making A WiiStep Application With CMake
---------------------------------------


Making A WiiStep Middleware Library With CMake
----------------------------------------------



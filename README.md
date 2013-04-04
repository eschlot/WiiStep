What It Is
----------

A *CMake-driven, auto-installing suite of free software*; combined to
form a *Foundation Framework based* (non-GUI), modern **Objective-C 
Development Environment**. 

The environment is suitable for authoring Objective-C sources against
familiar Framework-APIs for intended execution on the Wii.


### Modern Objective-C Awesomeness

Most features available to Mac and iOS developers compiling with Xcode 
are available via WiiStep. 

A significant portion of the *Foundation Framework* is available via the 
[GNUstep-Base](https://github.com/gnustep/gnustep-base) implementation.

The GNUstep project also provides the [libobjc2](https://github.com/gnustep/gnustep-libobjc2)
Objective-C runtime library. A PowerPC-aware fork of this library has
been created as the [WiiStep Runtime](https://github.com/jackoalan/gnustep-libobjc2). 
The runtime provides Clang-ABI-compatible implementations supporting 
[Block objects](http://clang.llvm.org/docs/BlockLanguageSpec.html) and
[Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html).
Any other PowerPC-ABI compatible Clang extensions should work as well. 


### Platform Integration

ELF Code-linking tools and the fundamental C/C++ runtimes are provided 
by [devkitPPC](http://devkitpro.org). Platform abstraction is 
accomplished using externally-linked [libogc](http://libogc.devkitpro.org). 

Optionally, certain libogc platform-functionality (threads and locks) may be 
substituted for symbols present in RVL_SDK 2.1, based on headers floating 
around the internet. If this route is preferred, place the `RVL_SDK` root
in the Cmake build directory and add `-DWIISTEP_PLATFORM="RVL_SDK"` to the 
`cmake` command.


What I Need
-----------

* [LLVM/Clang toolchain](http://llvm.org) (for PowerPC toolchain bootstrap)
    * `clang` C/C++/Objective-C compiler frontend and supporting LLVM backend required
    * [Xcode's](http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12) bundled toolchain works fine, and CMake will discover it within `Xcode.app`
* [CMake 2.8](http://www.cmake.org) (or greater)
* [Git](http://git-scm.com) (naturally)
* **~3GB** of disk space; LLVM's build process is rather file-intensive

Aaand...That's it. All other dependencies are automatically fetched within 
`git submodule` and the provided `wsinstall` target.

### And Those Would Be?

* Via **Git-Submodule**:
    * [`llvm`](http://llvm.org/) for [linking](http://llvm.org/docs/CommandGuide/llvm-link.html), [optimising](http://llvm.org/docs/CommandGuide/opt.html), and [PowerPC](http://llvm.org/docs/CodeGenerator.html#the-powerpc-backend) [Code Generation](http://llvm.org/docs/CommandGuide/llc.html)
    * [`clang`](http://clang.llvm.org) for providing modern [C](http://clang.llvm.org/docs/BlockLanguageSpec.html) and [Objective-C](http://clang.llvm.org/docs/AutomaticReferenceCounting.html) magic
    * [`gnustep-libobjc2`](http://GNUstep.org) continuing the magic [at runtime](https://github.com/jackoalan/gnustep-libobjc2#readme)
    * [`gnustep-base`](http://GNUstep.org) providing a default *Foundation.framework* implementation
    * `compiler-rt`
* Via **wsinstall**:
    * [`devkitPPC`](http://devkitpro.org) GCC-forked toolchain for performing final .ELF link
    * [`libogc`](http://wiibrew.org/wiki/Libogc) open-source OS ([multithreaded kernel contained in app](http://en.wikipedia.org/wiki/Light-weight_process)) and HW drivers ([also in app](http://libogc.devkitpro.org/api_doc.html))

At writing, `wsinstall` (an Objective-C based installer) only links against the actual 
Apple *Foundation.framework* and downloads the OS X version of *devkitPPC*, effectively 
making `wsinstall` compatible only with **OS X 10.7 and later**. I'd like to eventually get 
WiiStep's CMake bootstrapping its own copy of `gnustep-base` and the master branch of 
`gnustep-libobjc2` for a native Objective-C build environment and wider platform
support for `wsinstall`.

As a workaround for other platforms, add `-DNO_WSINSTALL=TRUE` to the `cmake` command.
This will prevent `wsinstall` from building/running during the build process.
Of course, this *requires* the developer to manually download/build 
[devkitPPC](http://sourceforge.net/projects/devkitpro/files/devkitPPC/) 
and [libogc](http://sourceforge.net/projects/devkitpro/files/libogc/). 
Afterwards, place their roots in WiiStep's CMake build directory and build WiiStep
as normal.

Please note that libogc's tar is something of a 
[tarbomb](http://en.wikipedia.org/wiki/Tar_%28computing%29#Tarbomb) and will
need to be extracted within a new directory named `libogc` within WiiStep's
build directory. devkitPPC's tar is OK to extract directly in the build directory.



How To Do
---------

### Basically:

```sh
cd <Where i should be>
git clone https://github.com/jackoalan/WiiStep.git
cd WiiStep
./bootstrap.sh
mkdir build && cd build
cmake ..
make

# Optional (WiiStep's build directory may be directly utilised for external development):
sudo make install
```

[Details on the CMake method](https://github.com/jackoalan/WiiStep/tree/master/cmake#readme) 
are also available. 

The install destination is `/opt` by default. A single directory named
`wiistep` is placed in the install destination containing PowerPC-enabled
LLVM and Clang as well as devkitPPC, libogc and the files described below.
The install destination may be adjusted (perhaps within user-space) by
adding the standard `-DCMAKE_INSTALL_PREFIX="<INSTALL_DIR>"` to the `cmake`
command.

After the build completes, there will be two *important* files in the 
build directory. These files are used by [adoptable CMake modules](https://github.com/jackoalan/WiiStep/blob/master/cmake/README.md#making-a-cmake-project-against-wiistep) 
to automate the correct compilation sequence for app sources. 


### Using these two files, the general build process goes like this:

### libobjc-wii.bc

First, `libobjc-wii.bc` *isn't* a gcc-compatible ELF archive; it actually
is *LLVM-IR-bitcode* (.bc) linked together (with [`llvm-link`](http://llvm.org/docs/CommandGuide/llvm-link.html)) and used like an archive. 
This bitcode file is utilised by the application build system's own invocation 
of `llvm-link`.

Once the application's 
WiiStep-using code is linked with `libobjc-wii.bc`, LLVM's [`opt`](http://llvm.org/docs/CommandGuide/opt.html)
may be ran with the `-gnu-objc` flag to apply various transformations
to the code making it run very efficiently within the WiiStep Runtime.

Finally, the LLVM static compiler, [`llc`](http://llvm.org/docs/CommandGuide/llc.html),
performs the final LLVM-to-PPC conversion and emits a PPC-assembly
(.S) file. 

This file may essentially be the entire application and WiiStep runtime
minus any ELF archives that should be linked in during the final link 
( *libogc* and *wiiuse* are notable examples ).

### libobjc-wii-asm.a

Next, `libobjc-wii-asm.a` *is* a gcc-compatible ELF archive that 
contains *platform-native, direct-assembled* objects that *need*
to be linked in the final phase. 

Once this file is in place, linking of the final application executable
may occur. Essentially, that involves a straight `-mrvl` linking pass to 
`powerpc-eabi-gcc` in devkitPPC. Perhaps some C/C++ files may
be compiled and linked at this time as well, within the *GCC environment*. 

Essentially, `powerpc-eabi-gcc` needs to link:
* Your application-produced LLVM-to-PPC assembly file
    * Also includes `libobjc-wii.bc`
    * May include extra Objective-C frameworks like *Foundation*
* `libobjc-wii-asm.a`
* `libogc` (OS and most drivers)
* `libbte` (Bluetooth stack)
* `libwiiuse` (Wii Remote API)
* Any other what-have-you ELF archives

The result will be an *.ELF* executable file ready for conversion into a 
*.DOL* executable. CMake utilises `elf2dol` in devkitPPC to produce a paired 
.DOL anytime an .ELF is (re)generated. 

Once done, the DOL should launch on a production Wii and return to the 
launching app correctly according to Nintendo's apploader design.

WiiStep Objective-C Development Environment
===========================================

What It Is
----------

A *CMake-driven, auto-installing suite of free software*; combined to
form a *Foundation Framework based* (non-GUI), modern **Objective-C 
Development Environment**. 

The environment is suitable for authoring Objective-C sources against
familiar Framework-APIs for intended execution on the Wii. It produces 
fully-linked ELF/DOL executables, loadable by nearly all 
[homebrew methods](http://wiibrew.org).


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
    * Mac users may install [*Xcode command-line tools*](https://developer.apple.com/downloads)
* [CMake 2.8](http://www.cmake.org) (or greater)
* [Git](http://git-scm.com) (naturally)
* **~3GB** of disk space; LLVM's build process is rather file-intensive

You will also need the PowerPC toolchain and platform libraries (follow instructions below).


How To Do
---------

### Clone WiiStep and initialize

```sh
cd <preferred-dev-directory>
git clone https://github.com/jackoalan/WiiStep.git
cd WiiStep
./bootstrap.sh
mkdir build && cd build
```

### Downloading PowerPC toolchain and libraries

The PowerPC toolchain (`devkitPPC`) and platform libaries (`libogc`)
must be downloaded separately from SourceForge.

#### devkitPPC

Download binary from here (for your platform):
http://sourceforge.net/projects/devkitpro/files/devkitPPC/

Then extract the archive, rename the directory to plain `devkitPPC` 
(without version suffixes) and place it in `WiiStep/build`.

#### libogc

Download binary from here (not libogc-src):
http://sourceforge.net/projects/devkitpro/files/libogc/

Then extract the archive, rename the directory to plain `libogc` 
(without version suffixes) and place it in `WiiStep/build`. 

#### libfat

Download binary from here (libfat-ogc):
http://sourceforge.net/projects/devkitpro/files/libfat/

Then extract the archive, rename the directory to plain `libfat` 
(without version suffixes) and place it in `WiiStep/build`. 

### Now Run CMake

```sh
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

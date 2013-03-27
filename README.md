What It Is
----------

A *Cmake-driven, auto-installing suite of free software*; combined to
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

Code-linking tools and the fundamental C/C++ runtimes are provided 
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

Aaand...That's it. All other dependencies are automatically fetched within 
`git submodule` and the provided `wsinstall` target.

### And Those Would Be?

* Via **Git-Submodule**:
    * [`llvm`](http://llvm.org/) for [linking](http://llvm.org/docs/CommandGuide/llvm-link.html), [optimising](http://llvm.org/docs/CommandGuide/opt.html), and [PowerPC](http://llvm.org/docs/CodeGenerator.html#the-powerpc-backend) [Code Generation](http://llvm.org/docs/CommandGuide/llc.html)
    * [`clang`](http://clang.llvm.org) for providing modern [C](http://clang.llvm.org/docs/BlockLanguageSpec.html) and [Objective-C](http://clang.llvm.org/docs/AutomaticReferenceCounting.html) magic
    * [`gnustep-libobjc2`](http://GNUstep.org) continuing the magic [at runtime](https://github.com/jackoalan/gnustep-libobjc2#readme)
    * [`gnustep-base`](http://GNUstep.org) providing a default *Foundation.framework* implementation
    * `libffi`
    * `compiler-rt`
    * `gnustep-make`
* Via **wsinstall**:
    * [devkitPPC](http://devkitpro.org) GCC-forked toolchain for performing final .ELF link
    * [libogc](http://wiibrew.org/wiki/Libogc) open-source OS ([multithreaded kernel contained in app](http://en.wikipedia.org/wiki/Light-weight_process)) and HW drivers (also in app)


How To Do
---------

### Basically:

```sh
cd <Where i should be>
git clone https://github.com/jackoalan/WiiStep.git
cd WiiStep
./wsprep.sh
mkdir build && cd build
cmake ..
make
```

[Details on the CMake method](https://github.com/jackoalan/WiiStep/tree/master/cmake#readme) 
are also available. 

After the build completes, there will be two *important* files in the 
build directory. These files are used by [adoptable CMake modules](https://github.com/jackoalan/WiiStep/tree/master/cmake#making-a-wiistep-application-with-cmake) 
to automate the correct compilation sequence for app sources. 


### Using these two files, the general build process goes like this:

### libobjc-wii.a

First, `libobjc-wii.a` *isn't* a gcc-compatible ELF archive; it actually
is *LLVM-IR-bitcode* linked together (with [`llvm-link`](http://llvm.org/docs/CommandGuide/llvm-link.html)) and used like an archive. 
This *.bc* file is utilised by the application build system's own invocation 
of `llvm-link`.

Once the application's 
WiiStep-using code is linked with `libobjc-wii.a`, LLVM's [`opt`](http://llvm.org/docs/CommandGuide/opt.html)
may be ran with the `-gnu-objc` flag to apply various transformations
to the code making it run very efficiently within the WiiStep Runtime.

Finally, the LLVM static compiler, [`llc`](http://llvm.org/docs/CommandGuide/llc.html),
performs the final LLVM-to-PPC conversion and emits a PPC-assembly
(.S) file. 

This file may essentially be the entire application and WiiStep runtime
minus any ELF archives that should be linked in during the final link (*libogc*
and *wiiuse* are notable examples).

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
    * Also includes libobjc-wii.a
    * May include extra Objective-C frameworks like *Foundation*
* libobjc-wii-asm.a
* libogc (OS and most drivers)
* libbte (Bluetooth stack)
* libwiiuse (Wii Remote API)
* Any other what-have-you ELF archives

The result will be an *.ELF* executable file ready for conversion into a 
*.DOL* executable. `elf2dol` in devkitPPC may be used to do the 

Once done, the DOL should launch on a production Wii and return to the 
launching app correctly according to Nintendo's apploader design.

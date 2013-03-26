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

* [Clang/LLVM toolchain](http://llvm.org)
    * `clang` C/C++/Objective-C compiler frontend
    * `llvm-link` LLVM bitcode linker
    * `llc` LLVM static compiler (for [PowerPC Code Generation](http://llvm.org/docs/CodeGenerator.html#the-powerpc-backend))
    * Xcode's bundled `clang` works fine (but doesn't include `llc` or `llvm-link`)
    * [MacPorts](http://macports.org) distributes a working `llc` and `llvm-link` as `llc-mp-3.3` and `llvm-link-mp-3.3`
* [Cmake 2.8](http://www.cmake.org) (or greater)

Aaand...That's it. All other dependencies are automatically fetched within 
`git submodule` and the provided `wsinstall` target.


How To Do
---------

Basically:

```sh
cd <Where i should be>
git clone https://github.com/jackoalan/WiiStep.git
cd WiiStep
./wsprep.sh
mkdir build && cd build
cmake ..
make
```

After the (noisy) build completes, there will be two *important* files in the 
build directory:


### libobjc-wii.a

First, `libobjc-wii.a` *isn't* a gcc-compatible ELF archive; it actually
is *LLVM-IR-bitcode* linked together (with [`llvm-link`](http://llvm.org/docs/CommandGuide/llvm-link.html)) and used like an archive. 
This *.bc* file is utilised by the application build system's own invocation 
of `llvm-link`. A CMake module will soon be written to simplify WiiStep's 
integration into an application's CMake project. 

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
*.DOL* executable. `elf2dol` in devkitPPC may be used to do the conversion.

Again, the pending CMake module may perform all of these tasks as well. 

Once done, the DOL should launch on a production Wii and return to the 
launching app correctly according to Nintendo's apploader design.

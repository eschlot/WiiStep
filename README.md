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
[GNUStep-Base](https://github.com/gnustep/gnustep-base) implementation.

The GNUStep project also provides the [libobjc2](https://github.com/gnustep/gnustep-libobjc2)
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
    * `llc` static compiler (for [PowerPC Code Generation](http://llvm.org/docs/CodeGenerator.html#the-powerpc-backend))
    * Xcode's bundled `clang` works fine (but doesn't include `llc`)
    * [MacPorts](http://macports.org) distributes a working `llc` as `llc-mp-3.3`
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
git submodule init
git submodule update
mkdir build && cd build
cmake ..
make
```

After the (noisy) build completes, the resulting `libobjc.a` in the Cmake build
directory may be linked into an ELF executable with devkitPPC's `powerpc-eabi-gcc` 
alongside `libogc.a` and the application code. After running `elf2dol` on this ELF, 
the resulting DOL may be loaded onto an actual Wii using one of the many homebrew 
methods available.

What It Is
----------

A *Cmake-driven, auto-installing suite of free software*; combined to
form a *Foundation Framework based* (non-GUI), modern **Objective-C 
Development Environment**. 

The environment is suitable for authoring Objective-C sources against
familiar Framework-APIs for intended execution on the Wii.

Code-linking tools and the fundamental C/C++ runtimes are provided 
by [devkitPPC](http://devkitpro.org). Platform abstraction is 
accomplished using externally-linked [libogc](http://libogc.devkitpro.org). 

Optionally, certain libogc platform-functionality (threads and locks) may be 
substituted for symbols present in RVL_SDK 2.1, based on headers floating 
around the internet. Add `-DWIISTEP_PLATFORM="RVL_SDK"` to the `cmake` command 
if this route is preferred.


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



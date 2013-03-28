#!/bin/sh

# Need 1 argument
if [ $# -ne 1 ]
then
echo "Usage: build-llvm <CMAKE_INSTALL_PREFIX>"
exit -1
fi

# Build LLVM (and Clang, compiler-rt)
pushd llvm
mkdir build
pushd build
cmake -DCMAKE_INSTALL_PREFIX="$1" -DLLVM_DEFAULT_TARGET_TRIPLE="powerpc-generic-eabi" -DLLVM_TARGETS_TO_BUILD="PowerPC" ..
make
popd
popd

touch llvm-built

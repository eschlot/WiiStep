#!/bin/sh

# Fetch Submodules
git submodule init
git submodule update

# Build LLVM (and Clang, compiler-rt)
pushd llvm
mkdir build
pushd build
cmake -DLLVM_TARGETS_TO_BUILD="PowerPC" ..
make
popd
popd

# Note that we finished
touch wsprep-ran

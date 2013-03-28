#!/bin/sh

# Fetch Submodules
git submodule init
git submodule update

# Note that we finished
touch wsprep-ran

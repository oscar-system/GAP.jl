#!/usr/bin/env bash

set -e

# Download and install GAP
git clone --depth=1 https://github.com/gap-system/gap
cd gap
./autogen.sh
./configure --with-gc=julia --with-julia
make -j4
make bootstrap-pkg-minimal

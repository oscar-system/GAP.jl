#!/usr/bin/env bash

set -e

main_dir=${PWD}

# Download and install Julia
wget https://julialangnightlies-s3.julialang.org/bin/linux/x64/julia-latest-linux64.tar.gz
mkdir julia 
tar xf julia-latest-linux64.tar.gz -C julia --strip-components 1

# Download and install GAP
# TODO: test with both GAP master and stable-4.10
git clone --depth=1 https://github.com/gap-system/gap -b stable-4.10
cd gap
./autogen.sh
./configure --with-gc=julia --with-julia=${main_dir}/julia/
make -j4
make libgap.la
make bootstrap-pkg-minimal

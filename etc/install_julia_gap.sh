#!/usr/bin/env bash

set -e

main_dir=${PWD}

# Download and install Julia
wget https://julialangnightlies-s3.julialang.org/bin/linux/x64/julia-latest-linux64.tar.gz
mkdir julia 
tar xf julia-latest-linux64.tar.gz -C julia --strip-components 1

# Download and install GAP
git clone --depth=1 https://github.com/gap-system/gap
cd gap
./autogen.sh
./configure --with-gc=julia --with-julia=${main_dir}/julia/
make -j4
make bootstrap-pkg-minimal
cd pkg
git clone https://github.com/oscar-system/GAPJulia
cd GAPJulia/JuliaInterface
./configure
make

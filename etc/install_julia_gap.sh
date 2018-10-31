#!/usr/bin/env bash

set -e

main_dir=${PWD}

# Download and install Julia
wget https://julialangnightlies-s3.julialang.org/bin/linux/x64/julia-latest-linux64.tar.gz
mkdir julia 
tar xf julia-latest-linux64.tar.gz -C julia --strip-components 1

# Download and install GAP
#git clone --depth=1 https://github.com/gap-system/gap
git clone --depth=1 https://github.com/rbehrends/gap -b alt-gc
cd gap
./autogen.sh
./configure --with-gc=julia --with-julia=${main_dir}/julia/
make -j4
make libgap.la
make bootstrap-pkg-minimal

# Download and install GAPJulia
if [[ $DONT_FETCH_GAP_JULIA_PKG = yes ]] ; then exit 0; fi
cd pkg
git clone https://github.com/oscar-system/GAPJulia
cd GAPJulia/JuliaInterface
./configure
make

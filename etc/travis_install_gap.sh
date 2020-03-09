#!/usr/bin/env bash

set -e

# Download and install GAP
GAP_VERSION_SERIES=4.11
GAP_VERSION=4.11.0

# TODO: gap-system.org availability is flaky, which often breaks CI builds; so use
# github mirror instead, which is more reliable, albeit somewhat slower
#wget https://www.gap-system.org/pub/gap/gap-${GAP_VERSION_SERIES}/tar.bz2/gap-${GAP_VERSION}.tar.bz2
wget https://github.com/gap-system/gap/releases/download/v${GAP_VERSION}/gap-${GAP_VERSION}.tar.bz2
tar xf gap-${GAP_VERSION}.tar.bz2
cd gap-${GAP_VERSION}
./configure --with-gc=julia --with-julia
make -j4

# build a few packages
cd pkg
$GAPROOT/bin/BuildPackages.sh --with-gaproot=$GAPROOT io* profiling*

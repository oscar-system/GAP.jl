#!/usr/bin/env bash

set -e

pushd $GAPROOT/pkg
  git clone https://github.com/gap-packages/io
  git clone https://github.com/gap-packages/profiling
  $GAPROOT/bin/BuildPackages.sh
popd

# Build our packages with coverage
export CFLAGS=--coverage
export LDFLAGS=--coverage
./configure $GAPROOT
make

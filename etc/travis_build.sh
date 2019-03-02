#!/usr/bin/env bash

set -e

cd $GAP_ROOT/pkg

git clone https://github.com/gap-packages/io
git clone https://github.com/gap-packages/profiling

$GAP_ROOT/bin/BuildPackages.sh --with-gaproot=$GAP_ROOT io profiling

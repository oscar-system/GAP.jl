#!/usr/bin/env bash

set -e

cd $GAPROOT/pkg

git clone https://github.com/gap-packages/io
git clone https://github.com/gap-packages/profiling

$GAPROOT/bin/BuildPackages.sh --with-gaproot=$GAPROOT io profiling

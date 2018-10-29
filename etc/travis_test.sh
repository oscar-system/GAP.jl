#!/bin/sh

set -e

export CFLAGS=--coverage
export LDFLAGS=--coverage

./configure $GAPROOT
make

cd JuliaInterface
pwd
$GAPROOT/gap -A --quitonbreak --norepl --cover $TRAVIS_BUILD_DIR/coverage/JuliaInterface tst/testall.g
gcov -o .. src/*.c*
cd ..

cd JuliaExperimental
pwd
$GAPROOT/gap -A --quitonbreak --norepl --cover $TRAVIS_BUILD_DIR/coverage/JuliaExperimental tst/testall.g
gcov -o .. src/*.c*
cd ..

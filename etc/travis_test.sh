#!/bin/sh

set -e

export CFLAGS=--coverage
export LDFLAGS=--coverage

# check code formatting
find . -name '*.c' -exec clang-format -i {} \;
find . -name '*.h' -exec clang-format -i {} \;
git diff --exit-code -- . # detect if there are any diffs


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

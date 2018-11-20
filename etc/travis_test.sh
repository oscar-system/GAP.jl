#!/bin/sh

set -e

export CFLAGS=--coverage
export LDFLAGS=--coverage

AnyFailures=No

# check code formatting
find . -name '*.c' -exec clang-format -i {} \;
find . -name '*.h' -exec clang-format -i {} \;
git diff --exit-code -- . # detect if there are any diffs


./configure $GAPROOT
make

#
cd JuliaInterface
pwd
$GAPROOT/gap -A --quitonbreak --norepl --cover $TRAVIS_BUILD_DIR/coverage/JuliaInterface tst/testall.g || AnyFailures=Yes
gcov -o .. src/*.c*
cd ..

#
cd JuliaExperimental
pwd
$GAPROOT/gap -A --quitonbreak --norepl --cover $TRAVIS_BUILD_DIR/coverage/JuliaExperimental tst/testall.g || AnyFailures=Yes
gcov -o .. src/*.c*
cd ..

#
cd LibGAP.jl
pwd
${JULIAROOT}/bin/julia --code-coverage --inline=no test/runtests.jl || AnyFailures=Yes
cd ..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

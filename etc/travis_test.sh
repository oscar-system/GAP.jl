#!/bin/sh

set -e

export CFLAGS=--coverage
export LDFLAGS=--coverage

AnyFailures=No

# check code formatting
find . -name '*.c' -exec clang-format -i {} \;
find . -name '*.h' -exec clang-format -i {} \;
git diff --exit-code -- '*.c' '*.h' # detect if there are any diffs



#
cd ${TRAVIS_BUILD_DIR}/pkg/GAPJulia/JuliaInterface
pwd
${HOME}/.julia/gap -A --quitonbreak --norepl --cover ${TRAVIS_BUILD_DIR}/coverage/JuliaInterface tst/testall.g || AnyFailures=Yes
gcov -o .. src/*.c*
cd ..

#
cd ${TRAVIS_BUILD_DIR}/pkg/GAPJulia/JuliaExperimental
pwd
${HOME}/.julia/gap -A --quitonbreak --norepl --cover ${TRAVIS_BUILD_DIR}/coverage/JuliaExperimental tst/testall.g || AnyFailures=Yes
gcov -o .. src/*.c*
cd ..

#
pwd
julia --project="$JULIA_PROJECT" --code-coverage --inline=no -e 'using Pkg ; Pkg.test("GAP")' || AnyFailures=Yes
cd ..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

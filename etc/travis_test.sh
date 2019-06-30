#!/bin/sh

set -e
set -x

AnyFailures=No

# check code formatting
find . -name '*.c' -exec clang-format -i {} \;
find . -name '*.h' -exec clang-format -i {} \;
git diff --exit-code -- . # detect if there are any diffs

#
GAP="${HOME}/.julia/gap -A --quitonbreak --norepl"

#
cd ${TRAVIS_BUILD_DIR}/pkg/GAPJulia/JuliaInterface
pwd
${GAP} makedoc.g
${GAP} --cover ${TRAVIS_BUILD_DIR}/coverage/JuliaInterface.coverage tst/testall.g || AnyFailures=Yes
gcov -o $HOME/.julia/packages/GAP/*/pkg/GAPJulia/JuliaInterface/gen/src/.libs src/*.c*
cd ..

#
cd ${TRAVIS_BUILD_DIR}/pkg/GAPJulia/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ${TRAVIS_BUILD_DIR}/coverage/JuliaExperimental.coverage tst/testall.g || AnyFailures=Yes
gcov -o $HOME/.julia/packages/GAP/*/pkg/GAPJulia/JuliaExperimental/gen/src/.libs src/*.c*
cd ..

#
pwd
julia -e 'using Pkg ; Pkg.test("GAP"; coverage=true)' || AnyFailures=Yes

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

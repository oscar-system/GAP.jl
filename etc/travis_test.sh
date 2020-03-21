#!/bin/sh

set -e
set -x

AnyFailures=No

#
cd ${TRAVIS_BUILD_DIR}/pkg/JuliaInterface
pwd
${GAP} makedoc.g
${GAP} --cover ${TRAVIS_BUILD_DIR}/coverage/JuliaInterface.coverage tst/testall.g || AnyFailures=Yes
gcov -o $HOME/.julia/packages/GAP/*/pkg/JuliaInterface/gen/src/.libs src/*.c*
cd ..

#
cd ${TRAVIS_BUILD_DIR}/pkg/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ${TRAVIS_BUILD_DIR}/coverage/JuliaExperimental.coverage tst/testall.g || AnyFailures=Yes
gcov -o $HOME/.julia/packages/GAP/*/pkg/JuliaExperimental/gen/src/.libs src/*.c*
cd ..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

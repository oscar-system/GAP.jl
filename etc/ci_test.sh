#!/bin/sh

set -e
set -x

AnyFailures=No

mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaInterface.coverage tst/testall.g || AnyFailures=Yes
gcov -o gen/src/.libs src/*.c*
cd ../..

#
cd pkg/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaExperimental.coverage tst/testall.g || AnyFailures=Yes
gcov -o gen/src/.libs src/*.c*
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

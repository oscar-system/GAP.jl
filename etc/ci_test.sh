#!/bin/sh

set -e
set -x

AnyFailures=No

mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
# Force recompilation of JuliaInterface with coverage instrumentation.
# Use a fixed object directory so that gcov can find .gcno/.gcda files.
CFLAGS="--coverage" LDFLAGS="--coverage" FORCE_JULIAINTERFACE_COMPILATION=. ${GAP} --nointeract
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaInterface.coverage -r tst/testall.g || AnyFailures=Yes
gcov -o gen/src/ src/*.c*
rm -rf gen # Delete the coverage instrumentation in JuliaInterface again
cd ../..

#
cd pkg/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaExperimental.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

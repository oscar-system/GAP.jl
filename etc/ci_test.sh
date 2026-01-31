#!/bin/sh

set -e
set -x

AnyFailures=No

# Force recompilation of JuliaInterface with coverage instrumentation
export CFLAGS="--coverage"
export LDFLAGS="--coverage"
mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
# Force recompilation of JuliaInterface with coverage instrumentation.
# Use a fixed build directory so that gcov can find .gcno/.gcda files.
export FORCE_JULIAINTERFACE_COMPILATION=tmp
${GAP} --cover ../../coverage/JuliaInterface.coverage -r makedoc.g tst/testall.g || AnyFailures=Yes
gcov -o tmp/gen/src/ src/*.c*
rm -rf tmp # Delete the coverage instrumentation in JuliaInterface again
cd ../..

#
export FORCE_JULIAINTERFACE_COMPILATION=
cd pkg/JuliaExperimental
pwd
${GAP} --cover ../../coverage/JuliaExperimental.coverage -r makedoc.g tst/testall.g || AnyFailures=Yes
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

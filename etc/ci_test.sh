#!/bin/sh

set -e
set -x

AnyFailures=No

# Force recompilation of JuliaInterface with coverage instrumentation
export CFLAGS="--coverage"
export LDFLAGS="--coverage"
export FORCE_JULIAINTERFACE_COMPILATION=true

mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
${GAP} --cover ../../coverage/JuliaInterface.coverage -r makedoc.g tst/testall.g || AnyFailures=Yes
gcov -o gen/src/ src/*.c*
cd ../..

#
cd pkg/JuliaExperimental
pwd
${GAP} --cover ../../coverage/JuliaExperimental.coverage -r makedoc.g tst/testall.g || AnyFailures=Yes
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

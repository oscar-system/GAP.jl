#!/bin/sh

set -e
set -x

AnyFailures=No

JuliaInterfaceBuildDir="${PWD}/pkg/JuliaInterface/tmp"

export CFLAGS="${CFLAGS:+${CFLAGS} }--coverage"
export LDFLAGS="${LDFLAGS:+${LDFLAGS} }--coverage"
export FORCE_JULIAINTERFACE_COMPILATION="${JuliaInterfaceBuildDir}"

mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
# Force recompilation of JuliaInterface with coverage instrumentation.
# Use a fixed build directory so that gcov can find .gcno/.gcda files.
${GAP} --nointeract
JuliaInterfaceSo=$(find "${JuliaInterfaceBuildDir}/bin" -name JuliaInterface.so -type f | head -n 1)
test -n "${JuliaInterfaceSo}"
export GAP_JL_JULIAINTERFACE_SO="${JuliaInterfaceSo}"
unset FORCE_JULIAINTERFACE_COMPILATION

${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaInterface.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

#
cd pkg/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaExperimental.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

cd pkg/JuliaInterface
gcov -o "${JuliaInterfaceBuildDir}/gen/src/" src/*.c*
rm -rf "${JuliaInterfaceBuildDir}" # Delete the coverage instrumentation in JuliaInterface again
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

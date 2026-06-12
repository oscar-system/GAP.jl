#!/bin/sh

set -e
set -x

AnyFailures=No

JuliaInterfaceBuildDir="${JULIAINTERFACE_COVERAGE_BUILD_DIR:-${PWD}/pkg/JuliaInterface/tmp}"
RemoveJuliaInterfaceBuildDir=No

export CFLAGS="${CFLAGS:+${CFLAGS} }--coverage"
export LDFLAGS="${LDFLAGS:+${LDFLAGS} }--coverage"

mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
if [ -n "${GAP_JL_JULIAINTERFACE_SO:-}" ]
then
    JuliaInterfaceSo="${GAP_JL_JULIAINTERFACE_SO}"
    test -f "${JuliaInterfaceSo}"
    JuliaInterfaceBuildDir=$(cd "$(dirname "${JuliaInterfaceSo}")/../.." && pwd)
    unset FORCE_JULIAINTERFACE_COMPILATION
else
    # Force recompilation of JuliaInterface with coverage instrumentation.
    # Use a fixed build directory so that gcov can find .gcno/.gcda files.
    export FORCE_JULIAINTERFACE_COMPILATION="${JuliaInterfaceBuildDir}"
    ${GAP} --nointeract
    JuliaInterfaceSo=$(find "${JuliaInterfaceBuildDir}/bin" -name JuliaInterface.so -type f | head -n 1)
    test -n "${JuliaInterfaceSo}"
    export GAP_JL_JULIAINTERFACE_SO="${JuliaInterfaceSo}"
    unset FORCE_JULIAINTERFACE_COMPILATION
    RemoveJuliaInterfaceBuildDir=Yes
fi
test -d "${JuliaInterfaceBuildDir}/gen/src"

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
if [ "${RemoveJuliaInterfaceBuildDir}" = Yes ]
then
    rm -rf "${JuliaInterfaceBuildDir}" # Delete the coverage instrumentation in JuliaInterface again
fi
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

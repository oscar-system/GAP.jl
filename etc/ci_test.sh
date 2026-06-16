#!/bin/sh

set -e
set -x

AnyFailures=No

DefaultJuliaInterfaceBuildDir="${PWD}/pkg/JuliaInterface/tmp"
JuliaInterfaceBuildDir="${DefaultJuliaInterfaceBuildDir}"
RemoveJuliaInterfaceBuildDir=No

build_JuliaInterface_for_coverage() {
    JuliaInterfaceBuildDir="${DefaultJuliaInterfaceBuildDir}"
    mkdir -p "${JuliaInterfaceBuildDir}"
    JuliaInterfaceBuildDir=$(cd "${JuliaInterfaceBuildDir}" && pwd)
    # Force recompilation of JuliaInterface with coverage instrumentation.
    # Use a fixed build directory so that gcov can find .gcno/.gcda files.
    export FORCE_JULIAINTERFACE_COMPILATION="${JuliaInterfaceBuildDir}"
    ${GAP} --nointeract
    JuliaInterfaceSo=$(find "${JuliaInterfaceBuildDir}/bin" -name JuliaInterface.so -type f | head -n 1)
    test -n "${JuliaInterfaceSo}"
    export GAP_JL_JULIAINTERFACE_SO="${JuliaInterfaceSo}"
    unset FORCE_JULIAINTERFACE_COMPILATION
    RemoveJuliaInterfaceBuildDir=Yes
}

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
    if [ -d "${JuliaInterfaceBuildDir}/gen/src" ] && ls "${JuliaInterfaceBuildDir}"/gen/src/*.gcno >/dev/null 2>&1
    then
        unset FORCE_JULIAINTERFACE_COMPILATION
        RemoveJuliaInterfaceBuildDir=No
    else
        unset GAP_JL_JULIAINTERFACE_SO
        build_JuliaInterface_for_coverage
    fi
else
    build_JuliaInterface_for_coverage
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

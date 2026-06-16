#!/bin/sh

set -e
set -x

AnyFailures=No

# If this script has to build JuliaInterface itself, use a predictable
# out-of-tree build directory below the checkout. gcov needs the matching
# .gcno files from that build directory after the tests have run.
DefaultJuliaInterfaceBuildDir="${PWD}/pkg/JuliaInterface/tmp"

# This may be replaced below when a caller provides GAP_JL_JULIAINTERFACE_SO.
# In that case it points at the build directory containing the provided .so.
JuliaInterfaceBuildDir="${DefaultJuliaInterfaceBuildDir}"

# Only delete the build directory when this script created it. Callers that
# prebuild and pass GAP_JL_JULIAINTERFACE_SO own their build directory.
RemoveJuliaInterfaceBuildDir=No

build_JuliaInterface_for_coverage() {
    JuliaInterfaceBuildDir="${DefaultJuliaInterfaceBuildDir}"
    mkdir -p "${JuliaInterfaceBuildDir}"
    JuliaInterfaceBuildDir=$(cd "${JuliaInterfaceBuildDir}" && pwd)

    # Force recompilation of JuliaInterface with coverage instrumentation.
    # Use a fixed build directory so that gcov can find .gcno/.gcda files.
    export FORCE_JULIAINTERFACE_COMPILATION="${JuliaInterfaceBuildDir}"
    ${GAP} --nointeract

    # Tell subsequent GAP.jl sessions to load this instrumented library instead
    # of rebuilding or using the JLL-provided JuliaInterface.so.
    JuliaInterfaceSo=$(find "${JuliaInterfaceBuildDir}/bin" -name JuliaInterface.so -type f | head -n 1)
    test -n "${JuliaInterfaceSo}"
    export GAP_JL_JULIAINTERFACE_SO="${JuliaInterfaceSo}"
    unset FORCE_JULIAINTERFACE_COMPILATION
    RemoveJuliaInterfaceBuildDir=Yes
}

export CFLAGS="${CFLAGS:+${CFLAGS} }--coverage"
export LDFLAGS="${LDFLAGS:+${LDFLAGS} }--coverage"

mkdir -p coverage

# Enter the JuliaInterface GAP package directory. makedoc.g, tst/testall.g,
# and the later gcov invocation are all relative to this directory.
cd pkg/JuliaInterface
pwd

# Some callers, notably the treehash workflow, prebuild an instrumented
# JuliaInterface.so and pass it in GAP_JL_JULIAINTERFACE_SO. Reuse it only if
# it comes from a gcov build: the .so path alone is not enough, because other
# workflows may also force a local build without coverage instrumentation.
if [ -n "${GAP_JL_JULIAINTERFACE_SO:-}" ]
then
    JuliaInterfaceSo="${GAP_JL_JULIAINTERFACE_SO}"
    test -f "${JuliaInterfaceSo}"
    JuliaInterfaceBuildDir=$(cd "$(dirname "${JuliaInterfaceSo}")/../.." && pwd)

    # gcov requires .gcno files emitted at compile time. If they are missing,
    # ignore the provided library and build a coverage-instrumented one here.
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

# Build the JuliaInterface manual. This also checks the manual examples.
${GAP} makedoc.g

# Run the JuliaInterface GAP test suite while collecting GAP-level coverage.
${GAP} --cover ../../coverage/JuliaInterface.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

# Build docs and run the JuliaExperimental GAP tests as part of the bundled
# GAP package checks. These reuse the same instrumented JuliaInterface.so.
cd pkg/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaExperimental.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

# Convert the C coverage counters from the instrumented JuliaInterface build
# into .gcov files for Codecov. This must happen before deleting the build dir.
cd pkg/JuliaInterface
gcov -o "${JuliaInterfaceBuildDir}/gen/src/" src/*.c*

# Avoid leaving this script's temporary coverage build behind. When the build
# was supplied by the caller, keep it available for later workflow steps.
if [ "${RemoveJuliaInterfaceBuildDir}" = Yes ]
then
    rm -rf "${JuliaInterfaceBuildDir}" # Delete the coverage instrumentation in JuliaInterface again
fi
cd ../..

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

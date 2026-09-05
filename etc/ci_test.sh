#!/bin/sh

set -e
set -x

AnyFailures=No

# C coverage is deliberately opt-in. Clang on macOS and GCC on Linux disagree
# about which source lines are executable, so merging their reports can mark
# covered continuation lines and case labels as uncovered. Only the Julia LTS
# rebuild job using GCC on Linux sets JULIAINTERFACE_COVERAGE=Yes.
if [ "${JULIAINTERFACE_COVERAGE:-No}" = Yes ]
then
    # If this script has to build JuliaInterface itself, use a predictable
    # out-of-tree build directory below the checkout. gcov needs the matching
    # .gcno files from that build directory after the tests have run.
    DefaultJuliaInterfaceBuildDir="${PWD}/pkg/JuliaInterface/tmp"

    # Start with the default directory. If the caller provides an instrumented
    # .so below, derive and use the directory in which that library was built.
    JuliaInterfaceBuildDir="${DefaultJuliaInterfaceBuildDir}"

    # Only delete the build directory when this script created it. Callers that
    # prebuild and pass GAP_JL_JULIAINTERFACE_SO own their build directory.
    RemoveJuliaInterfaceBuildDir=No

    build_JuliaInterface_for_coverage() {
        JuliaInterfaceBuildDir="${DefaultJuliaInterfaceBuildDir}"
        mkdir -p "${JuliaInterfaceBuildDir}"
        JuliaInterfaceBuildDir=$(cd "${JuliaInterfaceBuildDir}" && pwd)

        # The presence of FORCE_JULIAINTERFACE_COMPILATION bypasses the matching
        # JLL, while JULIAINTERFACE_BUILD_DIR keeps the gcov files in a known
        # location.
        export FORCE_JULIAINTERFACE_COMPILATION=
        export JULIAINTERFACE_BUILD_DIR="${JuliaInterfaceBuildDir}"

        # Trigger a GAP.jl load to compile JuliaInterface.so, then record its
        # path for the subsequent test processes.
        ${GAP} --nointeract -c 'FileString("juliainterface.path", JuliaToGAP(IsString, GAP_jl.JuliaInterface_path)); QUIT;'

        # Load this instrumented library instead of rebuilding or using the
        # JLL-provided JuliaInterface.so.
        JuliaInterfaceSo=$(cat juliainterface.path)
        test -f "${JuliaInterfaceSo}"
        export GAP_JL_JULIAINTERFACE_SO="${JuliaInterfaceSo}"
        unset FORCE_JULIAINTERFACE_COMPILATION
        unset JULIAINTERFACE_BUILD_DIR
        RemoveJuliaInterfaceBuildDir=Yes
    }

    export CFLAGS="${CFLAGS:+${CFLAGS} }--coverage"
    export LDFLAGS="${LDFLAGS:+${LDFLAGS} }--coverage"
fi

mkdir -p coverage

# Enter the JuliaInterface GAP package directory. makedoc.g, tst/testall.g,
# and the optional gcov invocation are all relative to this directory.
cd pkg/JuliaInterface
pwd  # for debugging

if [ "${JULIAINTERFACE_COVERAGE:-No}" = Yes ]
then
    # The Linux LTS rebuild job passes its instrumented JuliaInterface.so in
    # GAP_JL_JULIAINTERFACE_SO. Reuse it only if it comes from a gcov build:
    # the .so path alone does not prove that it was instrumented.
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
            unset JULIAINTERFACE_BUILD_DIR
            RemoveJuliaInterfaceBuildDir=No
        else
            unset GAP_JL_JULIAINTERFACE_SO
            build_JuliaInterface_for_coverage
        fi
    else
        build_JuliaInterface_for_coverage
    fi
    test -d "${JuliaInterfaceBuildDir}/gen/src"
fi

# Build the JuliaInterface manual. This also checks the manual examples.
${GAP} makedoc.g

# Run the JuliaInterface GAP test suite while collecting GAP-level coverage.
${GAP} --cover ../../coverage/JuliaInterface.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

# Build docs and run the JuliaExperimental GAP tests as part of the bundled
# GAP package checks. The coverage job reuses its instrumented library here.
cd pkg/JuliaExperimental
pwd
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaExperimental.coverage -r tst/testall.g || AnyFailures=Yes
cd ../..

# Only the Linux LTS rebuild job emits JuliaInterface C coverage. Convert its
# counters before deleting a build created here; caller-owned builds remain
# available for later workflow steps.
if [ "${JULIAINTERFACE_COVERAGE:-No}" = Yes ]
then
    cd pkg/JuliaInterface
    gcov -o "${JuliaInterfaceBuildDir}/gen/src/" src/*.c*

    # Avoid leaving this script's temporary coverage build behind. When the build
    # was supplied by the caller, keep it available for later workflow steps.
    if [ "${RemoveJuliaInterfaceBuildDir}" = Yes ]
    then
        rm -rf "${JuliaInterfaceBuildDir}" # Delete the coverage instrumentation in JuliaInterface again
    fi
    cd ../..
fi

if [ ${AnyFailures} = Yes ]
then
    exit 1
fi

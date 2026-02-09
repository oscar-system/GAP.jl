#!/bin/sh

set -e
set -x

AnyFailures=No

mkdir -p coverage
#
cd pkg/JuliaInterface
pwd
# Force recompilation of JuliaInterface with coverage instrumentation
CFLAGS="--coverage" LDFLAGS="--coverage" FORCE_JULIAINTERFACE_COMPILATION=true ${GAP} --nointeract
${GAP} makedoc.g
${GAP} --cover ../../coverage/JuliaInterface.coverage -r tst/testall.g || AnyFailures=Yes
gcov -o gen/src/ src/*.c*
# We should delete the coverage instrumentation in JuliaInterface now
# by calling `make clean`. However, this does not work because the
# `gaproot_for_building` only exists while GAP.jl runs.
# So we instead start a new GAP.jl session that forces a recompilation
# of JuliaInterface with default settings, thus overwriting the
# coverage instrumentation.
FORCE_JULIAINTERFACE_COMPILATION=true ${GAP} --nointeract
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

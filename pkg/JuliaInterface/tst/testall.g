#
# JuliaInterface: Test interface to julia
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#

ReadPackage("JuliaInterface", "tst/testsetup.g");

TestDirectory(dir, rec(exitGAP := true,
                       testOptions := rec(compareFunction := compare) ) );
FORCE_QUIT_GAP(1);

#
# JuliaInterface: Test interface to julia
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage("JuliaInterface");
TestDirectory(DirectoriesPackageLibrary("JuliaInterface", "tst"), rec(exitGAP := true));
FORCE_QUIT_GAP(1);

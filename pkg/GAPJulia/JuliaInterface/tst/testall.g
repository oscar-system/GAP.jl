#
# JuliaInterface: Test interface to julia
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage("JuliaInterface");
dir:=DirectoriesPackageLibrary("JuliaInterface", "tst");
Assert(0, dir <> fail);
TestDirectory(dir, rec(exitGAP := true,
                       testOptions := rec(compareFunction := "uptowhitespace") ) );
FORCE_QUIT_GAP(1);

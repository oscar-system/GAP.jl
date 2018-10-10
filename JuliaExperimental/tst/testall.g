#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage( "JuliaExperimental" );

dirs := DirectoriesPackageLibrary( "JuliaExperimental", "tst" );
Assert(0, dir <> fail);

TestDirectory(dir, rec(exitGAP := true));

FORCE_QUIT_GAP(1);

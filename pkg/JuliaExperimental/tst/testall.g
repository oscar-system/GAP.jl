#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file runs package tests.
# It is referenced in the package metadata in PackageInfo.g.
#

ReadPackage("JuliaExperimental", "tst/testsetup.g");

TestDirectory( files, rec(exitGAP := true,
                          testOptions := rec(compareFunction := "uptowhitespace") ) );

FORCE_QUIT_GAP(1);

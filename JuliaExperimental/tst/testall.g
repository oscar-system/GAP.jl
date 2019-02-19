#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file runs package tests.
# It is referenced in the package metadata in PackageInfo.g.
#
LoadPackage( "JuliaExperimental" );

pairs:= [
  [ "context.tst", [ "Nemo" ] ],
  [ "gapnemo.tst", [ "Nemo" ] ],
  [ "gapperm.tst", [] ],
  [ "hnf.tst", [ "Nemo" ] ],
  [ "loewy.tst", [ "Primes" ] ],
  [ "numfield.tst", [ "Nemo" ] ],
  [ "realcyc.tst", [ "Nemo" ] ],
  [ "singular.tst", [ "Singular" ] ],
  [ "utils.tst", [] ],
  [ "zmodnz.tst", [ "Nemo" ] ],
];

dirs:= DirectoriesPackageLibrary( "JuliaExperimental", "tst" );
Assert(0, dirs <> fail);

# Run only those tests that are supported by the current Julia installation.
pairs:= Filtered( pairs, x -> ForAll( x[2], JuliaImportPackage ) );
files:= List( pairs, x -> Filename( dirs, x[1] ) );
if fail in files then
  Print( "#E  unavailable test files:\n",
         List( pairs{ Positions( files, fail ) }, x -> x[1] ), "\n" );
  files:= Filtered( files, IsString );
fi;

TestDirectory( files, rec(exitGAP := true,
                          testOptions := rec(compareFunction := "uptowhitespace") ) );

FORCE_QUIT_GAP(1);


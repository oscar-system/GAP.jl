LoadPackage( "JuliaExperimental" );

pairs:= [
  [ "context.tst", [ "Nemo" ] ],
  [ "gapnemo.tst", [ "Nemo" ] ],
  [ "gapperm.tst", [] ],
  [ "hnf.tst", [ "Nemo" ] ],
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

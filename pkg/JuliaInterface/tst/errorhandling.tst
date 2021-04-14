## Test handling of Julia errors.
gap> START_TEST( "errorhandling.tst" );

# don't interpret percent signs etc. in Julia error strings
gap> JuliaEvalString( "error( \"abc %, 1\" )" );
Error, abc %, 1

#
gap> STOP_TEST( "errorhandling.tst", 1 );

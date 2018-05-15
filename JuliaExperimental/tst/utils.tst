#############################################################################
##
#W  utils.tst         GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "utils.tst" );

##
gap> JuliaUsingPackage( "Core" );
true
gap> JuliaUsingPackage( "No_Julia_Package_With_This_Name" );
#I  The Julia package 'No_Julia_Package_With_This_Name' cannot be loaded
false

##
gap> JuliaTypeInfo( 0 );
"Int64"
gap> JuliaTypeInfo( JuliaBox( 1 ) );
"Int64"
gap> JuliaTypeInfo( Julia.Base.parse );
"Base.#parse"

##
gap> RecNames( CallFuncListWithTimings( Julia.Base.sleep, [ 2 ] ) );
[ "result", "GAP_time", "Julia_time" ]

##
gap> STOP_TEST( "utils.tst", 1 );


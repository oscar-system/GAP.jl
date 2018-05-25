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

##  small or large integers
gap> l:= JuliaArrayOfFmpz( [ -2, -1, 0, 1, 2, 3 ] );
<Julia: Nemo.fmpz[-2, -1, 0, 1, 2, 3]>
gap> l:= JuliaArrayOfFmpz( [ 1, 2, 3, 2^70 ] );
<Julia: Nemo.fmpz[1, 2, 3, 1180591620717411303424]>

##  small or large rationals
gap> l:= JuliaArrayOfFmpq( [ -2, -1/2, 0, 1, 2/3, 3/7 ] );
<Julia: Nemo.fmpq[-2, -1//2, 0, 1, 2//3, 3//7]>
gap> l:= JuliaArrayOfFmpq( [ 2^70/3, 1/2^70 ] );
<Julia: Nemo.fmpq[1180591620717411303424//3, 1//1180591620717411303424]>

##
gap> RecNames( CallFuncListWithTimings( Julia.Base.sleep, [ 2 ] ) );
[ "result", "GAP_time", "Julia_time" ]

##
gap> STOP_TEST( "utils.tst", 1 );


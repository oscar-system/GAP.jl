#############################################################################
##
#W  gaprat.tst         GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "gaprat.tst" );

##
gap> x:= JuliaGAPRatInt( 3 );;
gap> y:= JuliaGAPRatInt( 4 );;
gap> JuliaObjGAPRat( x );
3

##  create GAPRat objects in Julia
gap> gaprat:= JuliaFunction( "GAPRat", "GAPRatModule" );;
gap> JuliaObjGAPRat( gaprat( JuliaBox( 1 ), JuliaBox( 2 ) ) );
1/2

##  test arithmetic operations with GAPRats
gap> zero:= GetJuliaFunc( "zero" )( x );;
gap> JuliaObjGAPRat( zero );
0
gap> JuliaObjGAPRat( GetJuliaFunc( "-" )( x ) );
-3
gap> JuliaObjGAPRat( GetJuliaFunc( "one" )( x ) );
1
gap> JuliaObjGAPRat( GetJuliaFunc( "inv" )( x ) );
1/3
gap> JuliaUnbox( GetJuliaFunc( "==" )( x, x ) );
true
gap> JuliaUnbox( GetJuliaFunc( "==" )( x, y ) );
false
gap> JuliaUnbox( GetJuliaFunc( "isless" )( x, y ) );
true
gap> JuliaUnbox( GetJuliaFunc( "isless" )( y, x ) );
false
gap> JuliaUnbox( GetJuliaFunc( "isless" )( x, x ) );
false
gap> JuliaObjGAPRat( GetJuliaFunc( "+" )( x, y ) );
7
gap> JuliaObjGAPRat( GetJuliaFunc( "-" )( x, y ) );
-1
gap> JuliaObjGAPRat( GetJuliaFunc( "*" )( x, y ) );
12
gap> JuliaObjGAPRat( GetJuliaFunc( "//" )( x, x ) );
1
gap> JuliaObjGAPRat( GetJuliaFunc( "^" )( x, y ) );
81
gap> JuliaObjGAPRat( GetJuliaFunc( "^" )( x, 2 ) );
9
gap> JuliaObjGAPRat( GetJuliaFunc( "mod" )( x, y ) );
3
gap> JuliaUnbox( GetJuliaFunc( "iszero" )( x ) );
false
gap> JuliaUnbox( GetJuliaFunc( "iszero" )( zero ) );
true
gap> JuliaUnbox( GetJuliaFunc( "==" )( x, x ) );
true
gap> JuliaUnbox( GetJuliaFunc( "==" )( x, y ) );
false
gap> JuliaUnbox( GetJuliaFunc( "isless" )( x, y ) );
true
gap> JuliaUnbox( GetJuliaFunc( "isless" )( y, x ) );
false
gap> JuliaUnbox( GetJuliaFunc( "isless" )( x, x ) );
false

##  test binary arithmetic operations with GAPRats and Julia integers
gap> j:= JuliaBox( 20 );;
gap> JuliaObjGAPRat( GetJuliaFunc( "+" )( x, j ) );
23
gap> JuliaObjGAPRat( GetJuliaFunc( "+" )( j, x ) );
23
gap> JuliaObjGAPRat( GetJuliaFunc( "-" )( x, j ) );
-17
gap> JuliaObjGAPRat( GetJuliaFunc( "-" )( j, x ) );
17
gap> JuliaObjGAPRat( GetJuliaFunc( "*" )( x, j ) );
60
gap> JuliaObjGAPRat( GetJuliaFunc( "*" )( j, x ) );
60
gap> JuliaObjGAPRat( GetJuliaFunc( "//" )( x, j ) );
3/20
gap> JuliaObjGAPRat( GetJuliaFunc( "//" )( j, x ) );
20/3
gap> JuliaObjGAPRat( GetJuliaFunc( "^" )( x, j ) );
3486784401
gap> # JuliaObjGAPRat( GetJuliaFunc( "^" )( j, x ) );  # too large ...
gap> JuliaObjGAPRat( GetJuliaFunc( "mod" )( x, j ) );
3
gap> JuliaObjGAPRat( GetJuliaFunc( "mod" )( j, x ) );
2

##  test arithmetic operations with GAPRats and Julia rationals
#T TODO!

##  test the Julia functions for GAPRats
gap> JuliaObjGAPRat( GetJuliaFunc( "gcd" )( x, y ) );
1

##
gap> STOP_TEST( "gaprat.tst", 1 );

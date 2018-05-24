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
gap> JuliaObjGAPRat( gaprat( 1, 2 ) );
1/2

##  test arithmetic operations with GAPRats
gap> zero:= Julia.Base.zero( x );;
gap> JuliaObjGAPRat( zero );
0
gap> JuliaObjGAPRat( Julia.Base.( "-" )( x ) );
-3
gap> JuliaObjGAPRat( Julia.Base.one( x ) );
1
gap> JuliaObjGAPRat( Julia.Base.inv( x ) );
1/3
gap> JuliaUnbox( Julia.Base.( "==" )( x, x ) );
true
gap> JuliaUnbox( Julia.Base.( "==" )( x, y ) );
false
gap> JuliaUnbox( Julia.Base.isless( x, y ) );
true
gap> JuliaUnbox( Julia.Base.isless( y, x ) );
false
gap> JuliaUnbox( Julia.Base.isless( x, x ) );
false
gap> JuliaObjGAPRat( Julia.Base.( "+" )( x, y ) );
7
gap> JuliaObjGAPRat( Julia.Base.( "-" )( x, y ) );
-1
gap> JuliaObjGAPRat( Julia.Base.( "*" )( x, y ) );
12
gap> JuliaObjGAPRat( Julia.Base.( "//" )( x, x ) );
1
gap> JuliaObjGAPRat( Julia.Base.( "^" )( x, y ) );
81
gap> JuliaObjGAPRat( Julia.Base.( "^" )( x, 2 ) );
9
gap> JuliaObjGAPRat( Julia.Base.( "mod" )( x, y ) );
3
gap> JuliaUnbox( Julia.Base.iszero( x ) );
false
gap> JuliaUnbox( Julia.Base.iszero( zero ) );
true
gap> JuliaUnbox( Julia.Base.( "==" )( x, x ) );
true
gap> JuliaUnbox( Julia.Base.( "==" )( x, y ) );
false
gap> JuliaUnbox( Julia.Base.isless( x, y ) );
true
gap> JuliaUnbox( Julia.Base.isless( y, x ) );
false
gap> JuliaUnbox( Julia.Base.isless( x, x ) );
false

##  test binary arithmetic operations with GAPRats and Julia integers
gap> j:= JuliaBox( 20 );;
gap> JuliaObjGAPRat( Julia.Base.( "+" )( x, j ) );
23
gap> JuliaObjGAPRat( Julia.Base.( "+" )( j, x ) );
23
gap> JuliaObjGAPRat( Julia.Base.( "-" )( x, j ) );
-17
gap> JuliaObjGAPRat( Julia.Base.( "-" )( j, x ) );
17
gap> JuliaObjGAPRat( Julia.Base.( "*" )( x, j ) );
60
gap> JuliaObjGAPRat( Julia.Base.( "*" )( j, x ) );
60
gap> JuliaObjGAPRat( Julia.Base.( "//" )( x, j ) );
3/20
gap> JuliaObjGAPRat( Julia.Base.( "//" )( j, x ) );
20/3
gap> JuliaObjGAPRat( Julia.Base.( "^" )( x, j ) );
3486784401
gap> # JuliaObjGAPRat( Julia.Base.( "^" )( j, x ) );  # too large ...
gap> JuliaObjGAPRat( Julia.Base.( "mod" )( x, j ) );
3
gap> JuliaObjGAPRat( Julia.Base.( "mod" )( j, x ) );
2

##  test arithmetic operations with GAPRats and Julia rationals
#T TODO!

##  test the Julia functions for GAPRats
gap> JuliaObjGAPRat( Julia.Base.gcd( x, y ) );
1

##
gap> STOP_TEST( "gaprat.tst", 1 );


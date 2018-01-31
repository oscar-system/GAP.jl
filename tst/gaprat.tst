
##
gap> START_TEST( "gaprat.tst" );

##
gap> x:= JuliaGAPRatInt( 3 );;
gap> y:= JuliaGAPRatInt( 4 );;
gap> JuliaObjGAPRat( x );
3

##  test arithmetic operations
gap> zero:= GetJuliaFunc( "zero" )( x );;
gap> JuliaObjGAPRat( zero );
0
gap> JuliaObjGAPRat( GetJuliaFunc( "-" )( x ) );
-3
gap> one:= GetJuliaFunc( "one" )( x );;
gap> JuliaObjGAPRat( one );
1
gap> JuliaObjGAPRat( GetJuliaFunc( "inv" )( one ) );
1
gap> JuliaUnbox( GetJuliaFunc( "==" )( x, x ) );
true
gap> JuliaUnbox( GetJuliaFunc( "==" )( x, y ) );
false
gap> JuliaUnbox( GetJuliaFunc( "isless" )( x, y ) );
true
gap> JuliaUnbox( GetJuliaFunc( "isless" )( y, x ) );
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

##
gap> STOP_TEST( "gaprat.tst", 1 );

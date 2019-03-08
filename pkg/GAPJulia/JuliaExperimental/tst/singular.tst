#############################################################################
##
#W  singular.tst       GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "singular.tst" );

##
gap> r:= PolynomialRing( Rationals, [ "x", "y" ] );;
gap> c:= ContextGAPSingular( r );
<context for pol. ring over Rationals, with 2 indeterminates>
gap> R:= c!.JuliaDomain;
Singular_PolynomialRing
gap> IsSingularPolynomialRing( Rationals );
false
gap> IsSingularPolynomialRing( R );
true
gap> indets:= IndeterminatesOfPolynomialRing( R ); 
[ <<Julia: x>>, <<Julia: y>> ]
gap> Print( indets, "\n" );
[ x, y ]
gap> List( indets, String );
[ "x", "y" ]
gap> Unbind( x );  Unbind( y ); 
gap> AssignGeneratorVariables( R ); 
#I  Assigned the global variables [ x, y ]
gap> IsSingularPolynomial( x );
true
gap> x;  y;
<<Julia: x>>
<<Julia: y>>
gap> Zero( x ); 
<<Julia: 0>>
gap> One( x ); 
<<Julia: 1>>
gap> Zero( R ); 
<<Julia: 0>>
gap> One( R ); 
<<Julia: 1>>
gap> Zero( x ) = 0; 
false
gap> x = y; 
false
gap> 2 * x = 2 * x; 
true
gap> x + y; 
<<Julia: x+y>>
gap> x + 1;
<<Julia: x+1>>
gap> 1 + x;
<<Julia: x+1>>
gap> -x;
<<Julia: -x>>
gap> x - y;
<<Julia: x-y>>
gap> x - 1;
<<Julia: x-1>>
gap> 1 - x;
<<Julia: -x+1>>
gap> x * y;
<<Julia: x*y>>
gap> x * 2;
<<Julia: 2*x>>
gap> 2 * x;
<<Julia: 2*x>>
gap> x / 2;
<<Julia: 1/2*x>>
gap> (x + y)^3;
<<Julia: x^3+3*x^2*y+3*x*y^2+y^3>>

##
gap> f:= ( x + y ) * ( x^2 * y + 2 * x );
<<Julia: x^3*y+x^2*y^2+2*x^2+2*x*y>>
gap> g:= ( x + y ) * ( x - y );
<<Julia: x^2-y^2>>
gap> IsSubset( R, [ f, g ] );                                         
true
gap> DefaultRing( f, g );
Singular_PolynomialRing
gap> Gcd( f, g );
<<Julia: x+y>>
gap> GcdOp( f, g );
<<Julia: x+y>>
gap> GcdOp( R, f, g );
<<Julia: x+y>>

##
gap> STOP_TEST( "singular.tst" );


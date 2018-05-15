#############################################################################
##
#W  numfield.tst       GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "numfield.tst" );

# Nemo polynomials
gap> R:= Nemo_PolynomialRing( Nemo_QQ, "x" );
Nemo_QQ[x]
gap> Nemo_Polynomial( R, [ 1, 0, 1 ] );
<<Julia: x^2+1>>
gap> Nemo_Polynomial( R, [ 1, 0, 1/2 ] );
<<Julia: 1//2*x^2+1>>

# matrix over Z
gap> mat:= NemoMatrix( Nemo_ZZ, IdentityMat( 2 ) );
<<Julia: [1 0]
[0 1]>>

# matrix over Q
gap> mat:= NemoMatrix( Nemo_QQ, IdentityMat( 2 ) );
<<Julia: [1 0]
[0 1]>>

# matrix over ext. field
gap> x:= X( Rationals );;
gap> f:= AlgebraicExtension( Rationals, x^2+1 );;
gap> ff:= Nemo_Field( f );;
gap> z:= Zero( f );;  o:= One( f );;  a:= RootOfDefiningPolynomial( f );;
gap> mat:= [ [ o, a/2 ], [ z, o ] ];
[ [ !1, 1/2*a ], [ !0, !1 ] ]
gap> nmat:= NemoMatrix( ff, mat );
<<Julia: [1 1//2*a]
[0 1]>>
gap> GAPMatrix( f, nmat );
[ [ !1, 1/2*a ], [ !0, !1 ] ]
gap> no:= One( ff );
<<Julia: 1>>
gap> no + 1;
<<Julia: 2>>
gap> mat^2;
[ [ !1, a ], [ !0, !1 ] ]
gap> nmat^2;
<<Julia: [1 a]
[0 1]>>

##
gap> STOP_TEST( "numfield.tst", 1 );


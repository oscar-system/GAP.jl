#############################################################################
##
#W  numfield.tst       GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "numfield.tst" );

# matrix over ext. field
gap> x:= X( Rationals, "x" );;
gap> f:= AlgebraicExtension( Rationals, x^2+1 );;
gap> c:= ContextGAPNemo( f );
<context for alg. ext. field over Rationals, w.r.t. polynomial x^2+1>
gap> z:= Zero( f );;  o:= One( f );;  a:= RootOfDefiningPolynomial( f );;
gap> v:= [ z, o ];
[ !0, !1 ]
gap> nv:= GAPToNemo( c, v );
<<Julia: [0 1]>>
gap> mat:= [ [ o, a/2 ], [ z, o ] ];
[ [ !1, 1/2*a ], [ !0, !1 ] ]
gap> nmat:= GAPToNemo( c, mat );
<<Julia: [1 1//2*a]
[0 1]>>

#gap> JuliaTypeInfo( JuliaPointer( nmat ) );
#"AbstractAlgebra.Generic.Mat{Nemo.nf_elem}"
gap> PrintObj( nmat );  Print( "\n" );
[1 1//2*a]
[0 1]
gap> IsZero( nmat );
false
gap> IsZero( 0 * nmat );
true
gap> Zero( nmat );
<<Julia: [0 0]
[0 0]>>
gap> ZeroMatrix( 3, 4, nmat );
<<Julia: [0 0 0 0]
[0 0 0 0]
[0 0 0 0]>>
gap> NewZeroMatrix( IsNemoMatrixObj, Rationals, 2, 3 );
<<Julia: [0 0 0]
[0 0 0]>>
gap> IsOne( nmat );
false
gap> IsOne( nmat^0 );
true
gap> One( nmat );
<<Julia: [1 0]
[0 1]>>
gap> IdentityMatrix( 3, nmat );
<<Julia: [1 0 0]
[0 1 0]
[0 0 1]>>
gap> NewIdentityMatrix( IsNemoMatrixObj, Rationals, 2 );
<<Julia: [1 0]
[0 1]>>
gap> InverseMutable( nmat );
<<Julia: [1 -1//2*a]
[0 1]>>
gap> RankMat( nmat );
2
gap> - nmat;
<<Julia: [-1 -1//2*a]
[0 -1]>>
gap> nmat + nmat;
<<Julia: [2 a]
[0 2]>>
gap> nmat - nmat;
<<Julia: [0 0]
[0 0]>>
gap> nmat * nmat;
<<Julia: [1 a]
[0 1]>>
gap> sum:= nmat + 1;           # DO WE REALLY WANT THIS RESULT???
<<Julia: [2 1//2*a]
[0 2]>>
gap> NumberRows( sum );
2
gap> NumberColumns( sum );
2
gap> nmat[1,1];
<<Julia: 1>>
gap> Characteristic( nmat );
0
gap> tr:= TraceMat( nmat );
<<Julia: 2>>
gap> JuliaTypeInfo( JuliaPointer( tr ) );
"Nemo.nf_elem"
gap> det:= DeterminantMat( nmat );
<<Julia: 1>>
gap> JuliaTypeInfo( JuliaPointer( det ) );
"Nemo.nf_elem"
gap> NemoToGAP( c, nmat );
[ [ !1, 1/2*a ], [ !0, !1 ] ]
gap> no:= GAPToNemo( c, One( f ) );
<<Julia: 1>>
gap> no + 1;
<<Julia: 2>>
gap> mat^2;
[ [ !1, a ], [ !0, !1 ] ]
gap> nmat^2;
<<Julia: [1 a]
[0 1]>>
gap> nmat^-1;
<<Julia: [1 -1//2*a]
[0 1]>>
gap> TransposedMat( nmat );
<<Julia: [1 0]
[1//2*a 1]>>
gap> KroneckerProduct( nmat, nmat );
<<Julia: [1 1//2*a 1//2*a -1//4]
[0 1 0 1//2*a]
[0 0 1 1//2*a]
[0 0 0 1]>>
gap> R:= PolynomialRing( Rationals );;
gap> x:= Indeterminate( Rationals );;
gap> pol:= x^4 + 2*x^3 + 4*x^2 + 1;;
gap> c:= ContextGAPNemo( R );
<context for pol. ring over Rationals, with 1 indeterminates>
gap> npol:= GAPToNemo( c, pol );;
gap> CompanionMatrix( npol, nmat );
<<Julia: [0 1 0 0 0]
[0 0 1 0 0]
[0 0 0 1 0]
[0 0 0 0 1]
[-1 0 -4 -2 -1]>>

# gap> nconcat:= Unfold( nmat, nv );
# <<Julia: [1 1//2*a 0 1]>>
# gap> Fold( nconcat, 1, nmat );
# <<Julia: [1]
# [1//2*a]
# [0]
# [1]>>
# gap> nmat = Fold( nconcat, 2, nmat );
# true
#
## multivariate Flint polynomial rings
gap> R:= PolynomialRing( Rationals, [ "x", "y" ] );;
gap> indets:= IndeterminatesOfPolynomialRing( R );;
gap> x:= indets[1];;  y:= indets[2];;
gap> f:= x * y + 1;
x*y+1
gap> c:= ContextGAPNemo( R );
<context for pol. ring over Rationals, with 2 indeterminates>
gap> npol:= GAPToNemo( c, f );
<<Julia: x*y + 1>>
gap> npol^2;
<<Julia: x^2*y^2 + 2*x*y + 1>>
gap> GAPDescriptionOfNemoPolynomial( c, npol );
[ [ 1, 1, 2, 1 ], 1, [  ], 1 ]
gap> mat:= [ [ One( R ), f ], [ Zero( R ), One( R ) ] ];
[ [ 1, x*y+1 ], [ 0, 1 ] ]
gap> nmat:= GAPToNemo( c, mat );
<<Julia: [1 x*y + 1]
[0 1]>>
gap> nmat^2;
<<Julia: [1 2*x*y + 2]
[0 1]>>
gap> NemoToGAP( c, nmat );
[ [ 1, x*y+1 ], [ 0, 1 ] ]

##
gap> STOP_TEST( "numfield.tst" );


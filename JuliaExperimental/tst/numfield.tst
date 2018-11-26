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
gap> mat:= [ [ o, a/2 ], [ z, o ] ];
[ [ !1, 1/2*a ], [ !0, !1 ] ]
gap> nmat:= GAPToNemo( c, mat );
<<Julia: [1 1//2*a]
[0 1]>>
gap> JuliaTypeInfo( JuliaPointer( nmat ) );
"AbstractAlgebra.Generic.Mat{Nemo.nf_elem}"
gap> PrintObj( nmat );  Print( "\n" );
[1 1//2*a]
[0 1]
gap> nmat + 1;           # DO WE REALLY WANT THIS RESULT???
<<Julia: [2 1//2*a]
[0 2]>>
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

##
gap> STOP_TEST( "numfield.tst", 1 );


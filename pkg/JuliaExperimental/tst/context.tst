#############################################################################
##
#W  context.tst        GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "context.tst" );

##  call NewContextGAPNemo
gap> NewContextGAPJulia( "", [] );
Error, <arec> must be a record
gap> NewContextGAPJulia( "Nemo", rec() );
Error, the component 'Name' must be bound in <arec>
gap> NewContextGAPJulia( "Nemo", rec(
>        Name:= "test",
>        GAPDomain:= Domain( [ 1 ] ),
>        JuliaDomain:= ObjectifyWithAttributes( rec(),
>          TypeObj( ~.GAPDomain ),
>          JuliaPointer, GAPToJulia( [ 1 ] ) ),
>        ElementType:= TypeObj( 1 ),
>        ElementGAPToJulia:= ( x -> GAPToJulia( x ) ),
>        ElementJuliaToGAP:= ( x -> JuliaToGAP( x ) ),
>        ElementWrapped:= ( x -> x ),
>        VectorType:= TypeObj( [ 1 ] ),
>        VectorGAPToJulia:= ( x -> GAPToJulia( x ) ),
>        VectorJuliaToGAP:= ( x -> JuliaToGAP( x ) ),
>        VectorWrapped:= ( x -> x ),
>        MatrixType:= TypeObj( [ [ 1 ] ] ),
>        MatrixGAPToJulia:= ( x -> GAPToJulia( x ) ),
>        MatrixJuliaToGAP:= ( x -> JuliaToGAP( x ) ),
>        MatrixWrapped:= ( x -> x ),
>   ) );
test

# Nemo conversion: Integers
gap> R:= Integers;;
gap> c:= ContextGAPNemo( R );
<context for Integers>
gap> x:= GAPToNemo( c, 1 );
<<Julia: 1>>
gap> JuliaTypeInfo( JuliaPointer( x ) );
"Nemo.fmpz"
gap> NemoToGAP( c, x );
1
gap> vec:= GAPToNemo( c, [ 1, 2 ] );
<<Julia: [1 2]>>
gap> JuliaTypeInfo( JuliaPointer( vec ) );
"Nemo.fmpz_mat"
gap> NemoToGAP( c, vec );
[ 1, 2 ]
gap> mat:= GAPToNemo( c, [ [ 1, 2 ], [ 3, 4 ] ] );
<<Julia: [1 2]
[3 4]>>
gap> JuliaTypeInfo( JuliaPointer( mat ) );
"Nemo.fmpz_mat"
gap> NemoToGAP( c, mat );
[ [ 1, 2 ], [ 3, 4 ] ]

# Nemo conversion: Integers mod n
gap> R:= Integers mod 6;;
gap> c:= ContextGAPNemo( R );
<context for Integers mod 6>
gap> x:= GAPToNemo( c, One( R ) );
<<Julia: 1>>
gap> x:= GAPToNemo( c, 1 );
<<Julia: 1>>
gap> JuliaTypeInfo( JuliaPointer( x ) );
"Nemo.nmod"
gap> NemoToGAP( c, x );
ZmodnZObj( 1, 6 )
gap> vec:= GAPToNemo( c, [ 1, 2 ] * One( R ) );
<<Julia: [1 2]>>
gap> vec:= GAPToNemo( c, [ 1, 2 ] );
<<Julia: [1 2]>>
gap> JuliaTypeInfo( JuliaPointer( vec ) );
"Nemo.nmod_mat"
gap> NemoToGAP( c, vec );
[ ZmodnZObj( 1, 6 ), ZmodnZObj( 2, 6 ) ]
gap> mat:= GAPToNemo( c, [ [ 1, 2 ], [ 3, 4 ] ] * One( R ) );
<<Julia: [1 2]
[3 4]>>
gap> mat:= GAPToNemo( c, [ [ 1, 2 ], [ 3, 4 ] ] );
<<Julia: [1 2]
[3 4]>>
gap> JuliaTypeInfo( JuliaPointer( mat ) );
"Nemo.nmod_mat"
gap> NemoToGAP( c, mat );
[ [ ZmodnZObj( 1, 6 ), ZmodnZObj( 2, 6 ) ], 
  [ ZmodnZObj( 3, 6 ), ZmodnZObj( 4, 6 ) ] ]

# Nemo conversion: Rationals
gap> R:= Rationals;;
gap> c:= ContextGAPNemo( R );
<context for Rationals>
gap> x:= GAPToNemo( c, 1/2 );
<<Julia: 1//2>>
gap> JuliaTypeInfo( JuliaPointer( x ) );
"Nemo.fmpq"
gap> NemoToGAP( c, x );
1/2
gap> vec:= GAPToNemo( c, [ 1/2, 2 ] );
<<Julia: [1//2 2]>>
gap> JuliaTypeInfo( JuliaPointer( vec ) );
"Nemo.fmpq_mat"
gap> NemoToGAP( c, vec );
[ 1/2, 2 ]
gap> mat:= GAPToNemo( c, [ [ 1/2, 2 ], [ 3, 4/3 ] ] );
<<Julia: [1//2 2]
[3 4//3]>>
gap> JuliaTypeInfo( JuliaPointer( mat ) );
"Nemo.fmpq_mat"
gap> NemoToGAP( c, mat );
[ [ 1/2, 2 ], [ 3, 4/3 ] ]

# Nemo conversion: univariate polynomial ring over Rationals
gap> R:= PolynomialRing( Rationals, 1 );
Rationals[x_1]
gap> c:= ContextGAPNemo( R );
<context for pol. ring over Rationals, with 1 indeterminates>
gap> indets:= IndeterminatesOfPolynomialRing( R );
[ x_1 ]
gap> x:= indets[1];;
gap> pol:= GAPToNemo( c, x^3 + x + 1 );
<<Julia: x_1^3+x_1+1>>
gap> JuliaTypeInfo( JuliaPointer( pol ) );
"Nemo.fmpq_poly"
gap> NemoToGAP( c, pol );
x_1^3+x_1+1
gap> vec:= GAPToNemo( c, [ x+1, x-1 ] );
<<Julia: [x_1+1 x_1-1]>>

#gap> JuliaTypeInfo( JuliaPointer( vec ) );
#"AbstractAlgebra.Generic.Mat{Nemo.fmpq_poly}"
gap> NemoToGAP( c, vec );
[ x_1+1, x_1-1 ]
gap> mat:= GAPToNemo( c, [ [ x, x+1 ], [ 2*x, x^2+1] ] );
<<Julia: [x_1 x_1+1]
[2*x_1 x_1^2+1]>>

#gap> JuliaTypeInfo( JuliaPointer( mat ) );
#"AbstractAlgebra.Generic.Mat{Nemo.fmpq_poly}"
gap> NemoToGAP( c, mat );
[ [ x_1, x_1+1 ], [ 2*x_1, x_1^2+1 ] ]

# Nemo conversion: number fields
gap> x:= X( Rationals );
x_1
gap> f:= AlgebraicExtension( Rationals, x^2+1 );
<algebraic extension over the Rationals of degree 2>
gap> c:= ContextGAPNemo( f );
<context for alg. ext. field over Rationals, w.r.t. polynomial x_1^2+1>
gap> elm:= GAPToNemo( c, One( f ) );
<<Julia: 1>>
gap> JuliaTypeInfo( JuliaPointer( elm ) );
"Nemo.nf_elem"
gap> NemoToGAP( c, elm );
!1
gap> a:= RootOfDefiningPolynomial( f );
a
gap> elm:= GAPToNemo( c, a );
<<Julia: a>>
gap> JuliaTypeInfo( JuliaPointer( elm ) );
"Nemo.nf_elem"
gap> NemoToGAP( c, elm );
a
gap> vec:= GAPToNemo( c, [ a+1, a-1 ] );
<<Julia: [a+1 a-1]>>

#gap> JuliaTypeInfo( JuliaPointer( vec ) );
#"AbstractAlgebra.Generic.Mat{Nemo.nf_elem}"
gap> NemoToGAP( c, vec );
[ a+1, a-1 ]
gap> mat:= GAPToNemo( c, [ [ a, a+1 ], [ 2*a, a^2+1] ] );
<<Julia: [a a+1]
[2*a 0]>>

#gap> JuliaTypeInfo( JuliaPointer( mat ) );
#"AbstractAlgebra.Generic.Mat{Nemo.nf_elem}"
gap> NemoToGAP( c, mat );
[ [ a, a+1 ], [ 2*a, !0 ] ]

##
gap> STOP_TEST( "context.tst" );


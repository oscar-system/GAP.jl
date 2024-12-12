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
gap> x:= GAPToNemo( c, 1 );;
gap> Julia.typeof( JuliaPointer( x ) );
<Julia: Nemo.ZZRingElem>
gap> NemoToGAP( c, x ) = 1;
true
gap> gap_vec:= [ 1, 2 ];;
gap> vec:= GAPToNemo( c, gap_vec );;
gap> Julia.typeof( JuliaPointer( vec ) );
<Julia: Nemo.ZZMatrix>
gap> NemoToGAP( c, vec ) = gap_vec;
true
gap> gap_mat:= [ [ 1, 2 ], [ 3, 4 ] ];;
gap> mat:= GAPToNemo( c, gap_mat );;
gap> Julia.typeof( JuliaPointer( mat ) );
<Julia: Nemo.ZZMatrix>
gap> NemoToGAP( c, mat ) = gap_mat;
true

# Nemo conversion: Integers mod n
gap> R:= Integers mod 6;;
gap> c:= ContextGAPNemo( R );
<context for Integers mod 6>
gap> gap_x:= One( R );;
gap> x:= GAPToNemo( c, gap_x );;
gap> x = GAPToNemo( c, 1 );
true
gap> Julia.typeof( JuliaPointer( x ) );
<Julia: Nemo.zzModRingElem>
gap> NemoToGAP( c, x ) = gap_x;
true
gap> gap_vec:= [ 1, 2 ] * One( R );;
gap> vec:= GAPToNemo( c, gap_vec );;
gap> vec = GAPToNemo( c, [ 1, 2 ] );
true
gap> Julia.typeof( JuliaPointer( vec ) );
<Julia: Nemo.zzModMatrix>
gap> NemoToGAP( c, vec ) = gap_vec;
true
gap> gap_mat:= [ [ 1, 2 ], [ 3, 4 ] ] * One( R );;
gap> mat:= GAPToNemo( c, gap_mat );;
gap> mat = GAPToNemo( c, [ [ 1, 2 ], [ 3, 4 ] ] );
true
gap> Julia.typeof( JuliaPointer( mat ) );
<Julia: Nemo.zzModMatrix>
gap> NemoToGAP( c, mat ) = gap_mat;
true

# Nemo conversion: Rationals
gap> R:= Rationals;;
gap> c:= ContextGAPNemo( R );
<context for Rationals>
gap> gap_x:= 1/2;;
gap> x:= GAPToNemo( c, gap_x );;
gap> Julia.typeof( JuliaPointer( x ) );
<Julia: Nemo.QQFieldElem>
gap> NemoToGAP( c, x ) = gap_x;
true
gap> gap_vec:= [ 1/2, 2 ];;
gap> vec:= GAPToNemo( c, gap_vec );;
gap> Julia.typeof( JuliaPointer( vec ) );
<Julia: Nemo.QQMatrix>
gap> NemoToGAP( c, vec ) = gap_vec;
true
gap> gap_mat:= [ [ 1/2, 2 ], [ 3, 4/3 ] ];;
gap> mat:= GAPToNemo( c, gap_mat );;
gap> Julia.typeof( JuliaPointer( mat ) );
<Julia: Nemo.QQMatrix>
gap> NemoToGAP( c, mat ) = gap_mat;
true

# Nemo conversion: univariate polynomial ring over Rationals
gap> R:= PolynomialRing( Rationals, 1 );
Rationals[x_1]
gap> c:= ContextGAPNemo( R );
<context for pol. ring over Rationals, with 1 indeterminates>
gap> indets:= IndeterminatesOfPolynomialRing( R );;
gap> x:= indets[1];;
gap> gap_pol:= x^3 + x + 1;;
gap> pol:= GAPToNemo( c, gap_pol );;
gap> Julia.typeof( JuliaPointer( pol ) );
<Julia: Nemo.QQPolyRingElem>
gap> NemoToGAP( c, pol ) = gap_pol;
true
gap> gap_vec:= [ x+1, x-1 ];;
gap> vec:= GAPToNemo( c, gap_vec );;

#gap> Julia.typeof( JuliaPointer( vec ) );
#<Julia: AbstractAlgebra.Generic.MatSpaceElem{QQPolyRingElem}>
gap> NemoToGAP( c, vec ) = gap_vec;
true
gap> gap_mat:= [ [ x, x+1 ], [ 2*x, x^2+1 ] ];;
gap> mat:= GAPToNemo( c, gap_mat );;

#gap> Julia.typeof( JuliaPointer( mat ) );
#<Julia: AbstractAlgebra.Generic.MatSpaceElem{QQPolyRingElem}>
gap> NemoToGAP( c, mat ) = gap_mat;
true

# Nemo conversion: number fields
gap> x:= X( Rationals );;
gap> f:= AlgebraicExtension( Rationals, x^2+1 );;
gap> c:= ContextGAPNemo( f );
<context for alg. ext. field over Rationals, w.r.t. polynomial x_1^2+1>
gap> gap_elm:= One( f );;
gap> elm:= GAPToNemo( c, gap_elm );;
gap> Julia.typeof( JuliaPointer( elm ) );
<Julia: Nemo.AbsSimpleNumFieldElem>
gap> NemoToGAP( c, elm ) = gap_elm;
true
gap> a:= RootOfDefiningPolynomial( f );;
gap> elm:= GAPToNemo( c, a );;
gap> Julia.typeof( JuliaPointer( elm ) );
<Julia: Nemo.AbsSimpleNumFieldElem>
gap> NemoToGAP( c, elm ) = a;
true
gap> gap_vec:= [ a+1, a-1 ];;
gap> vec:= GAPToNemo( c, gap_vec );;

#gap> Julia.typeof( JuliaPointer( vec ) );
#<Julia: AbstractAlgebra.Generic.MatSpaceElem{AbsSimpleNumFieldElem}>
gap> NemoToGAP( c, vec ) = gap_vec;
true
gap> gap_mat:= [ [ a, a+1 ], [ 2*a, a^2+1 ] ];;
gap> mat:= GAPToNemo( c, gap_mat );;

#gap> Julia.typeof( JuliaPointer( mat ) );
#<Julia: AbstractAlgebra.Generic.MatSpaceElem{AbsSimpleNumFieldElem}>
gap> NemoToGAP( c, mat ) = gap_mat;
true

##
gap> STOP_TEST( "context.tst" );

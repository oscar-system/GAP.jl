#############################################################################
##
#W  znodnz.tst         GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "zmodnz.tst" );

# 
gap> R:= Integers mod 9;;
gap> c:= ContextGAPNemo( R );
<context for Integers mod 9>
gap> mat:= [[1,2],[3,4]];
[ [ 1, 2 ], [ 3, 4 ] ]
gap> m:= GAPToNemo( c, mat );
<<Julia: [1 2]
[3 4]>>
gap> m^2;
<<Julia: [7 1]
[6 4]>>
gap> NumberRows( m );
2
gap> inv:= m^-1;
<<Julia: [7 1]
[6 4]>>
gap> inv * m;
<<Julia: [1 0]
[0 1]>>
gap> Order( m );
3
gap> g:= Group( m );
Group([ <<Julia: [1 2]
    [3 4]>> ])
gap> Size( g );
3

#
gap> r:= Integers mod 6;;
gap> c:= ContextGAPNemo( r );;
gap> gens:= List( GeneratorsOfGroup( GL( 2, r ) ), m -> GAPToNemo( c, m ) );;
gap> g:= Group( gens );
Group([ <<Julia: [0 1]
    [1 0]>>, <<Julia: [1 1]
    [0 1]>>, <<Julia: [5 0]
    [0 1]>> ])
gap> One( g );
<<Julia: [1 0]
[0 1]>>
gap> Size( g );
288

# If the modulus is large then the entries in Julia nmod matrices are fmpz;
# test the conversions in this case!

##
gap> STOP_TEST( "zmodnz.tst", 1 );


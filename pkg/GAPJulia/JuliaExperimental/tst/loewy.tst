#############################################################################
##
#W  loewy.tst          GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "loewy.tst" );

##  Test the general functionality of Singer algebras (not Julia related).
gap> a:= SingerAlgebra( 5, 2, 4 );;  ParametersOfSingerAlgebra( a );
[ 5, 2, 4 ]
gap> a:= SingerAlgebra( 5, 2, 4 );;  CanonicalBasis( a );
CanonicalBasis( A(5,2,4) )
gap> a:= SingerAlgebra( 5, 2, 4 );;  Zero( Random( a ) );
0*b0
gap> a:= SingerAlgebra( 5, 2, 4 );;  Representative( a );
b0
gap> a:= SingerAlgebra( 5, 2, 4 );;  One( a );
b0
gap> a:= SingerAlgebra( 5, 2, 4 );;  Zero( a );
0*b0
gap> a:= SingerAlgebra( 5, 2, 4 );;  GeneratorsOfAlgebra( a );
[ b0, b1, b2, b3, b4, b5, b6 ]
gap> a:= SingerAlgebra( 5, 2, 4 );;  GeneratorsOfAlgebraWithOne( a );
[ b0, b1, b2, b3, b4, b5, b6 ]
gap> a:= SingerAlgebra( 5, 2, 4 );;  Centre( a );
A(5,2,4)

##  Auxiliary function:
##  Test only one generator from each cyclic group of prime residues.
gap> SmallestPrimeResidueGenerators:= e -> Filtered( PrimeResidues( e ),
>        q -> ForAll( PrimeResidues( OrderMod( q, e ) ), 
>                     i -> PowerModInt( q, i, e ) >= q ) );;

##  Test the minimal degree computation (in Julia).
gap> for e in [ 2 .. 15 ] do
>      for q in SmallestPrimeResidueGenerators( e ) do
>        if q = 1 then
>          q:= e+1;
>        fi;
>        n:= OrderMod( q, e );
>        a:= SingerAlgebra( q, n, e );
>        m:= MinimalDegreeOfSingerAlgebra( a );
>        if m <> MinimalDegreeOfSingerAlgebra( q, e ) then
>          Error( "bad result for ", [ q, e ], "\n"  );
>        fi;
>        Print( [ q, e, m ], "\n" );
>      od;
>    od;
[ 3, 2, 2 ]
[ 4, 3, 3 ]
[ 2, 3, 2 ]
[ 5, 4, 4 ]
[ 3, 4, 2 ]
[ 6, 5, 5 ]
[ 2, 5, 2 ]
[ 4, 5, 2 ]
[ 7, 6, 6 ]
[ 5, 6, 2 ]
[ 8, 7, 7 ]
[ 2, 7, 3 ]
[ 3, 7, 2 ]
[ 6, 7, 2 ]
[ 9, 8, 8 ]
[ 3, 8, 4 ]
[ 5, 8, 4 ]
[ 7, 8, 2 ]
[ 10, 9, 9 ]
[ 2, 9, 2 ]
[ 4, 9, 3 ]
[ 8, 9, 2 ]
[ 11, 10, 10 ]
[ 3, 10, 2 ]
[ 9, 10, 2 ]
[ 12, 11, 11 ]
[ 2, 11, 2 ]
[ 3, 11, 3 ]
[ 10, 11, 2 ]
[ 13, 12, 12 ]
[ 5, 12, 4 ]
[ 7, 12, 6 ]
[ 11, 12, 2 ]
[ 14, 13, 13 ]
[ 2, 13, 2 ]
[ 3, 13, 3 ]
[ 4, 13, 2 ]
[ 5, 13, 2 ]
[ 12, 13, 2 ]
[ 15, 14, 14 ]
[ 3, 14, 2 ]
[ 9, 14, 4 ]
[ 13, 14, 2 ]
[ 16, 15, 15 ]
[ 2, 15, 4 ]
[ 4, 15, 6 ]
[ 7, 15, 3 ]
[ 11, 15, 5 ]
[ 14, 15, 2 ]

##  Test the Loewy length computations in Julia.
gap> for e in [ 2 .. 15 ] do
>      for q in SmallestPrimeResidueGenerators( e ) do
>        if q = 1 then
>          q:= e+1;
>        fi;
>        n:= OrderMod( q, e );
>        a:= SingerAlgebra( q, n, e );
>        if Dimension( a ) < 10000 then
>          l:= LoewyLength( a );
>          if l <> LoewyLength( q, n, e ) then
>            Error( "bad result for ", [ q, n, e ], "\n"  );
>          fi;
>          Print( [ q, e, l ], "\n" );
>        fi;
>      od;
>    od;
[ 3, 2, 2 ]
[ 4, 3, 2 ]
[ 2, 3, 2 ]
[ 5, 4, 2 ]
[ 3, 4, 3 ]
[ 6, 5, 2 ]
[ 2, 5, 3 ]
[ 4, 5, 4 ]
[ 7, 6, 2 ]
[ 5, 6, 5 ]
[ 8, 7, 2 ]
[ 2, 7, 2 ]
[ 3, 7, 7 ]
[ 6, 7, 6 ]
[ 9, 8, 2 ]
[ 3, 8, 2 ]
[ 5, 8, 3 ]
[ 7, 8, 7 ]
[ 10, 9, 2 ]
[ 2, 9, 4 ]
[ 4, 9, 4 ]
[ 8, 9, 8 ]
[ 11, 10, 2 ]
[ 3, 10, 5 ]
[ 9, 10, 9 ]
[ 12, 11, 2 ]
[ 2, 11, 6 ]
[ 3, 11, 4 ]
[ 10, 11, 10 ]
[ 13, 12, 2 ]
[ 5, 12, 3 ]
[ 7, 12, 3 ]
[ 11, 12, 11 ]
[ 14, 13, 2 ]
[ 2, 13, 7 ]
[ 3, 13, 3 ]
[ 4, 13, 10 ]
[ 5, 13, 9 ]
[ 12, 13, 12 ]
[ 15, 14, 2 ]
[ 3, 14, 7 ]
[ 9, 14, 7 ]
[ 13, 14, 13 ]
[ 16, 15, 2 ]
[ 2, 15, 2 ]
[ 4, 15, 2 ]
[ 7, 15, 9 ]
[ 11, 15, 5 ]
[ 14, 15, 14 ]

##  Test 'DimensionsLoewyFactors'.
gap> for e in [ 2 .. 15 ] do
>      for q in SmallestPrimeResidueGenerators( e ) do
>        if q = 1 then
>          q:= e+1;
>        fi;
>        n:= OrderMod( q, e );
>        a:= SingerAlgebra( q, n, e );
>        if Dimension( a ) < 10000 then
>          v:= DimensionsLoewyFactors( a );
>          Print( [ q, e, v ], "\n" );
>        fi;
>      od;
>    od;
[ 3, 2, [ 1, 1 ] ]
[ 4, 3, [ 1, 1 ] ]
[ 2, 3, [ 1, 1 ] ]
[ 5, 4, [ 1, 1 ] ]
[ 3, 4, [ 1, 1, 1 ] ]
[ 6, 5, [ 1, 1 ] ]
[ 2, 5, [ 1, 2, 1 ] ]
[ 4, 5, [ 1, 1, 1, 1 ] ]
[ 7, 6, [ 1, 1 ] ]
[ 5, 6, [ 1, 1, 1, 1, 1 ] ]
[ 8, 7, [ 1, 1 ] ]
[ 2, 7, [ 1, 1 ] ]
[ 3, 7, [ 1, 17, 38, 31, 14, 3, 1 ] ]
[ 6, 7, [ 1, 1, 1, 1, 1, 1 ] ]
[ 9, 8, [ 1, 1 ] ]
[ 3, 8, [ 1, 1 ] ]
[ 5, 8, [ 1, 2, 1 ] ]
[ 7, 8, [ 1, 1, 1, 1, 1, 1, 1 ] ]
[ 10, 9, [ 1, 1 ] ]
[ 2, 9, [ 1, 3, 3, 1 ] ]
[ 4, 9, [ 1, 3, 3, 1 ] ]
[ 8, 9, [ 1, 1, 1, 1, 1, 1, 1, 1 ] ]
[ 11, 10, [ 1, 1 ] ]
[ 3, 10, [ 1, 2, 3, 2, 1 ] ]
[ 9, 10, [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ]
[ 12, 11, [ 1, 1 ] ]
[ 2, 11, [ 1, 27, 40, 20, 5, 1 ] ]
[ 3, 11, [ 1, 11, 10, 1 ] ]
[ 10, 11, [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ]
[ 13, 12, [ 1, 1 ] ]
[ 5, 12, [ 1, 1, 1 ] ]
[ 7, 12, [ 1, 3, 1 ] ]
[ 11, 12, [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ]
[ 14, 13, [ 1, 1 ] ]
[ 2, 13, [ 1, 58, 127, 92, 31, 6, 1 ] ]
[ 3, 13, [ 1, 1, 1 ] ]
[ 4, 13, [ 1, 23, 56, 84, 74, 44, 22, 8, 3, 1 ] ]
[ 5, 13, [ 1, 6, 11, 12, 9, 4, 3, 2, 1 ] ]
[ 12, 13, [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ]
[ 15, 14, [ 1, 1 ] ]
[ 3, 14, [ 1, 11, 18, 13, 6, 3, 1 ] ]
[ 9, 14, [ 1, 7, 15, 16, 10, 3, 1 ] ]
[ 13, 14, [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ]
[ 16, 15, [ 1, 1 ] ]
[ 2, 15, [ 1, 1 ] ]
[ 4, 15, [ 1, 1 ] ]
[ 7, 15, [ 1, 10, 28, 38, 39, 24, 16, 4, 1 ] ]
[ 11, 15, [ 1, 2, 3, 2, 1 ] ]
[ 14, 15, [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] ]

##  Test 'LoewyStructureInfo'.
gap> for e in [ 2 .. 30 ] do
>      for q in SmallestPrimeResidueGenerators( e ) do
>        if q = 1 then
>          q:= e+1;
>        fi;
>        n:= OrderMod( q, e );
>        a:= SingerAlgebra( q, n, e );
>        if Dimension( a ) < 10000 then
>          LoewyStructureInfo( a );
>        fi;
>      od;
>    od;

##  Test large e.
gap> q:= 17;;  n:= 19;;  e:= ( q^n - 1 ) / 2;
119536217842575662423576
gap> IsSmallIntRep( e );
false
gap> a:= SingerAlgebra( q, n, e );;
gap> Dimension( a );
3
gap> data:= LoewyStructureInfo( a );;
gap> keys:= Julia.Base.keys( data );;
gap> keys:= Julia.Base.collect( keys );;
gap> Set( JuliaToGAP( IsList, keys, true ) );
[ "chain", "inputs", "layers", "ll", "m", "monomials" ]

##  Test some error messages.
gap> SingerAlgebra( 2, 2, 0 );
Error, <q>, <n>, <e> must be positive integers
gap> SingerAlgebra( 1, 2, 3 );
Error, <q> must be an integer > 1
gap> SingerAlgebra( 7, 2, 5 );
Error, <e> must divide <q>^<n> - 1
gap> MinimalDegreeOfSingerAlgebra( 1, 2 );
Error, <q> must be an integer > 1
gap> LoewyLength( 1, 2, 3 );
Error, <q> must be an integer > 1

##  Test the Julia part.
gap> Julia.LoewyStructure.test_this_module();
true

##
gap> STOP_TEST( "loewy.tst" );


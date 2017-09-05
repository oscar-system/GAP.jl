
# tests for the rudimentary permutations

include( "julia/gapperm.jl" );

# using GAPPermutations

IdentityPerm

imgsarray = [ 1, 2, 3 ]
ccc = convert( Array{UInt16,1}, imgsarray )

Permutation2( 3, ccc )

p1 = Permutation( ccc )

p1 = Permutation( [ 1, 2, 3 ] )
one = OnePerm( p1 )

EqPerm22( p1, one )
EqPerm22( one, p1 )
LtPerm22( p1, one )
LtPerm22( one, p1 )

p1 = Permutation( [ 2, 1, 3 ] )
p2 = Permutation( [ 1, 3, 2 ] )
EqPerm22( p1, p2 )
EqPerm22( p2, p1 )
LtPerm22( p1, p2 )
LtPerm22( p2, p1 )

p11 = Permutation( [ 2, 1 ] )
EqPerm22( p11, p1 )
EqPerm22( p1, p11 )
LtPerm22( p1, p11 )
LtPerm22( p11, p1 )

show( STDOUT, p1 )

ProdPerm22( p1, one )
ProdPerm22( one, p1 )
prod = ProdPerm22( p1, p2 )
ProdPerm22( prod, prod )
ProdPerm22( one, one )
# p1 * one
# one * p1
# p1 * p2
# one * one

OrderPerm( prod )
OrderPerm( p1 )
OrderPerm( p2 )
OrderPerm( p11 )
OrderPerm( Permutation( [ 2, 1, 4, 5, 3 ] ) )

LargestMovedPointPerm( prod )
LargestMovedPointPerm( one )
LargestMovedPointPerm( p1 )
LargestMovedPointPerm( p11 )
LargestMovedPointPerm( p2 )

InvPerm( p1 )
InvPerm( p11 )
InvPerm( p2 )
InvPerm( prod )

PowPerm2Int( p1, -4711 )
PowPerm2Int( p1, -9 )
PowPerm2Int( p1, -8 )
PowPerm2Int( p1, -2 )
PowPerm2Int( p1, -1 )
PowPerm2Int( p1, 0 )
PowPerm2Int( p1, 1 )
PowPerm2Int( p1, 2 )
PowPerm2Int( p1, 8 )
PowPerm2Int( p1, 9 )
PowPerm2Int( p1, 4711 )

PowIntPerm2( 1, prod )
PowIntPerm2( 2, prod )
PowIntPerm2( 3, prod )
PowIntPerm2( 4, prod )

QuoIntPerm2( 1, prod )
QuoIntPerm2( 2, prod )
QuoIntPerm2( 3, prod )
QuoIntPerm2( 4, prod )


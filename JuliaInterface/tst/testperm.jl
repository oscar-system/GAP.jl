##############################################################################
##
##  tests for the Julia code for permutations
##
include( "../julia/gapperm.jl" );

using GAPPermutations

IdentityPerm

imgsarray = [ 1, 2, 3 ]
ccc = convert( Array{UInt16,1}, imgsarray )

p1 = Permutation( ccc )

p1 == Permutation( [ 1, 2, 3 ] )
oneperm = one( p1 )

p1 == oneperm
oneperm == p1
p1 < oneperm
oneperm < p1

p1 = Permutation( [ 2, 1, 3 ] )
p2 = Permutation( [ 1, 3, 2 ] )
p1 == p2
p2 == p1
p1 < p2
p2 < p1

p11 = Permutation( [ 2, 1 ] )
p11 == p1
p1 == p11
p1 < p11
p11 < p1

show( STDOUT, p1 )

p1 * oneperm
oneperm * p1
prod = p1 * p2
prod * prod
oneperm * oneperm

OrderPerm( prod )
OrderPerm( p1 )
OrderPerm( p2 )
OrderPerm( p11 )
OrderPerm( Permutation( [ 2, 1, 4, 5, 3 ] ) )

LargestMovedPointPerm( prod )
LargestMovedPointPerm( oneperm )
LargestMovedPointPerm( p1 )
LargestMovedPointPerm( p11 )
LargestMovedPointPerm( p2 )

inv( oneperm )
inv( p1 )
inv( p11 )
inv( p2 )
inv( prod )

p1^-4711
p1^-9
p1^-8
p1^-2
p1^-1
p1^0
p1^1
p1^2
p1^8
p1^9
p1^4711

1^prod
2^prod
3^prod
4^prod
#T -> result should always be Int64, or always be equal to input type?

1 / prod
2 / prod
3 / prod
4 / prod


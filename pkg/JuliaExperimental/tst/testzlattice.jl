##############################################################################
##
##  tests for the Julia code for Z-lattices
##

include( "../julia/zlattice.jl" );

using GAPZLattice

A = [ 2 -1 -1 -1 ; -1 2 0 0 ; -1 0 2 0 ; -1 0 0 2 ];

sv = ShortestVectors( A, 2 )
size( sv[ "norms" ], 1 )  # should be 12


#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##
#@local A,jmat,sv,arec
gap> START_TEST( "zlattice.tst" );

#
gap> A:= [ [ 2, -1, -1, -1 ], [ -1, 2, 0, 0 ],
>          [ -1, 0, 2, 0 ], [ -1, 0, 0, 2 ] ];;
gap> jmat:= JuliaMatrixFromGapMatrix( A );;
gap> sv:= ShortestVectorsUsingJulia( jmat, 2 );;
gap> Length( sv.vectors );
12

#
gap> A:= [ [ 2, -1, -1, -1 ], [ -1, 2, 0, 0 ],
>          [ -1, 0, 2, 0 ], [ -1, 0, 0, 2 ] ];;
gap> jmat:= JuliaMatrixFromGapMatrix( A );;
gap> arec:= rec();;
gap> sv:= OrthogonalEmbeddingsUsingJulia( jmat, arec );;
gap> Length( sv.vectors );  Length( sv.solutions );
12
3

##
gap> STOP_TEST( "zlattice.tst" );

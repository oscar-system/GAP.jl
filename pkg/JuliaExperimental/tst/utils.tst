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
gap> START_TEST( "utils.tst" );

##
gap> JuliaMatrixFromGapMatrix( [ [ 1, 2 ], [ 3, 4 ] ] );
<Julia: [1 2; 3 4]>

##
gap> STOP_TEST( "utils.tst" );

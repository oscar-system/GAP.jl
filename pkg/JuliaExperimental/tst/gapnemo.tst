#@local l
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
gap> START_TEST( "gapnemo.tst" );

##  small or large integers
gap> l:= JuliaArrayOfFmpz( [ -2, -1, 0, 1, 2, 3 ] );
<Julia: Nemo.ZZRingElem[-2, -1, 0, 1, 2, 3]>
gap> l:= JuliaArrayOfFmpz( [ 1, 2, 3, 2^70 ] );
<Julia: Nemo.ZZRingElem[1, 2, 3, 1180591620717411303424]>

##  small or large rationals
gap> l:= JuliaArrayOfFmpq( [ -2, -1/2, 0, 1, 2/3, 3/7 ] );
<Julia: Nemo.QQFieldElem[-2, -1//2, 0, 1, 2//3, 3//7]>
gap> l:= JuliaArrayOfFmpq( [ 2^70/3, 1/2^70 ] );
<Julia: Nemo.QQFieldElem[1180591620717411303424//3, 1//1180591620717411303424]>

##
gap> STOP_TEST( "gapnemo.tst" );

#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
##
gap> START_TEST( "hnf.tst" );

##  For dimension 10 and 20, the result is likely to consist
##  of small integers.
##  For dimension 30 or larger, the result is likely to contain
##  some large integers.
##
gap> for dim in [ 10, 20 .. 60 ] do
>      m:= RandomMat( dim, dim, Integers );;
>      m_julia:= NemoMatrix_fmpz( m );;
>      hnf_gap:= HermiteNormalFormIntegerMat( m );;
>      hnf_nemo:= HermiteNormalFormIntegerMatUsingNemo( m_julia );;
>      if hnf_gap <> hnf_nemo then
>        Print( "difference in HNF for\n", m, "\n" );
>      fi;
>    od;

##
gap> m_julia:= NemoMatrix_fmpz( [ [ 1, 2 ], [ 3, 2^65 ] ] );
<Julia: [1 2; 3 36893488147419103232]>
gap> GAPMatrix_fmpz_mat( m_julia );
[ [ 1, 2 ], [ 3, 36893488147419103232 ] ]
gap> HermiteNormalFormIntegerMatUsingNemo( m_julia );
[ [ 1, 2 ], [ 0, 36893488147419103226 ] ]

##
gap> STOP_TEST( "hnf.tst" );

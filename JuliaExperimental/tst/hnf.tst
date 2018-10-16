#############################################################################
##
#W  hnf.tst            GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "hnf.tst" );

##  For dimension 10 and 20, the result is likely to consist
##  of small integers.
##  For dimension 30 or larger, the result is likely to contain
##  some large integers.
##
gap> for dim in [ 10, 20 .. 60 ] do
>      m:= RandomMat( dim, dim, Integers );;
>      m_julia:= NemoIntegerMatrix_Eval( m );;
>      hnf_gap:= HermiteNormalFormIntegerMat( m );;
>      hnf_nemo:= HermiteNormalFormIntegerMatUsingNemo( m_julia );;
>      if hnf_gap <> hnf_nemo then
>        Print( "difference in HNF for\n", m, "\n" );
>      fi;
>    od;

##
gap> STOP_TEST( "hnf.tst", 1 );


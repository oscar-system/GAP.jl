
##
gap> START_TEST( "hnf.tst" );

##
gap> m:= RandomMat( 10, 10, Integers );;
gap> hnf_gap:= HermiteNormalFormIntegerMat( m );;
gap> hnf_nemo:= HNFIntMatUsingNemo( m );;
gap> if hnf_gap <> hnf_nemo then
>      Print( "difference in HNF for\n", m, "\n" );
>    fi;

##
gap> STOP_TEST( "hnf.tst", 1 );


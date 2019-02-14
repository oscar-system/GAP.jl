#############################################################################
##
#W  gapnemo.tst        GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "gapnemo.tst" );

##  small or large integers
gap> l:= JuliaArrayOfFmpz( [ -2, -1, 0, 1, 2, 3 ] );
<Julia: Nemo.fmpz[-2, -1, 0, 1, 2, 3]>
gap> l:= JuliaArrayOfFmpz( [ 1, 2, 3, 2^70 ] );
<Julia: Nemo.fmpz[1, 2, 3, 1180591620717411303424]>

##  small or large rationals
gap> l:= JuliaArrayOfFmpq( [ -2, -1/2, 0, 1, 2/3, 3/7 ] );
<Julia: Nemo.fmpq[-2, -1//2, 0, 1, 2//3, 3//7]>
gap> l:= JuliaArrayOfFmpq( [ 2^70/3, 1/2^70 ] );
<Julia: Nemo.fmpq[1180591620717411303424//3, 1//1180591620717411303424]>

##
gap> STOP_TEST( "gapnemo.tst" );


#############################################################################
##
#W  gapperm.tst        GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "gapperm.tst" );

##
gap> p1:= PermutationInJulia( (1,2,3) );
<ext. perm.:<permutation: UInt16[0x0002, 0x0003, 0x0001]>>
gap> p1 = PermutationInJulia( (1,2,3) );
true
gap> p1 = PermutationInJulia( (1,2,3), 6 );
true
gap> p1 = PermutationInJulia( [ 2, 3, 1 ] );
true
gap> p1 = PermutationInJulia( [ 2, 3, 1 ], 6 );
true
gap> oneperm:= One( p1 );
<ext. perm.:<permutation: UInt16[]>>
gap> p1 = oneperm;
false
gap> oneperm = p1;
false
gap> p1 < oneperm;
false
gap> oneperm < p1;
true

##
gap> p1:= PermutationInJulia( (1,2) );
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> p2:= PermutationInJulia( (2,3) );
<ext. perm.:<permutation: UInt16[0x0001, 0x0003, 0x0002]>>
gap> p1 = p2;
false
gap> p2 = p1;
false
gap> p1 < p2;
false
gap> p2 < p1;
true

##
gap> p11:= PermutationInJulia( (1,2), 3 );
<ext. perm.:<permutation: UInt16[0x0002, 0x0001, 0x0003]>>
gap> p11 = p1;
true
gap> p1 = p11;
true
gap> p1 < p11;
false
gap> p11 < p1;
false

##
gap> ViewString( p1 );
"<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>"

##
gap> p1 * oneperm;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> oneperm * p1;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> prod:= p1 * p2;
<ext. perm.:<permutation: UInt16[0x0003, 0x0001, 0x0002]>>
gap> prod * prod;
<ext. perm.:<permutation: UInt16[0x0002, 0x0003, 0x0001]>>
gap> oneperm * oneperm;
<ext. perm.:<permutation: UInt16[]>>

##
gap> Order( prod );
3
gap> Order( p1 );
2
gap> Order( p2 );
2
gap> Order( p11 );
2
gap> Order( PermutationInJulia( [ 2, 1, 4, 5, 3 ] ) );
6
gap> Order( PermutationInJulia( [ 2, 1, 4, 5, 3 ], 10 ) );
6

##
gap> LargestMovedPoint( prod );
3
gap> LargestMovedPoint( oneperm );
0
gap> LargestMovedPoint( p1 );
2
gap> LargestMovedPoint( p11 );
2
gap> LargestMovedPoint( p2 );
3

##
gap> Inverse( oneperm );
<ext. perm.:<permutation: UInt16[]>>
gap> Inverse( p1 );
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> Inverse( p11 );
<ext. perm.:<permutation: UInt16[0x0002, 0x0001, 0x0003]>>
gap> Inverse( p2 );
<ext. perm.:<permutation: UInt16[0x0001, 0x0003, 0x0002]>>
gap> Inverse( prod );
<ext. perm.:<permutation: UInt16[0x0002, 0x0003, 0x0001]>>

##
gap> p1^-4711;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> p1^-9;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> p1^-8;
<ext. perm.:<permutation: UInt16[0x0001, 0x0002]>>
gap> p1^-2;
<ext. perm.:<permutation: UInt16[0x0001, 0x0002]>>
gap> p1^-1;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> p1^0;
<ext. perm.:<permutation: UInt16[]>>
gap> p1^1;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> p1^2;
<ext. perm.:<permutation: UInt16[0x0001, 0x0002]>>
gap> p1^8;
<ext. perm.:<permutation: UInt16[0x0001, 0x0002]>>
gap> p1^9;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>
gap> p1^4711;
<ext. perm.:<permutation: UInt16[0x0002, 0x0001]>>

##
gap> 1^prod;
3
gap> 2^prod;
1
gap> 3^prod;
2
gap> 4^prod;
4

##
gap> 1 / prod;
2
gap> 2 / prod;
3
gap> 3 / prod;
1
gap> 4 / prod;
4

##
gap> STOP_TEST( "gapperm.tst" );


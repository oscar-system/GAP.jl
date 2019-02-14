#############################################################################
##
#W  finvar.tst         GAP 4 package JuliaExperimental          Thomas Breuer
##
gap> START_TEST( "finvar.tst" );

##  trivialities: various constructions of an inv. ring
gap> InvariantRing( Group( (1,2) ) );
<algebra-with-one over Rationals>
gap> InvariantRing( Group( [ [ 0, 1 ], [ -1, 0 ] ] ) );
<algebra-with-one over Rationals>
gap> InvariantRing( Group( (1,2) ), CF(5) );
<algebra-with-one over CF(5)>
gap> InvariantRing( Group( [ [ 0, 1 ], [ -1, 0 ] ] ), CF(5) );
<algebra-with-one over CF(5)>
gap> InvariantRing( Group( (1,2) ), CF(5), 3 );
<algebra-with-one over CF(5)>
gap> InvariantRing( Group( (1,2) ), CF(5), 1 );
Error, <G> moves a point larger than the number of indet.
gap> P:= PolynomialRing( Rationals, [ "x", "y" ] );;
gap> InvariantRing( Group( (1,2,3) ), P );
Error, <G> moves a point larger than the number of indet.
gap> InvariantRing( Group( [ [ -1 ] ] ), P );
Error, the number of indeterminates differs from the dimension of <G>
gap> InvariantRing( Group( [ [ E(4), 0 ], [ 0, 1 ] ] ), P );
Error, field of <G> not contained in coeff. field of <P>
gap> InvariantRing( CyclicGroup( 2 ), P );
Error, <G> must be a permutation group or a matrix group

##  trivialities: inv. ring for a perm. group
gap> P:= PolynomialRing( Rationals, [ "x", "y" ] );
Rationals[x,y]
gap> indets:= IndeterminatesOfPolynomialRing( P );
[ x, y ]
gap> G1:= Group( (1,2) );;
gap> pol:= One( P );;
gap> ImageOfPolynomial( P, pol, G1.1 ) = pol;
true
gap> IsInvariant( P, pol, G1 );
true
gap> R1:= InvariantRing( G1, P );
<algebra-with-one over Rationals>
gap> pol in R1;
true
gap> pol:= IndeterminatesOfPolynomialRing( P )[1];;
gap> ImageOfPolynomial( P, pol, G1.1 ) = pol;
false
gap> pol in R1;
false
gap> IsInvariant( P, pol, G1 );
false

##  trivialities: inv. ring for a matrix group
gap> P:= PolynomialRing( Rationals, [ "x", "y" ] );
Rationals[x,y]
gap> G2:= Group( [ [ 0, 1 ], [ -1, 0 ] ] );;
gap> pol:= One( P );;
gap> ImageOfPolynomial( P, pol, G2.1 ) = pol;
true
gap> IsInvariant( P, pol, G2 );
true
gap> R2:= InvariantRing( G2, P );
<algebra-with-one over Rationals>
gap> pol in R2;
true
gap> pol:= IndeterminatesOfPolynomialRing( P )[1];;
gap> ImageOfPolynomial( P, pol, G2.1 ) = pol;
false
gap> pol in R2;
false
gap> IsInvariant( P, pol, G2 );
false

##
gap> List( [ 0 .. 3 ], d -> MonomialsOfGivenDegree( P, d ) );
[ [ 1 ], [ y, x ], [ y^2, x*y, x^2 ], [ y^3, x*y^2, x^2*y, x^3 ] ]
gap> ReynoldsOperator( R1 );
[ [ x, y ], [ y, x ] ]
gap> ReynoldsOperator( R1, One( P ) );
1
gap> ReynoldsOperator( R1, indets[1] );
1/2*x+1/2*y
gap> ReynoldsOperator( R2 );
[ [ -x, -y ], [ y, -x ], [ -y, x ], [ x, y ] ]
gap> ReynoldsOperator( R2, One( P ) );
1
gap> ReynoldsOperator( R2, indets[1] );
0
gap> MolienInfo( R1 );
[ [ 1, -1 ], [ 1, -2, 0, 2, -1 ], [  ] ]
gap> EvaluateMolienSeries( R1, 15 );
[ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8 ]
gap> BasisOfInvariantsOfGivenDegree( R1, 0 );
[ 1 ]
gap> BasisOfInvariantsOfGivenDegree( R1, 1 );
[ x+y ]
gap> BasisOfInvariantsOfGivenDegree( R1, 3 );
[ x^2*y+x*y^2, x^3+y^3 ]
gap> BasisOfInvariantsOfGivenDegree( R1, 4 );
[ x^3*y+x*y^3, x^2*y^2, x^4+y^4 ]
gap> BasisOfInvariantsOfGivenDegree( R1, 5 );
[ x^4*y+x*y^4, x^3*y^2+x^2*y^3, x^5+y^5 ]

##
gap> prim1:= PrimaryInvariants( R1 );
[ x+y, x*y ]
gap> DegreesOfSecondaryInvariants( R1, prim1 );
[ 1 ]
gap> sec1:= SecondaryInvariants( R1, prim1 );
[ 1 ]
gap> IsSubset( R1, sec1 );
true

##
gap> prim2:= PrimaryInvariants( R2 );
[ x^2+y^2, -x^3*y+x*y^3 ]
gap> DegreesOfSecondaryInvariants( R2, prim2 );
[ 1, 0, 0, 0, 1 ]
gap> sec2:= SecondaryInvariants( R2, prim2 );
[ 1, x^2*y^2 ]
gap> IsSubset( R2, sec2 );
true

##  Example 3.3.6, p. 84
gap> G3:= Group( [ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, E(4) ] ],
>                [ [ -1, 0, 0 ], [ 0, -1, 0 ], [ 0, 0, 1 ] ] );;
gap> P3:= PolynomialRing( FieldOfMatrixGroup( G3 ), [ "x", "y", "z" ] );
GaussianRationals[x,y,z]
gap> R3:= InvariantRing( G3, P3 );
<algebra-with-one over GaussianRationals>
gap> EvaluateMolienSeries( R3, 15 );
[ 1, 0, 3, 0, 6, 0, 10, 0, 15, 0, 21, 0, 28, 0, 36, 0 ]
gap> prim3:= PrimaryInvariants( R3 );
[ x*y, x^2+y^2, z^4 ]
gap> DegreesOfSecondaryInvariants( R3, prim3 );
[ 1, 0, 1 ]
gap> sec3:= SecondaryInvariants( R3, prim3 );
[ 1, x^2 ]
gap> IsSubset( R3, sec3 );
true

##  Example 3.5.4 (c), p. 92
gap> a:= (1+Sqrt(5))/2;;
gap> G4:= Group( [ [ 1, a, 0 ], [ 0, 0, 1 ], [ 0, -1, -1 ] ],
>                [ [ -a, -a, 0 ], [ 0, 0, -1 ], [ a, 1, 1 ] ] );;
gap> P4:= PolynomialRing( FieldOfMatrixGroup( G4 ), [ "x", "y", "z" ] );
<field in characteristic 0>[x,y,z]
gap> R4:= InvariantRing( G4, P4 );
<algebra-with-one over NF(5,[ 1, 4 ])>
gap> EvaluateMolienSeries( R4, 15 );
[ 1, 0, 1, 0, 1, 0, 2, 0, 2, 0, 3, 0, 4, 0, 4, 1 ]
gap> prim4:= PrimaryInvariants( R4 );;  List( prim4, Degree );
[ 2, 6, 10 ]
gap> DegreesOfSecondaryInvariants( R4, prim4 );
[ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]
gap> sec4:= SecondaryInvariants( R4, prim4 );;  List( sec4, Degree );
[ 0, 15 ]
gap> IsSubset( R4, sec4 );
true

##
gap> STOP_TEST( "finvar.tst" );


##############################################################################
##
##  finvar.gd
##
##  functionality for polynomial invariants of finite groups
##


##############################################################################
##
#I  InfoInvariants
##
DeclareInfoClass( "InfoInvariants" );


##############################################################################
##
#C  IsInvariantRing( <R> )
##
DeclareCategory( "IsInvariantRing", IsRing );


##############################################################################
##
#A  InvariantRing( <G> )
#O  InvariantRing( <G>, <K> )
#O  InvariantRing( <G>, <K>, <n> )
#O  InvariantRing( <G>, <P> )
##
##  is the <A>K</A>-algebra of polynomial invariants for the finite group
##  <A>G</A>, which must be a permutation group or a matrix group over a
##  subfield of <A>K</A>.
##  The default for <K> is Rationals in the case of a permutation group,
##  or FieldOfMatrixGroup( <G> ) in the case of a matrix group.
##  <P/>
##  The returned algebra is a subset of the polynomial ring in <A>n</A>
##  indeterminates over <A>K</A>;
##  if <A>G</A> is a matrix group then <A>n</A> is equal to the dimension
##  of the matrices in <A>G</A>,
##  if <A>G</A> is a permutation group then <A>n</A> can be prescribed,
##  and the default for <A>n</A> is the largest moved point of <A>G</A>.
##  <P/>
##  Alternatively, one can enter a polynomial ring <A>P</A> over <A>K</A>
##  as the second argument.
##
DeclareAttribute( "InvariantRing", IsGroup );
DeclareOperation( "InvariantRing", [ IsGroup, IsField ] );
DeclareOperation( "InvariantRing", [ IsGroup, IsField, IsInt ] );
DeclareOperation( "InvariantRing", [ IsGroup, IsPolynomialRing ] );


##############################################################################
##
#O  ImageOfPolynomial( <R>, <pol>, <mat> )
#O  ImageOfPolynomial( <R>, <pol>, <perm> )
##
##  Let <A>R</A> be a polynomial, <A>pol</A> be an element of <A>R</A>,
##  and <A>mat</A> or <A>perm</A> be a matrix or permutation, respectively,
##  that acts of the indeterminates of <A>R</A>.
##  <Ref Oper="ImageOfPolynomial"/> returns the polynomial that is obtained
##  from <A>pol</A> by substituting the indeterminates of <A>R</A>.
##  <P/>
##  Note that we cannot write <A>pol</A><C>^</C><A>mat</A>
##  because <A>pol</A> does not know about the polynomial ring
##  w.r.t. which the action is considered.
##
DeclareOperation( "ImageOfPolynomial",
    [ IsPolynomialRing, IsPolynomial, IsMatrixObj ] );

DeclareOperation( "ImageOfPolynomial",
    [ IsPolynomialRing, IsPolynomial, IsPerm ] );


##############################################################################
##
#O  IsInvariant( <R>, <pol>, <elm> )
#O  IsInvariant( <R>, <pol>, <G> )
##
##  returns <K>true</K> if <Ref Oper="ImageOfPolynomial"/> returns <A>pol</A>
##  for the matrix or permutation <A>elm</A> or for all generators of the
##  group <A>G</A>, and <K>false</K> otherwise.
##
DeclareOperation( "IsInvariant",
    [ IsPolynomialRing, IsPolynomial, IsMatrixObj ] );

DeclareOperation( "IsInvariant",
    [ IsPolynomialRing, IsPolynomial, IsPerm ] );

DeclareOperation( "IsInvariant",
    [ IsPolynomialRing, IsPolynomial, IsGroup ] );


##############################################################################
##
#F  EvaluateMolienSeries( <R>, <d> )
#A  MolienInfo( <R> )
##
##  For an invariant ring <A>R</A> in the non-modular case,
##  <Ref Func="EvaluateMolienSeries"/> returns a list with (at least)
##  the first <A>d</A><M> + 1</M> coefficients of the Molien series.
##  <P/>
##  The attribute <Ref Attr="MolienInfo"/> stores known data about the
##  Molien series (numerator, denominator, coefficients that have already
##  been computed).
##
DeclareGlobalFunction( "EvaluateMolienSeries" );

DeclareAttribute( "MolienInfo", IsInvariantRing, "mutable" );

#T  TODO:  Turn GAP's global function 'MolienSeries' into an attribute,
#T         add a method for invariant rings.
#T         (What shall the value be:
#T         closed form or just an object that can be asked for coefficients?)


##############################################################################
##
#F  MonomialsOfGivenDegree( <R>, <d> )
##
##  For a polynomial ring <A>R</A> and a positive integer <A>d</A>,
##  this function returns the list of all monomials of degree <A>d</A>.
##
DeclareGlobalFunction( "MonomialsOfGivenDegree" );


##############################################################################
##
#A  ReynoldsOperator( <R> )
#O  ReynoldsOperator( <R>, <pol> )
##
DeclareAttribute( "ReynoldsOperator", IsInvariantRing );

DeclareOperation( "ReynoldsOperator", [ IsInvariantRing, IsPolynomial ] );


##############################################################################
##
#F  BasisOfInvariantsOfGivenDegree( <R>, <d> )
##
##  returns a list maximal length of linearly independent invariant
##  polynomials of degree <A>d</A> in the invariant ring <A>R</A>.
##
DeclareGlobalFunction( "BasisOfInvariantsOfGivenDegree" );

DeclareAttribute( "ComputedBasesOfInvariantsOfGivenDegree",
    IsInvariantRing, "mutable" );


##############################################################################
##
#A  PrimaryInvariants( <R> )
##
DeclareAttribute( "PrimaryInvariants", IsInvariantRing );


##############################################################################
##
#M  SecondaryInvariants( <R>[, <primary>] )
##
DeclareAttribute( "SecondaryInvariants", IsInvariantRing );

DeclareOperation( "SecondaryInvariants", [ IsInvariantRing, IsList ] );


##############################################################################
##
#T  TODO: further operations for invariant rings
##
#A  HilbertSeries( <R> )  (only other name, but also for modular case)
#A  FundamentalInvariants( <R> )
#P  IsCohenMacaulay( <R> )
#A  FreeResolution( <R> )
#A  HomologicalDimension( <R> )
#A  Depth( <R> )
##


##############################################################################
##
#E


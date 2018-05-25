##############################################################################
##
##  scfield.g
##
##  This is an experimental implementation of abelian number fields in GAP
##  (elements, vectors, matrices) via s. c. algebras.
##




# .................................
# 
f:= Field( Rationals, [ Sqrt(5) ] );
b:= Basis( f );
t:= StructureConstantsTable( b );
ff:= DivisionRingByStructureConstants( Rationals, t );
HasOne( ff );

ff:= DivisionRingByStructureConstants( Rationals, t : onecoeffs:= [-1,-1] );
HasOne( ff );

#T no ViewObj method that identifies as division ring!

#T generic GeneratorsOfDivisionRing method for library

guarantee  IsDenseCoeffVectorRep !  (via type)

IsDivisionRing( ff );
HasBasis( ff );
HasGeneratorsOfVectorSpace( ff );

HasGeneratorsOfAlgebraWithOne( ff );
GeneratorsOfAlgebraWithOne( ff );

# false
# 
# .................................
# 
# 
# #############################################################################
# ##
# #E
# 
# ElementOfFieldSC:= function( F, coeffs )

-> in library via ObjByExtRep

# 
# end;


#############################################################################
##
##  realiz. of fields of cyclotomics via alg. extensions:
##  set information that yields the correspondence with cyclotomics
##
DeclareCategory( "IsAlgebraicElementCyc", IsAlgebraicElement );

AbelianNumberFieldAE:= function( n, stab )
#T assume that n is minimal ...
    local r, gen, pol, F, efam;

    r:= E(n);
    if Length( stab ) = 1 then
      gen:= r;
      pol:= CyclotomicPolynomial( Rationals, n );
    else
      gen:= Sum( List( stab, i -> r^i ) );
      pol:= MinimalPolynomial( Rationals, gen );
    fi;

    F:= AlgebraicExtension( Rationals, pol );

    efam:= ElementsFamily( FamilyObj( F ) );
    efam!.IMP_FLAGS:= AND_FLAGS( efam!.IMP_FLAGS,
                                 FLAGS_FILTER( IsAlgebraicElementCyc ) );
    efam!.baseType:= Subtype( efam!.baseType, IsAlgebraicElementCyc );
    efam!.extType:= Subtype( efam!.extType, IsAlgebraicElementCyc );
    efam!.primitiveElmCyc:= gen;
    SetFilterObj( efam!.primitiveElm, IsAlgebraicElementCyc );
    SetFilterObj( One( efam ), IsAlgebraicElementCyc );
    SetFilterObj( Zero( efam ), IsAlgebraicElementCyc );
    SetConductor( efam, n );
    SetConductor( F, n );

    return F;
end;


CyclotomicFieldAE:= n -> AbelianNumberFieldAE( n, [ 1 ] );


CorrespondingCyclotomic:= function( algelmcyc )
    local coeffs;

    coeffs:= algelmcyc![1];
    if not IsList( coeffs ) then
      return coeffs;
    fi;
    return ValuePol( coeffs, FamilyObj( algelmcyc )!.primitiveElmCyc );
end;


CorrespondingFieldElement:= function( F, cyc )
    local efam, basis, v, coeffs;

    if IsRat( cyc ) then
      return ObjByExtRep( ElementsFamily( FamilyObj( F ) ), cyc );
    fi;

    # Compute the coefficients of 'cyc' w.r.t. the basis
    # of the field that consists of powers of the generator.
#T easier for cycl. field ...
    efam:= ElementsFamily( FamilyObj( F ) );
    if not IsBound( efam!.canonicalBasisCyc ) then
      basis:= List( [ 0 .. Dimension( F ) - 1 ],
                    i -> efam!.primitiveElmCyc^i );
#T cheaper!
      v:= VectorSpace( Rationals, basis, "basis" );
      efam!.canonicalBasisCyc:= BasisNC( v, basis );
    fi;

    coeffs:= Coefficients( efam!.canonicalBasisCyc, cyc );
    if coeffs = fail then
      return fail;
    fi;

    return ObjByExtRep( efam, coeffs );
end;


##  ad hoc arithmetics

InstallMethod( \+, [ IsCyc, IsAlgebraicElementCyc ],
    function( cyc, algelmcyc )
      return cyc + CorrespondingCyclotomic( algelmcyc );
    end );

InstallMethod( \-, [ IsCyc, IsAlgebraicElementCyc ],
    function( cyc, algelmcyc )
      return cyc - CorrespondingCyclotomic( algelmcyc );
    end );

InstallMethod( \*, [ IsCyc, IsAlgebraicElementCyc ],
    function( cyc, algelmcyc )
      return cyc * CorrespondingCyclotomic( algelmcyc );
    end );

InstallMethod( \/, [ IsCyc, IsAlgebraicElementCyc ],
    function( cyc, algelmcyc )
      return cyc / CorrespondingCyclotomic( algelmcyc );
    end );


InstallMethod( \+, [ IsAlgebraicElementCyc, IsCyc ],
    function( algelmcyc, cyc )
      return CorrespondingCyclotomic( algelmcyc ) + cyc;
    end );

InstallMethod( \-, [ IsAlgebraicElementCyc, IsCyc ],
    function( algelmcyc, cyc )
      return CorrespondingCyclotomic( algelmcyc ) - cyc;
    end );

InstallMethod( \*, [ IsAlgebraicElementCyc, IsCyc ],
    function( algelmcyc, cyc )
      return CorrespondingCyclotomic( algelmcyc ) * cyc;
    end );

InstallMethod( \/, [ IsAlgebraicElementCyc, IsCyc ],
    function( algelmcyc, cyc )
      return CorrespondingCyclotomic( algelmcyc ) / cyc;
    end );

#T \=, \<, ...: not equal behaviour! (family question ...)


#T TODO: ViewObj for elements!


# CyclotomicFieldSC:= function( n )
# 
# end;
# 
# 
# AbelianNumberFieldSC:= function( n, stab )
# 
# end;
# 
# 
# IsomorphismSCAlgebra: take field filters into account!
# -> and support natural embeddings,
#    via a function that knows how to create a cyclotomic from the object


###########################################################################
# 
# implement SCAlgebraVector, SCAlgebraMatrix!
# (avoid creating lots of objects; just fetching entries becomes expensive ...)
# 
# always immutable (no \[\]\:\=) ???  -> better not ...


##
##  coeffs is a list of coefficient vectors w.r.t. the defining basis of A
##
BindGlobal( "SCAlgebraVector", function( A, coeffs )
    ...
    end );

# -> need function that takes a coeff. vector and prints the string for the
#    corresp. element

DeclareCategory( "IsSCAlgebraVectorObj", IsVectorObj );

InstallMethod( BaseDomain,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
# the number field
    end );

InstallMethod( \[\],
    [ "IsSCAlgebraVectorObj", "IsPosInt" ],
    function( scalgvec, pos )
...
    end );

InstallMethod( \{\},
    [ "IsSCAlgebraVectorObj", "IsDenseList" ],
    function( scalgvec, poss )
...
    end );
#T ExtractSubVector -- needed, or generic method?

InstallMethod( PositionNonZero,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( PositionLastNonZero,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ListOp,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ListOp,
    [ "IsSCAlgebraVectorObj", "IsFunction" ],
    function( scalgvec, func )
...
    end );

InstallMethod( Unpack,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ShallowCopy,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
# create plain list
    end );

InstallMethod( StructuralCopy,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
# create plain list
    end );

InstallMethod( ViewObj,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( PrintObj,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
# self-contained?
    end );

InstallMethod( String,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( String,
    [ "IsSCAlgebraVectorObj", "IsInt" ],
    function( scalgvec, formatinfo )
...
    end );

InstallMethod( Display,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( AddRowVector,
    [ "IsSCAlgebraVectorObj and IsMutable", "IsSCAlgebraVectorObj" ],
    function( scalgvec1, scalgvec2 )
...
    end );

InstallMethod( AddRowVector,
    [ "IsSCAlgebraVectorObj and IsMutable", "IsSCAlgebraVectorObj",
      "IsObject" ],
    function( scalgvec1, scalgvec2, mult )
...
    end );

InstallMethod( AddRowVector,
    [ "IsSCAlgebraVectorObj and IsMutable", "IsSCAlgebraVectorObj",
      "IsObject", "IsPosInt", "IsPosInt" ],
    function( scalgvec1, scalgvec2, mult, pos1, pos2 )
...
    end );

InstallMethod( MultRowVector,
    [ "IsSCAlgebraVectorObj and IsMutable", "IsObject" ],
    function( scalgvec1, mult )
...
    end );

InstallMethod( MultRowVector,
    [ "IsSCAlgebraVectorObj and IsMutable", "IsList", "IsSCAlgebraVectorObj",
      "IsList", "IsObject" ],
    function( scalgvec1, list1, scalgvec2, list2, mult )
...
    end );

InstallMethod( \*,
    [ "IsSCAlgebraVectorObj", "IsObject" ],
    function( scalgvec, mult )
...
    end );

InstallMethod( \*,
    [ "IsObject", "IsSCAlgebraVectorObj" ],
    function( mult, scalgvec )
...
    end );

InstallMethod( \/,
    [ "IsSCAlgebraVectorObj", "IsObject" ],
    function( scalgvec, mult )
...
    end );

InstallMethod( AdditiveInverseImmutable,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( AdditiveInverseMutable,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( AdditiveInverseSameMutability,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ZeroImmutable,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ZeroMutable,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ZeroSameMutability,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( IsZero,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( Characteristic,
    [ "IsSCAlgebraVectorObj" ],
    function( scalgvec )
...
    end );

InstallMethod( ScalarProduct,
    [ "IsSCAlgebraVectorObj", "IsSCAlgebraVectorObj" ],
    function( scalgvec1, scalgvecobj2 )
...
    end );

DeclareOperation( "ZeroVector", [IsInt,IsVectorObj] );
# Returns a new mutable zero vector in the same rep as the given one with
# a possible different length.

DeclareOperation( "ZeroVector", [IsInt,IsMatrixObj] );
# Returns a new mutable zero vector in a rep that is compatible with
# the matrix but of possibly different length.

DeclareOperation( "Vector", [IsList,IsVectorObj]);
# Creates a new vector in the same representation but with entries from list.
# The length is given by the length of the first argument.
# It is *not* guaranteed that the list is copied!

DeclareOperation( "ConstructingFilter", [IsVectorObj] );

DeclareConstructor( "NewVector", [IsVectorObj,IsSemiring,IsList] );
# A constructor. The first argument must be a filter indicating the
# representation the vector will be in, the second is the base domain.
# The last argument is guaranteed not to be changed!

DeclareConstructor( "NewZeroVector", [IsVectorObj,IsSemiring,IsInt] );
# A similar constructor to construct a zero vector, the last argument
# is the base domain.

DeclareOperation( "ChangedBaseDomain", [IsVectorObj,IsSemiring] );
# Changes the base domain. A copy of the row vector in the first argument is
# created, which comes in a "similar" representation but over the new
# base domain that is given in the second argument.
???

DeclareOperation( "Randomize", [IsVectorObj and IsMutable] );
# Changes the mutable argument in place, every entry is replaced
# by a random element from BaseDomain.
# The argument is also returned by the function.

DeclareOperation( "Randomize", [IsVectorObj and IsMutable,IsRandomSource] );
# The same, use the second argument to provide "randomness".
# The vector argument is also returned by the function.

-> necessary or generic?

DeclareOperation( "CopySubVector",
  [IsVectorObj,IsVectorObj and IsMutable, IsList,IsList] );


###########################################################################

DeclareCategory( "IsSCAlgebraMatrixObj", IsMatrixObj );

InstallMethod( BaseDomain,
    [ "IsSCAlgebraMatrixObj" ],
    function( scalgmat )
...
# the number field
    end );

DeclareAttribute( "NumberRows", IsMatrixObj );
DeclareAttribute( "NumberColumns", IsMatrixObj );

DeclareAttribute( "DimensionsMat", IsMatrixObj );   # returns [rows,cols]

DeclareAttribute( "RankMat", IsMatrixObj );
DeclareOperation( "RankMatDestructive", [ IsMatrixObj ] );

... etc. ...

# 
# Idea:
# -----
# 
# vector/matrix over some domain D whose elements are described
# by a coefficient vector;
# store the vector/matrix of these coefficient vectors,
# without creating the elements themselves
# 
# -> this works for algebraic extension elements and for s.c. algebra elements!
#    (careful: alg. ext. has 2 repres. of elements, one for base field elements!)
# 
# -> make everything inside immutable, this accelerates list arithmetics!
# 



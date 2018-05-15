##############################################################################
##
##  numfield.g
##
##  This is an experimental interface to Nemo's elements of number fields.
##

#T as soon as Nemo/Hecke's QabElem objects are available,
#T provide a conversion of single GAP cyclotomics?


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "numfield.jl" ) );

ImportJuliaModuleIntoGAP( "Core" );
ImportJuliaModuleIntoGAP( "Base" );
ImportJuliaModuleIntoGAP( "Nemo" );
ImportJuliaModuleIntoGAP( "GAPNumberFields" );


#############################################################################
##
##  Declare filters.
##
DeclareCategory( "IsNemoObject", IsObject );

DeclareSynonym( "IsNemoPolynomialRing",
    IsNemoObject and IsUnivariatePolynomialRing );
DeclareSynonym( "IsNemoField", IsNemoObject and IsField );
DeclareSynonym( "IsNemoNumberField", IsNemoField and IsNumberField );
DeclareSynonym( "IsNemoFieldElement", IsNemoObject and IsScalar );
DeclareSynonym( "IsNemoMatrixObj", IsNemoObject and IsMatrixObj );


#############################################################################
##
##  We need Nemo's ZZ and QQ for creating extensions and polynomial rings.
##
BindGlobal( "Nemo_ZZ", Objectify(
    NewType( CollectionsFamily( NewFamily( "Nemo_ZZ_ElementsFamily" ) ),
             IsAttributeStoringRep and IsRing ),
    rec() ) );
SetName( Nemo_ZZ, "Nemo_ZZ" );
SetLeftActingDomain( Nemo_ZZ, Nemo_ZZ );
SetSize( Nemo_ZZ, infinity );
SetJuliaPointer( Nemo_ZZ, Julia.Nemo.ZZ );
ElementsFamily( FamilyObj( Nemo_ZZ ) )!.matrixType:= NewType(
    CollectionsFamily( FamilyObj( Nemo_ZZ ) ),
    IsMatrixObj and IsNemoObject and IsAttributeStoringRep );

BindGlobal( "Nemo_QQ", Objectify(
    NewType( CollectionsFamily( NewFamily( "Nemo_QQ_ElementsFamily" ) ),
             IsAttributeStoringRep and IsField and IsPrimeField ),
    rec() ) );

SetName( Nemo_QQ, "Nemo_QQ" );
SetLeftActingDomain( Nemo_QQ, Nemo_QQ );
SetSize( Nemo_QQ, infinity );
SetJuliaPointer( Nemo_QQ, Julia.Nemo.QQ );
ElementsFamily( FamilyObj( Nemo_QQ ) )!.matrixType:= NewType(
    CollectionsFamily( FamilyObj( Nemo_QQ ) ),
    IsMatrixObj and IsNemoObject and IsAttributeStoringRep );


#############################################################################
##
##  We need polynomial rings in order to create polynomials.
##


#############################################################################
##
#F  Nemo_PolynomialRing( <R>, <name> )
##
##  univariate only
##
BindGlobal( "Nemo_PolynomialRing", function( R, name )
    local type, juliaobj, efam, result, getindex, indet;

    type:= IsNemoPolynomialRing and IsAttributeStoringRep and IsFreeLeftModule
           and IsFLMLORWithOne;

    # Check the arguments.
    if IsIdenticalObj( R, Integers ) or IsIdenticalObj( R, Nemo_ZZ ) then
      R:= Nemo_ZZ;
      type:= type and IsCommutative and IsAssociative;
    elif IsIdenticalObj( R, Rationals ) or IsIdenticalObj( R, Nemo_QQ ) then
      R:= Nemo_QQ;
      type:= type and IsAlgebraWithOne and IsEuclideanRing
             and IsCommutative and IsAssociative
             and IsRationalsPolynomialRing;
    elif not HasJuliaPointer( R ) then
#T admit also *finite* field in GAP (-> IsFiniteFieldPolynomialRing)
#T admit algebraic extensions (-> IsAlgebraicExtensionPolynomialRing)
#T admit GAP's abelian number fields (-> IsAbelianNumberFieldPolynomialRing)
      Error( "usage: ..." );
    fi;
    if not IsString( name ) then
      Error( "<name> must be a string" );
    fi;

    # Create the julia objects.
    juliaobj:= Julia.Nemo.PolynomialRing( JuliaPointer( R ), name );

    # Create the GAP wrapper.
    # Note that elements from two Nemo polynomial rings cannot be compared,
    # so we create always a new family.
    efam:= NewFamily( "NEMO_PolynomialsFamily" );
    efam!.defaultPolynomialType:= NewType( efam,
        IsPolynomial and IsNemoObject and IsAttributeStoringRep );

    result:= Objectify( NewType( CollectionsFamily( efam ), type ), rec() );

    # Set attributes.
    getindex:= Julia.Base.getindex;
    SetJuliaPointer( result, getindex( juliaobj, 1 ) );
    indet:= getindex( juliaobj, 2 );
    SetLeftActingDomain( result, R );
    SetIndeterminatesOfPolynomialRing( result, [ indet ] );
    SetIsFinite( result, false );
    SetIsFiniteDimensional( result, false );
    SetSize( result, infinity );
    SetCoefficientsRing( result, R );
    SetGeneratorsOfLeftOperatorRingWithOne( result, [ indet ] );
#T set one and zero?

    return result;
end );


#############################################################################
##
#F  Nemo_Polynomial( <R>, <descr> )
##
##  <R> is the Nemo polynomial ring over QQ or ZZ,
##  <descr> is a GAP list of coefficients (integers or rationals).
##
BindGlobal( "Nemo_Polynomial", function( R, descr )
    local fmpq, div, aux, pol;

    if not IsNemoPolynomialRing( R ) then
      Error( "<R> must be a Nemo polynomial ring" );
    elif Length( descr ) = 0 then
      return Zero( R );
    elif ForAll( descr, IsInt ) then
      # Nothing is to do.
    elif ForAll( descr, IsRat ) then
      # 'JuliaBox' does not allow us to transfer rationals.
      fmpq:= Julia.Nemo.fmpq;
      div:= Julia.Base.("//");
      descr:= List( descr,
                    x -> div( fmpq( NumeratorRat( x ) ),
                              fmpq( DenominatorRat( x ) ) ) );
    else
      Error( "<descr> must be a list of rationals (or integers)" );
    fi;

    aux:= Julia.GAPUtilsExperimental.MatrixFromNestedArray( descr );
    aux:= Julia.Base.vec( aux );
    pol:= JuliaPointer( R )( aux );

    return ObjectifyWithAttributes( rec(),
        ElementsFamily( FamilyObj( R ) )!.defaultPolynomialType,
        JuliaPointer, pol );
end );


#############################################################################
##
##  constructors for fields and field elements
##


#############################################################################
##
#F  Nemo_Field( <AlgExt>[, <name>] )
#F  Nemo_Field( <BaseField>, <GAP_pol>[, <name>] )
#F  Nemo_Field( <BaseField>, <GAP_coeffs>[, <name>] )
##
BindGlobal( "Nemo_Field", function( F, descr... )
    local name, coeffs, R, pol, juliaobj, efam, collfam, filt, result,
          access, gen;

    # Check the arguments.
    name:= "a";
    if IsAlgebraicExtension( F ) then
      descr:= Concatenation( [ DefiningPolynomial( F ) ], descr );
      F:= LeftActingDomain( F );
    fi;

    if IsIdenticalObj( F, Rationals ) or IsIdenticalObj( F, Nemo_QQ ) then
      F:= Nemo_QQ;
    elif not HasJuliaPointer( F ) then
#T admit also a Nemo field!
      Error( "usage: ..." );
    fi;

    if Length( descr ) = 2 and IsString( descr[2] ) then
      name:= descr[2];
    fi;

    if Length( descr ) >= 1 then
      if IsUnivariatePolynomial( descr[1] ) then
        coeffs:= CoefficientsOfUnivariatePolynomial( descr[1] );
      else
        coeffs:= descr[1];
      fi;
    fi;
    if Length( coeffs ) < 3 then
      Error( "need a polynomial of degree at least 2" );
    fi;

    # Create the julia objects.
    R:= Nemo_PolynomialRing( F, "$" );
    pol:= Nemo_Polynomial( R, coeffs );
    juliaobj:= Julia.Nemo.NumberField( JuliaPointer( pol ), name );

    # Create the GAP wrapper.
    # Note that elements from two NEMO field extensions cannot be compared,
    # so we create always a new family.
    # (This is the same as in GAP's 'AlgebraicExtension'.)
    efam:= NewFamily( "NEMO_FieldElementsFamily" );
    efam!.defaultType:= NewType( efam,
        IsAlgebraicElement and IsNemoObject and IsAttributeStoringRep );
    collfam:= CollectionsFamily( efam );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoObject and IsAttributeStoringRep );
    filt:= IsField and IsAttributeStoringRep;
#T set also 'IsNumberField' etc., depending on the situation
    result:= Objectify( NewType( collfam, filt ), rec() );

    # Set attributes.
    access:= Julia.Base.getindex;
    SetJuliaPointer( result, access( juliaobj, 1 ) );

    gen:= ObjectifyWithAttributes( rec(), efam!.defaultType,
              JuliaPointer, access( juliaobj, 2 ) );
    SetLeftActingDomain( result, F );
    SetDefiningPolynomial( result, pol );
    SetRootOfDefiningPolynomial( result, gen );
    SetCharacteristic( result, 0 );
    SetIsFiniteDimensional( result, true );
    SetGeneratorsOfField( result, [ gen ] );
    SetIsPrimeField( result, false );
    SetPrimitiveElement( result, gen );

    return result;
end );


#T  Random for this field:
#T  method for alg. ext.; method for v. sp. -> then need basis ...
#T  -> and need arithm. between GAP coeffs. and NEMO field elements


#############################################################################
##
#F  NemoElement( <template>, <jpointer> )
##
##  is used to wrap field elements, matrices, ...
##
BindGlobal( "NemoElement", function( template, jpointer )
    local type, result;

    if IsDomain( template ) then
      type:= ElementsFamily( FamilyObj( template ) )!.defaultType;
    else
      type:= FamilyObj( template )!.defaultType;
    fi;

    result:= ObjectifyWithAttributes( rec(), type, JuliaPointer, jpointer );

    return result;
end );


#############################################################################
##
##  methods for Nemo's polynomial rings and fields
##
InstallOtherMethod( Zero, [ IsNemoObject ], 200,
    F -> NemoElement( F, Julia.Base.zero( JuliaPointer( F ) ) ) );

InstallOtherMethod( One, [ IsNemoObject ], 200,
    F -> NemoElement( F, Julia.Base.one( JuliaPointer( F ) ) ) );

InstallMethod( RootOfDefiningPolynomial, [ IsNemoField ],
    F -> NemoElement( F, Julia.Nemo.gen( JuliaPointer( F ) ) ) );


#############################################################################
##
##  methods for field elements
##
InstallOtherMethod( ViewString, [ IsNemoObject ],
    x -> Concatenation( "<", ViewString( JuliaPointer( x ) ), ">" ) );

InstallOtherMethod( \=, [ IsNemoObject, IsNemoObject ],
    function( x, y )
      return JuliaUnbox(
                 Julia.Base.("==")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \+, [ IsNemoObject, IsNemoObject ],
    function( x, y )
      return NemoElement( x,
                 Julia.Base.("+")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \+, [ IsNemoObject, IsInt ],
    function( x, y )
      return NemoElement( x,
                 Julia.Base.("+")( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( AdditiveInverse, [ IsNemoObject ],
    x -> NemoElement( x, Julia.Base.("-")( JuliaPointer( x ) ) ) );

InstallOtherMethod( \-, [ IsNemoObject, IsNemoObject ],
    function( x, y )
      return NemoElement( x,
                 Julia.Base.("-")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \*, [ IsNemoObject, IsNemoObject ],
    function( x, y )
      return NemoElement( x,
                 Julia.Base.("*")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \/, [ IsNemoObject, IsNemoObject ],
    function( x, y )
      return NemoElement( x, Julia.Nemo.divexact(
                     JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \^, [ IsNemoObject, IsPosInt ],
    function( x, n )
      return NemoElement( x, Julia.Base.("^")( JuliaPointer( x ), n ) );
    end );


#############################################################################
##
##  Nemo matrices of elements of field extensions:
##  We create the coefficient vectors corresp. to the field elements,
##  and let Nemo convert them to field elements.
##


#############################################################################
##
#F  NemoMatrix( <nemo_field>, <gapmatrix_over_field> )
##
##  We assume that <gapmatrix_over_field> is a list of lists over
##  an algebraic extension 'F' in GAP,
##  and that <nemo_field> equals 'Nemo_Field( F )'.
##  (Thus the two fields are defined by the same polynomial.)
##
BindGlobal( "NemoMatrix", function( nemoF, gapmat )
    local m, n, coeffs, d, res, obj;

    # Remember the dimensions.
    m:= NumberRows( gapmat );
    n:= NumberColumns( gapmat );

    # Extract the coefficient vectors.
    coeffs:= Concatenation( gapmat );
    if IsIdenticalObj( nemoF, Nemo_ZZ ) then
      # The data format is different.
      res:= NemoMatrix_fmpz( gapmat );
    elif IsIdenticalObj( nemoF, Nemo_QQ ) then
      # The data format is different.
      res:= NemoMatrix_fmpq( gapmat );
    else
      # Compute the common denominator.
      coeffs:= List( coeffs, ExtRepOfObj );
      d:= Lcm( List( Concatenation( coeffs ), DenominatorRat ) );
      coeffs:= coeffs * d;

      # Convert the list of integral coefficient vectors
      # to a suitable matrix in Julia (Nemo.fmpz_mat).
      res:= Julia.GAPUtilsExperimental.MatrixFromNestedArray( coeffs );
# The following does not work in Nemo 0.6.0 but works in Nemo 0.7.3 ...
      res:= Julia.Nemo.matrix( Julia.Nemo.ZZ, res );

      # Call the Julia function.
      res:= Julia.GAPNumberFields.Nemo_Matrix_over_NumberField(
                JuliaPointer( nemoF ), m, n, res, d );
    fi;

    return ObjectifyWithAttributes( rec(),
        ElementsFamily( FamilyObj( nemoF ) )!.matrixType,
        JuliaPointer, res,
        BaseDomain, nemoF );
#T set NumberRows, NumberColumns, ...
end );


#############################################################################
##
#F  GAPMatrix( <gap_field>, <mat_of_Nemo_objects> )
##
BindGlobal( "GAPMatrix", function( gapF, nemomat )
    local ptr, m, n, d, efam, result, getindex, coeff, numerator, int,
          denom, i, ji, j, elm, coeffs, k, c;

    ptr:= JuliaPointer( nemomat );
    m:= JuliaUnbox( Julia.Nemo.rows( ptr ) );
    n:= JuliaUnbox( Julia.Nemo.cols( ptr ) );
    d:= Dimension( gapF );
    efam:= ElementsFamily( FamilyObj( gapF ) );
    result:= [];

    getindex:= Julia.Base.getindex;
    coeff:= Julia.Nemo.coeff;
    numerator:= Julia.Base.numerator;
#T need numer/denom because we cannot box/unbox rationals (yet)
    int:= JuliaFunction( "Int", "Base" );
#T note: Int is not in Julia.Base
#    int:= Julia.Base.Int;
    denom:= Julia.Base.denominator;

    for i in [ 1 .. m ] do
      result[i]:= [];
      ji:= JuliaBox( i );
      for j in [ 1 .. n ] do
        elm:= getindex( ptr, ji, j );
        coeffs:= [];
        for k in [ 1 .. d ] do
          c:= coeff( elm, k-1 );
          coeffs[k]:= JuliaUnbox( int( numerator( c ) ) ) /
                      JuliaUnbox( int( denom( c ) ) );
        od;
        result[i][j]:= AlgExtElm( efam, coeffs );
      od;
    od;

    return result;
end );

#T better use a Nemo function to extract the coefficient vectors?


##############################################################################
##
#E

#T set IsFlatMatrix?

InstallMethod( NumberRows,
    [ "IsNemoMatrixObj" ],
    nemomat -> JuliaUnbox( Julia.Nemo.rows( JuliaPointer( nemomat ) ) ) );
#T really unbox?

InstallMethod( NumberColumns,
    [ "IsNemoMatrixObj" ],
    nemomat -> JuliaUnbox( Julia.Nemo.cols( JuliaPointer( nemomat ) ) ) );

#T hier!!


InstallMethod( RankMat,
    [ "IsNemoMatrixObj" ],
    nemomat -> JuliaUnbox( Julia.Base.rank( JuliaPointer( nemomat ) ) ) );
#T RankMatDestructive?

#T [] ? (absurd for mutable matrices)
#T Position etc.?

#T ExtractSubMatrix ?

#T MutableCopyMat ?

#############################################################################
##
#O  CopySubMatrix( <src>, <dst>, <srows>, <drows>, <scols>, <dcols> )
##
##  <#GAPDoc Label="CopySubMatrix">
##  <ManSection>
##  <Oper Name="CopySubMatrix" Arg='src, dst, srows, drows, scols, dcols'/>
##
##  <Description>
##  returns nothing. Does <C><A>dst</A>{<A>drows</A>}{<A>dcols</A>} := <A>src</A>{<A>srows</A>}{<A>scols</A>}</C>
##  without creating an intermediate object and thus - at least in
##  special cases - much more efficiently. For certain objects like
##  compressed vectors this might be significantly more efficient if
##  <A>scols</A> and <A>dcols</A> are ranges with increment 1.
##  </Description>
##  </ManSection>
##  <#/GAPDoc>
##
#T DeclareOperation( "CopySubMatrix", [IsMatrixObj,IsMatrixObj,
#T                                    IsList,IsList,IsList,IsList] );

############################################################################
# New element access for matrices
############################################################################

InstallMethod( MatElm,
    [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt" ],
    function( nemomat, i, j )
      return Julia.Base.getindex( JuliaPointer( nemomat ), i, j );
    end );

InstallMethod( \[\],
    [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt" ],
    function( nemomat, i, j )
      return Julia.Base.getindex( JuliaPointer( nemomat ), i, j );
    end );

#T InstallMethod( SetMatElm,
#T     [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt", "IsObject" ],
#T     function( nemomat, i, j, obj )
#T ...
#T     end );
#T four argument []:= needed?


# DeclareOperation( "ViewObj", [IsMatrixObj] );

InstallMethod( PrintObj,
    [ "IsNemoMatrixObj" ],
    function( nemomat )
Print( "???" );
    end );
# This must produce GAP-readable input reproducing the representation.
#T how?

# DeclareAttribute( "String", IsMatrixObj );
# DeclareOperation( "String", [IsMatrixObj,IsInt] );

# DeclareOperation( "Display", [IsMatrixObj] );


############################################################################
# Arithmetical operations:
############################################################################

# The following binary arithmetical operations are possible for matrices
# over the same BaseDomain with fitting dimensions:
#    +, *, -
# The following are also allowed for different dimensions:
#    <, =
# Note1: It is not guaranteed that sorting is done lexicographically!
# Note2: If sorting is not done lexicographically then the objects
#        in that representation cannot be lists!

InstallMethod( \^,
    [ "IsNemoMatrixObj", "IsPosInt" ],
    function( nemomat, n )
    local power, type;

    power:= Julia.Base.("^")( JuliaPointer( nemomat ), n );
    type:= ElementsFamily( ElementsFamily( FamilyObj( nemomat ) ) )!.matrixType;
    return ObjectifyWithAttributes( rec(), type,
               JuliaPointer, power,
               BaseDomain, BaseDomain( nemomat ),
               NumberRows, NumberRows( nemomat ),
               NumberColumns, NumberColumns( nemomat ) );
    end );
#T check square?
#T what about 0x0 matrices?


# The following unary arithmetical operations are possible for matrices:
#    AdditiveInverseImmutable, AdditiveInverseMutable,
#    AdditiveInverseSameMutability, ZeroImmutable, ZeroMutable,
#    ZeroSameMutability, IsZero, Characteristic

InstallMethod( ZeroSameMutability,
    [ "IsNemoMatrixObj" ],
    function( nemomat )
    local zero, type;

    zero:= Julia.Base.zero( JuliaPointer( nemomat ) );
    type:= ElementsFamily( ElementsFamily( FamilyObj( nemomat ) ) )!.matrixType;
    return ObjectifyWithAttributes( rec(), type,
               JuliaPointer, zero,
               BaseDomain, BaseDomain( nemomat ),
               NumberRows, NumberRows( nemomat ),
               NumberColumns, NumberColumns( nemomat ) );
    end );


# The following unary arithmetical operations are possible for non-empty
# square matrices (inversion returns fail if not invertible):
#    OneMutable, OneImmutable, OneSameMutability,
#    InverseMutable, InverseImmutable, InverseSameMutability, IsOne,

# Problem: How about inverses of integer matrices that exist as
# elements of rationals matrix?


InstallMethod( TraceMat,
    [ "IsNemoMatrixObj" ],
    function( nemomat )
    local trace, type;

    trace:= Julia.Base.trace( JuliaPointer( nemomat ) );
    type:= ElementsFamily( ElementsFamily( FamilyObj( nemomat ) ) )!.defaultType;
    return ObjectifyWithAttributes( rec(), type, JuliaPointer, trace );
    end );


############################################################################
# Rule:
# Operations not sensibly defined return fail and do not trigger an error:
# In particular this holds for:
# One for non-square matrices.
# Inverse for non-square matrices
# Inverse for square, non-invertible matrices.
#
# An exception are properties:
# IsOne for non-square matrices returns false.
#
# To detect errors more easily:
# Matrix/vector and matrix/matrix product run into errors if not defined
# mathematically (like for example a 1x2 - matrix times itself.
############################################################################

############################################################################
# The "representation-preserving" contructor methods:
############################################################################

InstallMethod( ZeroMatrix,
    [ "IsInt", "IsInt", "IsNemoMatrixObj" ],
    function( m, n, nemomat )
    local R, zero, type;

    R:= BaseDomain( nemomat );
    zero:= Julia.Base.zero( Julia.Nemo.MatrixSpace( JuliaPointer( R ), m, n ) );
    type:= ElementsFamily( ElementsFamily( FamilyObj( nemomat ) ) )!.matrixType;
    return ObjectifyWithAttributes( rec(), type,
               JuliaPointer, zero,
               BaseDomain, R,
               NumberRows, m,
               NumberColumns, n );
    end );

InstallMethod( NewZeroMatrix,
    [ "IsNemoMatrixObj", "IsRing", "IsInt", "IsInt" ],
    function( nemomat, R, m, n )
    local zero, type;

    zero:= Julia.Base.zero( Julia.Nemo.MatrixSpace( JuliaPointer( R ), m, n ) );
    type:= ElementsFamily( FamilyObj( R ) )!.matrixType;
    return ObjectifyWithAttributes( rec(), type,
               JuliaPointer, zero,
               BaseDomain, R,
               NumberRows, m,
               NumberColumns, n );
    end );

# DeclareOperation( "IdentityMatrix", [IsInt,IsMatrixObj] );
# # Returns a new mutable identity matrix in the same rep as the given one with
# # possibly different dimensions.
# 
# DeclareConstructor( "NewIdentityMatrix", [IsMatrixObj,IsSemiring,IsInt]);
# # Returns a new fully mutable identity matrix over the base domain in the
# # 2nd argument. The integer is the number of rows and columns.
# 
# DeclareOperation( "CompanionMatrix", [IsUnivariatePolynomial,IsMatrixObj] );
# # Returns the companion matrix of the first argument in the representation
# # of the second argument. Uses row-convention. The polynomial must be
# # monic and its coefficients must lie in the BaseDomain of the matrix.
# 
# DeclareConstructor( "NewCompanionMatrix",
#   [IsMatrixObj, IsUnivariatePolynomial, IsSemiring] );
# # The constructor variant of <Ref Oper="CompanionMatrix"/>.
# 
# # The following are already declared in the library:
# # Eventually here will be the right place to do this.
# 
# DeclareOperation( "Matrix", [IsList,IsInt,IsMatrixObj]);
# # Creates a new matrix in the same representation as the fourth argument
# # but with entries from list, the second argument is the number of
# # columns. The first argument can be:
# #  - a plain list of vectors of the correct row length in a representation
# #          fitting to the matrix rep.
# #  - a plain list of plain lists where each sublist has the length of the rows
# #  - a plain list with length rows*cols with matrix entries given row-wise
# # If the first argument is empty, then the number of rows is zero.
# # Otherwise the first entry decides which case is given.
# # The outer list is guaranteed to be copied, however, the entries of that
# # list (the rows) need not be copied.
# # The following convenience versions exist:
# # With two arguments the first must not be empty and must not be a flat
# # list. Then the number of rows is deduced from the length of the first
# # argument and the number of columns is deduced from the length of the
# # element of the first argument (done with a generic method):
# DeclareOperation( "Matrix", [IsList,IsMatrixObj] );
# 
# # Note that it is not possible to generate a matrix via "Matrix" without
# # a template matrix object. Use the constructor methods instead:
# 
# InstallMethod( NewMatrix,
#     [ IsNemoMatrixObj, IsRing, IsInt, IsList ],
#     function( filter, R, n, rows )
# ...
#     end );
# 
# DeclareConstructor( "NewMatrix", [IsMatrixObj, IsSemiring, IsInt, IsList] );
# # Constructs a new fully mutable matrix. The first argument has to be a filter
# # indicating the representation. The second the base domain, the third
# # the row length and the last a list containing either row vectors
# # of the right length or lists with base domain elements.
# # The last argument is guaranteed not to be changed!
# # If the last argument already contains row vectors, they are copied.
# 
# DeclareOperation( "ConstructingFilter", [IsMatrixObj] );
# 
# DeclareOperation( "CompatibleVector", [IsMatrixObj] );
# 
# DeclareOperation( "ChangedBaseDomain", [IsMatrixObj,IsSemiring] );
# # Changes the base domain. A copy of the matrix in the first argument is
# # created, which comes in a "similar" representation but over the new
# # base domain that is given in the second argument.
# 
# DeclareGlobalFunction( "MakeMatrix" );
# # A convenience function for users to choose some appropriate representation
# # and guess the base domain if not supplied as second argument.
# # This is not guaranteed to be efficient and should never be used
# # in library or package code.
# 
# 
# ############################################################################
# # Some things that fit nowhere else:
# ############################################################################
# 
# DeclareOperation( "Randomize", [IsMatrixObj and IsMutable] );
# DeclareOperation( "Randomize", [IsMatrixObj and IsMutable,IsRandomSource] );
# # Changes the mutable argument in place, every entry is replaced
# # by a random element from BaseDomain.
# # The second version will come when we have random sources.
# 
# DeclareAttribute( "TransposedMatImmutable", IsMatrixObj );
# DeclareOperation( "TransposedMatMutable", [IsMatrixObj] );
# 
# DeclareOperation( "IsDiagonalMat", [IsMatrixObj] );
# 
# DeclareOperation( "IsUpperTriangularMat", [IsMatrixObj] );
# DeclareOperation( "IsLowerTriangularMat", [IsMatrixObj] );
# 
# DeclareOperation( "KroneckerProduct", [IsMatrixObj,IsMatrixObj] );
# # The result is fully mutable.
# 
# DeclareOperation( "Unfold", [IsMatrixObj, IsVectorObj] );
# # Concatenates all rows of a matrix to one single vector in the same
# # representation as the given template vector. Usually this must
# # be compatible with the representation of the matrix given.
# DeclareOperation( "Fold", [IsVectorObj, IsPosInt, IsMatrixObj] );
# # Cuts the row vector into pieces of length the second argument
# # and forms a matrix out of the pieces in the same representation
# # as the third argument. The length of the vector must be a multiple
# # of the second argument.
# 
# 
# ############################################################################
# # Arithmetic involving vectors and matrices:
# ############################################################################
# 
# # DeclareOperation( "*", [IsVectorObj, IsMatrixObj] );
# 
# # DeclareOperation( "^", [IsVectorObj, IsMatrixObj] );


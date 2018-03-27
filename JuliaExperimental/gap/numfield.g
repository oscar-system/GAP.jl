##############################################################################
##
##  numfield.g
##
##  This is an experimental interface to Nemo's elements of number fields.
##

#T as soon as Nemo/Hecke's QabElem objects are available,
#T provide a conversion of single GAP cyclotomics


#############################################################################
##
#F  JuliaTypeInfo( <juliaobj> )
##
##  the string that describes the julia type
##
JuliaTypeInfo:= juliaobj -> JuliaUnbox( Julia.Base.string(
                                Julia.Core.typeof( juliaobj ) ) );
#T move this to a more central place (``utilities'')?


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaInterface", "julia" ),
    "numfield.jl" ) );

ImportJuliaModuleIntoGAP( "Core" );
ImportJuliaModuleIntoGAP( "Base" );
ImportJuliaModuleIntoGAP( "Nemo" );
ImportJuliaModuleIntoGAP( "GAPNumberFields" );


#############################################################################
##
##  Declare filters.
##
DeclareAttribute( "JuliaPointer", IsObject );

DeclareCategory( "IsNemoObject", IsObject );

DeclareSynonym( "IsNemoPolynomialRing",
    IsNemoObject and IsUnivariatePolynomialRing );
DeclareSynonym( "IsNemoField", IsNemoObject and IsField );
DeclareSynonym( "IsNemoNumberField", IsNemoField and IsNumberField );
DeclareSynonym( "IsNemoFieldElement", IsNemoObject and IsScalar );


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

BindGlobal( "Nemo_QQ", Objectify(
    NewType( CollectionsFamily( NewFamily( "Nemo_QQ_ElementsFamily" ) ),
             IsAttributeStoringRep and IsField and IsPrimeField ),
    rec() ) );

SetName( Nemo_QQ, "Nemo_QQ" );
SetLeftActingDomain( Nemo_QQ, Nemo_QQ );
SetSize( Nemo_QQ, infinity );
SetJuliaPointer( Nemo_QQ, Julia.Nemo.QQ );


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
##  <R> is the Nemo polynomial ring,
##  <descr> is a GAP list of coefficients.
##
BindGlobal( "Nemo_Polynomial", function( R, descr )
    local pol, aux, result;

    if not IsNemoPolynomialRing( R ) then
      Error( "<R> must be a Nemo polynomial ring" );
    fi;

    if Length( descr ) = 0 then
      return Zero( R );
    fi;

    if ForAll( descr, IsInt ) then
#     descr:= List( descr, JuliaBox );
      descr:= JuliaBox( [ descr ] );
    elif ForAll( descr, IsRat ) then
#T missing from 'JuliaBox'
      descr:= List( descr,
                    x -> JuliaEvalString( Concatenation( "fmpq(",
                             String( NumeratorRat( x ) ), "//",
                             String( DenominatorRat( x ) ), ")" ) ) );
Error("not yet!");
    fi;

    aux:= Julia.GAPNumberFields.MatrixFromNestedArray( descr );
    aux:= Julia.Base.vec( aux );
    Julia.Base.( "setindex!" )( descr, aux, 1 );
    pol:= Julia.Core._apply( JuliaPointer( R ), descr );

    result:= rec();
#T would be simpler if ObjectifyWithAttributes would return the object
    ObjectifyWithAttributes( result,
        ElementsFamily( FamilyObj( R ) )!.defaultPolynomialType,
        JuliaPointer, pol );

    return result;
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

    gen:= rec();
#T would be simpler if ObjectifyWithAttributes would return the object
    ObjectifyWithAttributes( gen, efam!.defaultType,
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
#T would be simpler if ObjectifyWithAttributes would return the object
    if IsDomain( template ) then
      type:= ElementsFamily( FamilyObj( template ) )!.defaultType;
    else
      type:= FamilyObj( template )!.defaultType;
    fi;
    result:= rec();
    ObjectifyWithAttributes( result, type, JuliaPointer, jpointer );
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
BindGlobal( "NemoMatrix", function( nemoF, gapmat )
    local m, n, coeffs, d, res, obj;

    # Remember the dimensions.
    m:= Length( gapmat );
    n:= Length( gapmat[1] );

    # Extract the coefficient vectors.
    coeffs:= List( Concatenation( gapmat ), ExtRepOfObj );

    # Compute the common denominator.
    d:= Lcm( List( Concatenation( coeffs ), DenominatorRat ) );
    coeffs:= coeffs * d;

    # Convert the list of integral coefficient vectors
    # to a suitable matrix in Julia (Nemo.fmpz_mat).
    res:= Julia.GAPNumberFields.MatrixFromNestedArray( coeffs );
# The following does not work in Nemo 0.6.0 but works in Nemo 0.7.3 ...
    res:= Julia.Nemo.matrix( Julia.Nemo.ZZ, res );

    # Call the Julia function.
    res:= Julia.GAPNumberFields.Nemo_Matrix_over_NumberField(
              JuliaPointer( nemoF ), m, n, res, d );
#T wrap this into IsNemoObject?

    obj:= rec();
    ObjectifyWithAttributes( obj,
        ElementsFamily( FamilyObj( nemoF ) )!.matrixType, JuliaPointer, res );

    return obj;
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
    int:= Julia.Base.Int;
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


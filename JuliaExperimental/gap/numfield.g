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


#############################################################################
##
#M  ContextGAPNemo( Integers )
##
##  On the Nemo side, we have <C>Julia.Nemo.ZZ</C>.
##
InstallMethod( ContextGAPNemo,
    [ "IsRing and IsIntegers and IsAttributeStoringRep" ],
    function( R )
    local m, juliaRing, efam, collfam, gen, type;

    # No check of the ring is necessary.

    # Create the Nemo ring.
    juliaRing:= Julia.Nemo.ZZ;

    # Create the GAP wrappers.
    # Create a new family.
    efam:= NewFamily( "Nemo_ZZ_ElementsFamily", IsObject,
               IsNemoObject and IsScalar );
    SetIsUFDFamily( efam, true );
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsNemoRingElement and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsNemoObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoRingElement and IsAttributeStoringRep );

    gen:= ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 1 ) );

    SetZero( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 0 ) ) );
    SetOne( efam, gen );

    type:= IsNemoRing and IsAttributeStoringRep and
           IsCommutative and IsAssociative;

    return NewContextGAPNemo( rec(
      Name:= "<context for Integers>",

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, infinity,
                      Name, "Nemo_ZZ" ),

      ElementType:= efam!.elementType,

      ElementGAPToNemo:= function( C, obj )
        if IsInt( obj ) then
          return Julia.Nemo.fmpz( GAPToJulia( obj ) );
        else
          Error( "<obj> must be an integer" );
        fi;
      end,

      ElementNemoToGAP:= function( C, obj )
        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
        return FmpzToGAP( obj );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToNemo:= function( C, vec )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                 Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                   GAPToJulia( [ vec ] ) ) );
      end,

      VectorNemoToGAP:= function( C, mat )
        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        return GAPMatrix_fmpz_mat( mat )[1];
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToNemo:= function( C, mat )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                 Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                   GAPToJulia( mat ) ) );
      end,

      MatrixNemoToGAP:= function( C, mat )
        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        return GAPMatrix_fmpz_mat( mat );
      end,
    ) );
    end );


#############################################################################
##
#M  ContextGAPNemo( Rationals )
##
##  On the Nemo side, we have <C>Julia.Nemo.QQ</C>.
##
InstallMethod( ContextGAPNemo,
    [ "IsRing and IsRationals and IsAttributeStoringRep" ],
    function( R )
    local m, juliaRing, efam, collfam, gen, type;

    # No check of the ring is necessary.

    # Create the Nemo ring.
    juliaRing:= Julia.Nemo.QQ;

    # Create the GAP wrappers.
    # Create a new family.
    efam:= NewFamily( "Nemo_QQ_ElementsFamily", IsNemoObject, IsScalar );
    SetIsUFDFamily( efam, true );
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsNemoFieldElement and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsNemoObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoRingElement and IsAttributeStoringRep );

    gen:= ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 1 ) );

    SetZero( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 0 ) ) );
    SetOne( efam, gen );

    type:= IsNemoField and IsAttributeStoringRep and
           IsCommutative and IsAssociative;

    return NewContextGAPNemo( rec(
      Name:= "<context for Rationals>",

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, infinity,
                      Name, "Nemo_QQ" ),

      ElementType:= efam!.elementType,

      ElementGAPToNemo:= function( C, obj )
        return Julia.Nemo.fmpq(
            Julia.Base.\/\/( NumeratorRat( obj ), DenominatorRat( obj ) ) );
      end,

      ElementNemoToGAP:= function( C, obj )
        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
        return FmpzToGAP( Julia.Base.numerator( obj ) ) /
               FmpzToGAP( Julia.Base.denominator( obj ) );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToNemo:= function( C, vec )
        return NemoMatrix_fmpq( [ vec ] );
      end,

      VectorNemoToGAP:= function( C, vec )
        local result, j, entry;

        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        result:= [];
        for j in [ 1 .. Julia.Nemo.cols( vec ) ] do
          entry:= vec[ 1, j ];
          result[j]:= FmpzToGAP( Julia.Base.numerator( entry ) ) /
                      FmpzToGAP( Julia.Base.denominator( entry ) );
        od;

        return result;
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToNemo:= function( C, mat )
        return NemoMatrix_fmpq( mat );
      end,

      MatrixNemoToGAP:= function( C, mat )
        local n, result, i, row, j, entry;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Nemo.cols( mat );
        result:= [];
        for i in [ 1 .. Julia.Nemo.rows( mat ) ] do
          row:= [];
          for j in [ 1 .. n ] do
            entry:= mat[ i, j ];
            row[j]:= FmpzToGAP( Julia.Base.numerator( entry ) ) /
                     FmpzToGAP( Julia.Base.denominator( entry ) );
          od;
          result[i]:= row;
        od;

        return result;
      end,
    ) );
    end );


#############################################################################
##
#M  ContextGAPNemo( PolynomialRing( R, n ) )
##
##  On the Nemo side, we have <C>Julia.Nemo.PolynomialRing( ... )</C>.
##
InstallMethod( ContextGAPNemo,
    [ "IsPolynomialRing and IsAttributeStoringRep" ],
    function( R )
    local F, FContext, indetnames, names, juliaRing, efam, collfam, indets,
          type;

    # No check of the ring is necessary.
    F:= LeftActingDomain( R );
    FContext:= ContextGAPNemo( F );
    indetnames:= List( IndeterminatesOfPolynomialRing( R ), String );
    if Length( indetnames ) = 1 then
      names:= GAPToJulia( indetnames[1] );
    else
      names:= Julia.Base.convert( JuliaEvalString( "Array{String,1}" ),
                                  GAPToJulia( indetnames ) );
    fi;

    # Create the Nemo ring.
    juliaRing:= Julia.Nemo.PolynomialRing( FContext!.JuliaDomainPointer,
                                           names );

    # Create the GAP wrappers.
    # Create a new family.
    # Note that elements from two Nemo polynomial rings cannot be compared,
    efam:= NewFamily( "Nemo_PolynomialsFamily", IsNemoObject, IsScalar );
#   SetIsUFDFamily( efam, true );
#T ?
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsNemoPolynomial and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsNemoObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoRingElement and IsAttributeStoringRep );

    # Store the GAP list of wrapped Julia indeterminates.
    if Length( indetnames ) = 1 then
      # univariate case
      indets:= [ juliaRing[2] ];
    else
      # multivariate case
      indets:= JuliaToGAP( IsList, juliaRing[2] );
    fi;
    indets:= List( indets,
                   x -> ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, x ) );

    SetZero( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing[1]( 0 ) ) );
    SetOne( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing[1]( 1 ) ) );
    type:= IsNemoPolynomialRing and IsAttributeStoringRep and IsFreeLeftModule
           and IsFLMLORWithOne
           and HasIsFinite and HasIsFiniteDimensional;
    if HasIsField( F ) and IsField( F ) then
      type:= type and IsAlgebraWithOne;
    fi;
    if HasIsAssociative( F ) and IsAssociative( F ) then
      type:= type and IsAssociative;
    fi;
    if HasIsCommutative( F ) and IsCommutative( F ) then
      type:= type and IsCommutative;
    fi;
    if Length( indets ) = 1 then
      type:= type and IsUnivariatePolynomialRing;
    fi;
    if IsRationals( F ) and Length( indets ) = 1 then
      type:= type and IsEuclideanRing and IsRationalsPolynomialRing;
    fi;

    return NewContextGAPNemo( rec(
      Name:= Concatenation( "<context for pol. ring over ", String( F ),
                            ", with ", String( Length( indets ) ),
                            " indeterminates>" ),

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing[1],
                      LeftActingDomain, FContext!.JuliaDomain,
                      CoefficientsRing, FContext!.JuliaDomain,
                      IndeterminatesOfPolynomialRing, indets,
                      GeneratorsOfLeftOperatorRingWithOne, indets,
                      Size, infinity,
                      Name, "Nemo_PolynomialRing" ),

      ElementType:= efam!.elementType,

      ElementGAPToNemo:= function( C, obj )
        local FContext, pol, len, coeffs, monoms;

        FContext:= ContextGAPNemo( LeftActingDomain( C!.GAPDomain ) );

        if IsUnivariatePolynomialRing( C!.GAPDomain ) then
          if IsPolynomial( obj ) then
            obj:= CoefficientsOfUnivariatePolynomial( obj );
          fi;
          obj:= GAPToNemo( FContext, obj );
#T this yields "Nemo.fmpq_mat",
#T but I need "Array{Nemo.fmpq,1}" ...
          obj:= Julia.GAPNumberFields.VectorToArray( JuliaPointer( obj ) );

          pol:= C!.JuliaDomainPointer( obj );
        else
          if IsPolynomial( obj ) then
            obj:= ExtRepPolynomialRatFun( obj );
          fi;
          len:= Length( obj );
          coeffs:= GAPToNemo( FContext, obj{ [ 2, 4 .. len ] } );
          monoms:= Julia.Base.convert(
                     JuliaEvalString( "Array{Array{UInt,1},1}" ),
                     GAPToJulia( TransposedMat( obj{ [ 1, 3 .. len-1 ] } ) ) );
          pol:= C!.JuliaDomainPointer( coeffs, monoms );
        fi;

        return pol;
      end,

      ElementNemoToGAP:= function( C, obj )
        local descr;

        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
        descr:= GAPDescriptionOfNemoPolynomial( C, obj );
        if IsUnivariatePolynomialRing( C!.GAPDomain ) then
          return UnivariatePolynomialByCoefficients( 
                     ElementsFamily( FamilyObj( LeftActingDomain( C!.GAPDomain ) ) ), descr,
                     IndeterminateNumberOfUnivariateRationalFunction(
                       IndeterminatesOfPolynomialRing( C!.GAPDomain )[1] ) );
        else
          return PolynomialByExtRep(
# NC?
                     ElementsFamily( FamilyObj( LeftActingDomain( C!.GAPDomain ) ) ), descr );
        fi;
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToNemo:= function( C, vec )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer, 1, Length( vec ),
                   GAPToJulia( List( vec, x -> C!.ElementGAPToNemo( C, x ) ) ) );
      end,

      VectorNemoToGAP:= function( C, vec )
        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        return List( [ 1 .. Julia.Nemo.cols( vec ) ],
                     j -> C!.ElementNemoToGAP( C, vec[ 1, j ] ) );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToNemo:= function( C, mat )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                   NumberRows( mat ), NumberColumns( mat ),
                   GAPToJulia( List( Concatenation( mat ),
                                     x -> C!.ElementGAPToNemo( C, x ) ) ) );
      end,

      MatrixNemoToGAP:= function( C, mat )
        local n;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Nemo.cols( mat );
        return List( [ 1 .. Julia.Nemo.rows( mat ) ],
                     i -> List( [ 1 .. n ],
                                j -> C!.ElementNemoToGAP( C, mat[ i, j ] ) ) );
      end,
    ) );
    end );


#############################################################################
##
#M  ContextGAPNemo( AlgebraicExtension( Q, pol ) )
##
##  On the Nemo side, we have <C>Julia.Nemo....</C>.
##
InstallMethod( ContextGAPNemo,
    [ "IsField and IsAlgebraicExtension and IsAttributeStoringRep" ],
    function( R )
    local F, FContext, pol, PContext, coeffs, name, npol, juliaRing, efam,
          collfam, gen, type;

    # No check of the ring is necessary.
    F:= LeftActingDomain( R );
    FContext:= ContextGAPNemo( F );
    pol:= DefiningPolynomial( R );
    PContext:= ContextGAPNemo( PolynomialRing( F,
        [ IndeterminateNumberOfUnivariateRationalFunction(
              IndeterminateOfUnivariateRationalFunction( pol ) ) ] ) );
    coeffs:= CoefficientsOfUnivariatePolynomial( pol );
    if Length( coeffs ) < 3 then
      Error( "need a polynomial of degree at least 2" );
    fi;
    name:= GAPToJulia( ElementsFamily( FamilyObj( R ) )!.indeterminateName );

    # Create the Nemo ring.
    npol:= GAPToNemo( PContext, pol );
    juliaRing:= Julia.Nemo.NumberField( JuliaPointer( npol ), name );

    # Create the GAP wrappers.
    # Create a new family.
    # Note that elements from two NEMO field extensions cannot be compared.
    # (This is the same as in GAP's 'AlgebraicExtension'.)
    efam:= NewFamily( "Nemo_FieldElementsFamily", IsNemoFieldElement, IsScalar );
    SetIsUFDFamily( efam, true );
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsNemoFieldElement and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsNemoObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoRingElement and IsAttributeStoringRep );

    SetZero( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing[1]( 0 ) ) );
    SetOne( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing[1]( 1 ) ) );
    gen:= ObjectifyWithAttributes( rec(),
                    efam!.elementType,
                    JuliaPointer, juliaRing[2] );

    type:= IsNemoField and IsAttributeStoringRep and IsFiniteDimensional;
#T also IsFinite value
#T set also 'IsNumberField' etc., depending on the situation

    return NewContextGAPNemo( rec(
      Name:= Concatenation( "<context for alg. ext. field over ", String( F ),
                            ", w.r.t. polynomial ", String( pol ), ">" ),

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing[1],
                      DefiningPolynomial, npol,
                      Characteristic, Characteristic( R ),
                      LeftActingDomain, FContext!.JuliaDomain,
                      GeneratorsOfField, [ gen ],
                      PrimitiveElement, gen,
                      RootOfDefiningPolynomial, gen ),

      ElementType:= efam!.elementType,

      ElementGAPToNemo:= function( C, obj )
        local coeffs, d, res;

        # Compute the common denominator.
        coeffs:= ExtRepOfObj( obj );
        d:= Lcm( List( coeffs, DenominatorRat ) );
#T TODO: here we assume that we are over Q, fix this
        coeffs:= coeffs * d;

        # Convert the list of integral coefficient vectors
        # to a suitable matrix in Julia (Nemo.fmpz_mat).
        res:= Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                  GAPToJulia( [ coeffs ] ) );
        res:= Julia.Nemo.matrix( Julia.Nemo.ZZ, res );

        # Call the Julia function.
        return Julia.GAPNumberFields.NemoElementOfNumberField(
                   C!.JuliaDomainPointer, res, d );
      end,

      ElementNemoToGAP:= function( C, obj )
        local numden, convert, num, den, coeffs;

        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;


        numden:= Julia.GAPNumberFields.CoefficientVectorsNumDenOfNumberFieldElement(
                     obj, Dimension( C!.GAPDomain ) );

        convert:= Julia.Base.convert;
        num:= JuliaToGAP( IsList,
              convert( JuliaEvalString( "Array{Int,1}" ), numden[1] ), true );
        den:= JuliaToGAP( IsList,
              convert( JuliaEvalString( "Array{Int,1}" ), numden[2] ), true );
        coeffs:= List( [ 1 .. Length( num ) ], i -> num[i] / den[i] );

        return AlgExtElm( ElementsFamily( FamilyObj( C!.GAPDomain ) ), coeffs );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToNemo:= function( C, vec )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer, 1, Length( vec ),
                   GAPToJulia( List( vec, x -> C!.ElementGAPToNemo( C, x ) ) ) );
      end,

      VectorNemoToGAP:= function( C, vec )
        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        return List( [ 1 .. Julia.Nemo.cols( vec ) ],
                     j -> C!.ElementNemoToGAP( C, vec[ 1, j ] ) );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToNemo:= function( C, mat )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                   NumberRows( mat ), NumberColumns( mat ),
                   GAPToJulia( List( Concatenation( mat ),
                                     x -> C!.ElementGAPToNemo( C, x ) ) ) );
      end,

      MatrixNemoToGAP:= function( C, mat )
        local n;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Nemo.cols( mat );
        return List( [ 1 .. Julia.Nemo.rows( mat ) ],
                     i -> List( [ 1 .. n ],
                                j -> C!.ElementNemoToGAP( C, mat[ i, j ] ) ) );
      end,
    ) );
    end );


#############################################################################
##
#F  NemoElement( <template>, <jpointer> )
##
##  is used to wrap field elements, matrices, ...
##
BindGlobal( "NemoElement", function( template, jpointer )
    local type, result;

    if IsDomain( template ) then
#T needed?
      type:= ContextGAPNemo( FamilyObj( template ) )!.ElementType;
    elif IsVectorObj( template ) then
      type:= ContextGAPNemo( FamilyObj( template ) )!.VectorType;
    elif IsMatrixObj( template ) then
      type:= ContextGAPNemo( FamilyObj( template ) )!.MatrixType;
    else
      type:= ContextGAPNemo( FamilyObj( template ) )!.ElementType;
    fi;

    result:= ObjectifyWithAttributes( rec(), type, JuliaPointer, jpointer );
    if HasParent( template ) then
      SetParent( result, Parent( template ) );
    fi;

    return result;
end );


#T beat GAP's 'IsPolynomial' methods
NEMO_RANK_SHIFT:= 100;


#############################################################################
##
##  methods for Nemo's polynomials
##
InstallMethod( String,
    [ "IsNemoObject and HasJuliaPointer" ], 100,
    nemo_obj -> String( JuliaPointer( nemo_obj ) ) );

InstallMethod( PrintObj,
    [ "IsNemoObject and HasJuliaPointer" ], 100,
    function( nemo_obj )
    Print( PrintString( nemo_obj ) );
    end );


#############################################################################
##
##  methods for Nemo's polynomial rings and fields
##
InstallOtherMethod( Zero, [ IsNemoObject ], 200,
    F -> NemoElement( F, Julia.Base.zero( Julia.Base.parent( JuliaPointer( F ) ) ) ) );

InstallOtherMethod( One, [ IsNemoObject ], 200,
    F -> NemoElement( F, Julia.Base.one( Julia.Base.parent( JuliaPointer( F ) ) ) ) );

InstallMethod( RootOfDefiningPolynomial, [ IsNemoField ],
    F -> NemoElement( F, Julia.Nemo.gen( JuliaPointer( F ) ) ) );


#############################################################################
##
##  methods for field elements
##
InstallOtherMethod( ViewString, [ "IsNemoObject" ],
    x -> Concatenation( "<", ViewString( JuliaPointer( x ) ), ">" ) );

InstallOtherMethod( \=, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return Julia.Base.\=\=( JuliaPointer( x ), JuliaPointer( y ) );
    end );

InstallOtherMethod( \+, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x,
                 Julia.Base.\+( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \+, [ "IsNemoObject", "IsInt" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x,
                 Julia.Base.\+( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( AdditiveInverse, [ "IsNemoObject" ], NEMO_RANK_SHIFT,
    x -> NemoElement( x, Julia.Base.\-( JuliaPointer( x ) ) ) );

InstallOtherMethod( \-, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x,
                 Julia.Base.\-( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \*, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x,
                 Julia.Base.\*( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \/, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x, Julia.Nemo.divexact(
                     JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \^, [ "IsNemoObject", "IsPosInt" ], NEMO_RANK_SHIFT,
    function( x, n )
      return NemoElement( x, Julia.Base.\^( JuliaPointer( x ), n ) );
    end );


InstallMethod( NumberRows,
    [ "IsNemoMatrixObj" ],
    nemomat -> Julia.Nemo.rows( JuliaPointer( nemomat ) ) );

InstallMethod( NumberColumns,
    [ "IsNemoMatrixObj" ],
    nemomat -> Julia.Nemo.cols( JuliaPointer( nemomat ) ) );

InstallMethod( RankMat,
    [ "IsNemoMatrixObj" ],
    nemomat -> Julia.Base.rank( JuliaPointer( nemomat ) ) );
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
      return JuliaPointer( nemomat )[ i, j ];
    end );

InstallMethod( \[\],
    [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt" ],
    function( nemomat, i, j )
      return JuliaPointer( nemomat )[ i, j ];
    end );

#T InstallMethod( SetMatElm,
#T     [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt", "IsObject" ],
#T     function( nemomat, i, j, obj )
#T ...
#T     end );
#T four argument []:= needed?


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
    [ "IsNemoMatrixObj", "IsPosInt" ], NEMO_RANK_SHIFT,
                                       # beat the generic method
    function( nemomat, n )
    local power, type;

    power:= Julia.Base.\^( JuliaPointer( nemomat ), n );
    type:= ContextGAPNemo( FamilyObj( nemomat ) )!.MatrixType;
    return ObjectifyWithAttributes( rec(), type,
               JuliaPointer, power,
               BaseDomain, BaseDomain( nemomat ),
               NumberRows, NumberRows( nemomat ),
               NumberColumns, NumberColumns( nemomat ) );
    end );


# The following unary arithmetical operations are possible for matrices:
#    AdditiveInverseImmutable, AdditiveInverseMutable,
#    AdditiveInverseSameMutability, ZeroImmutable, ZeroMutable,
#    ZeroSameMutability, IsZero, Characteristic

InstallMethod( ZeroSameMutability,
    [ "IsNemoMatrixObj" ],
    function( nemomat )
    local zero, type;

    zero:= Julia.Base.zero( JuliaPointer( nemomat ) );
    type:= ContextGAPNemo( FamilyObj( nemomat ) )!.MatrixType;
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

InstallOtherMethod( OneMutable,
     [ "IsNemoMatrixObj" ], NEMO_RANK_SHIFT,
     x -> NemoElement( x, Julia.Base.one( JuliaPointer( x ) ) ) );

InstallOtherMethod( InverseMutable,
     [ "IsNemoMatrixObj" ], NEMO_RANK_SHIFT,
#    x -> NemoElement( x, Julia.Base.inv( JuliaPointer( x ) ) ) );
     function( x )
     local ptr, res, modulus, m, s, arr, i, j, entry;

     ptr:= JuliaPointer( x );
     res:= CallJuliaFunctionWithCatch( Julia.Base.inv, [ ptr ] );
     if res.ok then
       res:= res.value;
     elif JuliaTypeInfo( ptr ) <> "Nemo.nmod_mat" then
       Error( "matrix <x> is not invertible" );
     else
       # Perhaps the object is invertible:
       # Take a preimage over the integers, invert over the rationals,
       # compute the reductions of the entries (numerators and denominators).
       modulus:= Julia.Nemo.fmpz( Size( ContextGAPNemo( FamilyObj( x ) )!.GAPDomain ) );
       res:= Julia.Nemo.lift( JuliaPointer( x ) );
       m:= NumberRows( x );
#T note that res:= Julia.Nemo.matrix( Julia.Nemo.QQ, m, m, res ); does not work!
       s:= Julia.Nemo.MatrixSpace( Julia.Nemo.QQ, m, m );
       res:= s( res );
       res:= Julia.Base.inv( res );
       arr:= [];
       for i in [ 1 .. m ] do
         for j in [ 1 .. m ] do
           entry:= res[i,j];
           Add( arr, Julia.Nemo.numerator( entry )
                     * Julia.Base.invmod( Julia.Nemo.denominator( entry ), modulus ) );
         od;
       od;
       arr:= Julia.Base.convert( JuliaEvalString( "Array{Nemo.fmpz,1}" ),
                                 GAPToJulia( arr ) );
       res:= Julia.Nemo.parent( ptr )( arr );
     fi;
     return NemoElement( x, res );
     end );

InstallMethod( TraceMat,
    [ "IsNemoMatrixObj" ],
    nemomat -> ObjectifyWithAttributes( rec(),
        ContextGAPNemo( FamilyObj( nemomat ) )!.ElementType,
        JuliaPointer, Julia.LinearAlgebra.tr( JuliaPointer( nemomat ) ) ) );

InstallOtherMethod( DeterminantMat,
    [ "IsNemoMatrixObj" ],
    nemomat -> ObjectifyWithAttributes( rec(),
        ContextGAPNemo( FamilyObj( nemomat ) )!.ElementType,
        JuliaPointer, Julia.Nemo.det( JuliaPointer( nemomat ) ) ) );


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
    type:= ContextGAPNemo( FamilyObj( nemomat ) )!.MatrixType;
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
    type:= ContextGAPNemo( FamilyObj( R ) )!.MatrixType;
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


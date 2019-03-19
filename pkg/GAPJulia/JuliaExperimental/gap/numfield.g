##############################################################################
##
##  numfield.g
##
##  experimental interface to Nemo's elements of number fields
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

    return NewContextGAPJulia( "Nemo", rec(
      Name:= "<context for Integers>",

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, infinity,
                      Name, "Nemo_ZZ" ),

      ElementType:= efam!.elementType,

      ElementGAPToJulia:= function( C, obj )
        if IsInt( obj ) then
          return Julia.Nemo.fmpz( GAPToJulia( obj ) );
        else
          Error( "<obj> must be an integer" );
        fi;
      end,

      ElementJuliaToGAP:= function( C, obj )
        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
        return FmpzToGAP( obj );
      end,

      ElementWrapped:= function( C, obj )
        return ObjectifyWithAttributes( rec(), C!.ElementType,
                   JuliaPointer,  obj );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToJulia:= function( C, vec )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                 Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                   GAPToJulia( [ vec ] ) ) );
      end,

      VectorJuliaToGAP:= function( C, mat )
        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        return GAPMatrix_fmpz_mat( mat )[1];
      end,

      VectorWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.VectorType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToJulia:= function( C, mat )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                 Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                   GAPToJulia( mat ) ) );
      end,

      MatrixJuliaToGAP:= function( C, mat )
        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        return GAPMatrix_fmpz_mat( mat );
      end,

      MatrixWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.MatrixType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
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

    return NewContextGAPJulia( "Nemo", rec(
      Name:= "<context for Rationals>",

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, infinity,
                      Name, "Nemo_QQ" ),

      ElementType:= efam!.elementType,

      ElementGAPToJulia:= function( C, obj )
        return Julia.Nemo.fmpq(
            Julia.Base.\/\/( NumeratorRat( obj ), DenominatorRat( obj ) ) );
      end,

      ElementJuliaToGAP:= function( C, obj )
        return FmpzToGAP( Julia.Base.numerator( obj ) ) /
               FmpzToGAP( Julia.Base.denominator( obj ) );
      end,

      ElementWrapped:= function( C, obj )
        return ObjectifyWithAttributes( rec(), C!.ElementType,
                   JuliaPointer,  obj );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToJulia:= function( C, vec )
        return NemoMatrix_fmpq( [ vec ] );
      end,

      VectorJuliaToGAP:= function( C, vec )
        local result, j, entry;

        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        result:= [];
        for j in [ 1 .. Julia.Nemo.ncols( vec ) ] do
          entry:= vec[ 1, j ];
          result[j]:= FmpzToGAP( Julia.Base.numerator( entry ) ) /
                      FmpzToGAP( Julia.Base.denominator( entry ) );
        od;

        return result;
      end,

      VectorWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.VectorType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToJulia:= function( C, mat )
        return NemoMatrix_fmpq( mat );
      end,

      MatrixJuliaToGAP:= function( C, mat )
        local n, result, i, row, j, entry;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Nemo.ncols( mat );
        result:= [];
        for i in [ 1 .. Julia.Nemo.nrows( mat ) ] do
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

      MatrixWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.MatrixType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
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
#T useful?
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

    return NewContextGAPJulia( "Nemo", rec(
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

      ElementGAPToJulia:= function( C, obj )
        local FContext, pol, len, coeffs, n, monoms;

        FContext:= ContextGAPNemo( LeftActingDomain( C!.GAPDomain ) );

        if IsUnivariatePolynomialRing( C!.GAPDomain ) then
          if IsPolynomial( obj ) then
            obj:= CoefficientsOfUnivariatePolynomial( obj );
          fi;
          obj:= GAPToNemo( FContext, obj );
          # This yields 'Nemo.fmpq_mat', but we need 'Array{Nemo.fmpq,1}'.
          obj:= Julia.GAPNumberFields.VectorToArray( obj );
          pol:= C!.JuliaDomainPointer( obj );
        else
          if IsPolynomial( obj ) then
            obj:= ExtRepPolynomialRatFun( obj );
          fi;
          len:= Length( obj );
          if len = 0 then
            pol:= Julia.Base.zero( C!.JuliaDomain );
          else
            coeffs:= GAPToNemo( FContext, obj{ [ 2, 4 .. len ] } );
            coeffs:= Julia.GAPNumberFields.VectorToArray( coeffs );
            n:= Length( indets );
            monoms:= GAPToJulia( JuliaEvalString( "Array{Array{UInt,1},1}" ),
                         List( obj{ [ 1, 3 .. len-1 ] },
                               w -> ExponentVectorFromWord( w, n ) ) );
            pol:= C!.JuliaDomainPointer( coeffs, monoms );
          fi;
        fi;

        return pol;
      end,

      ElementJuliaToGAP:= function( C, obj )
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
#T add NC variant?
                     ElementsFamily( FamilyObj( ( C!.GAPDomain ) ) ), descr );
        fi;
      end,

      ElementWrapped:= function( C, obj )
        return ObjectifyWithAttributes( rec(), C!.ElementType,
                   JuliaPointer,  obj );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToJulia:= function( C, vec )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer, 1, Length( vec ),
                   GAPToJulia( List( vec, x -> C!.ElementGAPToJulia( C, x ) ) ) );
      end,

      VectorJuliaToGAP:= function( C, vec )
        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        return List( [ 1 .. Julia.Nemo.ncols( vec ) ],
                     j -> C!.ElementJuliaToGAP( C, vec[ 1, j ] ) );
      end,

      VectorWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.VectorType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToJulia:= function( C, mat )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                   NumberRows( mat ), NumberColumns( mat ),
                   GAPToJulia( List( Concatenation( mat ),
                                     x -> C!.ElementGAPToJulia( C, x ) ) ) );
      end,

      MatrixJuliaToGAP:= function( C, mat )
        local n;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Nemo.ncols( mat );
        return List( [ 1 .. Julia.Nemo.nrows( mat ) ],
                     i -> List( [ 1 .. n ],
                                j -> C!.ElementJuliaToGAP( C, mat[ i, j ] ) ) );
      end,

      MatrixWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.MatrixType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,
    ) );
    end );


#############################################################################
##
#M  ContextGAPNemo( AlgebraicExtension( Q, pol ) )
##
##  On the Nemo side, we have <C>Julia.Nemo.NumberField( ... )</C>.
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
    juliaRing:= Julia.Nemo.NumberField( npol, name );

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
#T also IsFinite value?
#T set also 'IsNumberField' etc., depending on the situation?

    return NewContextGAPJulia( "Nemo", rec(
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

      ElementGAPToJulia:= function( C, obj )
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

      ElementJuliaToGAP:= function( C, obj )
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

      ElementWrapped:= function( C, obj )
        return ObjectifyWithAttributes( rec(), C!.ElementType,
                   JuliaPointer,  obj );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToJulia:= function( C, vec )
        return Julia.Nemo.matrix( C!.JuliaDomainPointer, 1, Length( vec ),
                   GAPToJulia( List( vec, x -> C!.ElementGAPToJulia( C, x ) ) ) );
      end,

      VectorJuliaToGAP:= function( C, vec )
        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        return List( [ 1 .. Julia.Nemo.ncols( vec ) ],
                     j -> C!.ElementJuliaToGAP( C, vec[ 1, j ] ) );
      end,

      VectorWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.VectorType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToJulia:= function( C, mat )
#T better use Julia.GAPNumberFields.Nemo_Matrix_over_NumberField?
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                   NumberRows( mat ), NumberColumns( mat ),
                   GAPToJulia( List( Concatenation( mat ),
                                     x -> C!.ElementGAPToJulia( C, x ) ) ) );
      end,

      MatrixJuliaToGAP:= function( C, mat )
#T better use Julia.GAPNumberFields.MatricesOfCoefficientVectorsNumDen?
        local n;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Nemo.ncols( mat );
        return List( [ 1 .. Julia.Nemo.nrows( mat ) ],
                     i -> List( [ 1 .. n ],
                                j -> C!.ElementJuliaToGAP( C, mat[ i, j ] ) ) );
      end,

      MatrixWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.MatrixType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
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
    local C, result;

    C:= ContextGAPNemo( FamilyObj( template ) );
    if IsVectorObj( template ) then
      result:= C!.VectorWrapped( C, jpointer );
    elif IsMatrixObj( template ) then
      result:= C!.MatrixWrapped( C, jpointer );
    else
      result:= C!.ElementWrapped( C, jpointer );
    fi;

    if HasParent( template ) then
      SetParent( result, Parent( template ) );
    fi;

    return result;
end );


#T beat GAP's 'IsPolynomial' etc. methods
NEMO_RANK_SHIFT:= 100;


#############################################################################
##
##  methods for Nemo's polynomials, polynomial rings, and fields
##
InstallMethod( String,
    [ "IsNemoObject and HasJuliaPointer" ], NEMO_RANK_SHIFT,
    nemo_obj -> String( JuliaPointer( nemo_obj ) ) );

InstallMethod( PrintObj,
    [ "IsNemoObject and HasJuliaPointer" ], NEMO_RANK_SHIFT,
    function( nemo_obj )
    Print( PrintString( nemo_obj ) );
    end );

InstallOtherMethod( Zero, [ "IsNemoObject" ], NEMO_RANK_SHIFT,
    F -> NemoElement( F, Julia.Base.zero( Julia.Base.parent( F ) ) ) );

InstallOtherMethod( One, [ "IsNemoObject" ], NEMO_RANK_SHIFT,
    F -> NemoElement( F, Julia.Base.one( Julia.Base.parent( F ) ) ) );

InstallMethod( RootOfDefiningPolynomial, [ "IsNemoField" ],
    F -> NemoElement( F, Julia.Nemo.gen( F ) ) );


#############################################################################
##
##  methods for field elements, vectors, matrices; delegate to Julia
#T TODO: Unify this with the Singular case, as far as possible?
#T       On the other hand, 'Julia.Base' is responsible not in many cases.
##
InstallOtherMethod( ViewString, [ "IsNemoObject" ],
    x -> Concatenation( "<", ViewString( JuliaPointer( x ) ), ">" ) );

InstallOtherMethod( \=, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    Julia.Base.\=\= );

InstallOtherMethod( \+, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x, Julia.Base.\+( x, y ) );
    end );

#T TODO: Addition '<matrix> + <int>' is defined differently in Julia/Nemo,
#T       the <int> is added just on the diagonal of the matrix!
#T       How to deal with this incompatibility?
InstallOtherMethod( \+, [ "IsNemoObject", "IsInt" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x, Julia.Base.\+( x, y ) );
    end );

InstallOtherMethod( AdditiveInverse, [ "IsNemoObject" ], NEMO_RANK_SHIFT,
    x -> NemoElement( x, Julia.Base.\-( x ) ) );

InstallOtherMethod( \-, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x, Julia.Base.\-( x, y ) );
    end );

InstallOtherMethod( \*, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x, Julia.Base.\*( x, y ) );
    end );

InstallOtherMethod( \/, [ "IsNemoObject", "IsNemoObject" ], NEMO_RANK_SHIFT,
    function( x, y )
      return NemoElement( x, Julia.Nemo.divexact( x, y ) );
    end );

InstallOtherMethod( \^, [ "IsNemoObject", "IsPosInt" ], NEMO_RANK_SHIFT,
    function( x, n )
      return NemoElement( x, Julia.Base.\^( x, n ) );
    end );

InstallOtherMethod( InverseMutable, [ "IsNemoObject" ], NEMO_RANK_SHIFT,
    x -> NemoElement( x, Julia.Base.inv( x ) ) );


InstallMethod( NumberRows,
    [ "IsNemoMatrixObj" ],
    Julia.Nemo.nrows );

InstallMethod( NumberColumns,
    [ "IsNemoMatrixObj" ],
    Julia.Nemo.ncols );

InstallMethod( RankMat,
    [ "IsNemoMatrixObj" ],
    Julia.Nemo.rank );

InstallMethod( MatElm,
    [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt" ],
    function( nemomat, i, j )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    return C!.ElementWrapped( C, JuliaPointer( nemomat )[ i, j ] );
    end );

InstallMethod( \[\],
    [ "IsNemoMatrixObj", "IsPosInt", "IsPosInt" ],
    function( nemomat, i, j )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    return C!.ElementWrapped( C, JuliaPointer( nemomat )[ i, j ] );
    end );

InstallMethod( \^,
    [ "IsNemoMatrixObj", "IsPosInt" ], NEMO_RANK_SHIFT,
    function( nemomat, n )
    local C, power;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    power:= C!.MatrixWrapped( C, Julia.Base.\^( nemomat, n ) );
    SetNumberRows( power, NumberRows( nemomat ) );
    SetNumberColumns( power, NumberColumns( nemomat ) );
    return power;
    end );


InstallOtherMethod( IsZero,
    [ "IsNemoObject" ],
    Julia.Base.iszero );

InstallMethod( Characteristic,
    [ "IsNemoObject" ], NEMO_RANK_SHIFT,
#T TODO: Is the GAP library method of rank 2 really reasonable?
#T       (At least remove one of the two methods that ask the family.)
    function( obj )
    local R;

    R:= ContextGAPNemo( FamilyObj( obj ) )!.JuliaDomain;
    if JuliaTypeInfo( R ) = "Nemo.NmodRing" then
      # We need this for matrix groups over residue class rings.
      # Nemo does not support it.
      return JuliaToGAP( IsInt,
                 Julia.Base.getfield( R, JuliaSymbol( "n" ) ) );
    else
      return JuliaToGAP( IsInt, Julia.Nemo.characteristic( R ) );
    fi;
    end );


InstallMethod( ZeroSameMutability,
    [ "IsNemoMatrixObj" ],
    function( nemomat )
    local C, nr, nc, zero;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    nr:= NumberRows( nemomat );
    nc:= NumberColumns( nemomat );
    zero:= C!.MatrixWrapped( C,
               Julia.Nemo.zero_matrix( C!.JuliaDomain, nr, nc ) );
    SetNumberRows( zero, nr );
    SetNumberColumns( zero, nc );
    return zero;
    end );


InstallOtherMethod( IsOne,
    [ "IsNemoObject" ],
    Julia.Base.isone );

InstallOtherMethod( OneSameMutability,
     [ "IsNemoMatrixObj" ],
    function( nemomat )
    local C, nr, nc, one;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    nr:= NumberRows( nemomat );
    nc:= NumberColumns( nemomat );
    if nr <> nc then
      Error( "<nemomat> is not square" );
    fi;
    one:= C!.MatrixWrapped( C,
              Julia.Nemo.identity_matrix( C!.JuliaDomain, nr ) );
    SetNumberRows( one, nr );
    SetNumberColumns( one, nc );
    return one;
    end );

InstallOtherMethod( InverseMutable,
     [ "IsNemoMatrixObj" ], NEMO_RANK_SHIFT,
#    x -> NemoElement( x, Julia.Base.inv( x ) ) );
#T Remove the code below as soon as it becomes obsolete.
#T (The critical case is inversion of 'Nemo.nmod_mat' objects.)
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
       modulus:= Julia.Nemo.fmpz(
                     Size( ContextGAPNemo( FamilyObj( x ) )!.GAPDomain ) );
       res:= Julia.Nemo.lift( x );
       m:= NumberRows( x );
#T 'res:= Julia.Nemo.matrix( Julia.Nemo.QQ, m, m, res );' does not work
       s:= Julia.Nemo.MatrixSpace( Julia.Nemo.QQ, m, m );
       res:= s( res );
       res:= Julia.Base.inv( res );
       arr:= [];
       for i in [ 1 .. m ] do
         for j in [ 1 .. m ] do
           entry:= res[i,j];
           Add( arr, Julia.Nemo.numerator( entry )
                     * Julia.Base.invmod( Julia.Nemo.denominator( entry ),
                                          modulus ) );
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
    function( nemomat )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    return C!.ElementWrapped( C, Julia.LinearAlgebra.tr( nemomat ) );
    end );

InstallOtherMethod( DeterminantMat,
    [ "IsNemoMatrixObj" ],
    function( nemomat )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    return C!.ElementWrapped( C, Julia.Nemo.det( nemomat ) );
    end );


InstallMethod( ZeroMatrix,
    [ "IsInt", "IsInt", "IsNemoMatrixObj" ],
    function( m, n, nemomat )
    local C, zero;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    zero:= C!.MatrixWrapped( C,
               Julia.Nemo.zero_matrix( C!.JuliaDomain, m, n ) );
    SetNumberRows( zero, m );
    SetNumberColumns( zero, n );
    return zero;
    end );

# Assume that 'R' is a GAP ring, not a Nemo ring.
InstallMethod( NewZeroMatrix,
    [ "IsNemoMatrixObj", "IsRing", "IsInt", "IsInt" ],
    function( filt, R, m, n )
    local C, zero;

    C:= ContextGAPNemo( R );
    zero:= C!.MatrixWrapped( C,
               Julia.Nemo.zero_matrix( C!.JuliaDomain, m, n ) );
    SetNumberRows( zero, m );
    SetNumberColumns( zero, n );
    return zero;
    end );

InstallMethod( IdentityMatrix,
    [ "IsInt", "IsNemoMatrixObj" ],
    function( n, nemomat )
    local C, id;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    id:= C!.MatrixWrapped( C,
             Julia.Nemo.identity_matrix( C!.JuliaDomain, n ) );
    SetNumberRows( id, n );
    SetNumberColumns( id, n );
    return id;
    end );

# Assume that 'R' is a GAP ring, not a Nemo ring.
InstallMethod( NewIdentityMatrix,
    [ "IsNemoMatrixObj", "IsRing", "IsInt" ],
    function( filt, R, n )
    local C, id;

    C:= ContextGAPNemo( R );
    id:= C!.MatrixWrapped( C,
             Julia.Nemo.identity_matrix( C!.JuliaDomain, n ) );
    SetNumberRows( id, n );
    SetNumberColumns( id, n );
    return id;
    end );

InstallOtherMethod( CompanionMatrix,
    [ "IsNemoPolynomial", "IsNemoMatrixObj" ],
#T TODO: check compatibility?
    function( nemopol, nemomat )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    return C!.MatrixWrapped( C,
               Julia.GAPNemoExperimental.CompanionMatrix( nemopol ) );
    end );

InstallMethod( TransposedMat,
    [ "IsNemoMatrixObj" ], NEMO_RANK_SHIFT,
    function( nemomat )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat ) );
    return C!.MatrixWrapped( C, Julia.Nemo.transpose( nemomat ) );
    end );

InstallMethod( KroneckerProduct,
    IsIdenticalObj,
    [ "IsNemoMatrixObj", "IsNemoMatrixObj" ], NEMO_RANK_SHIFT,
    function( nemomat1, nemomat2 )
    local C;

    C:= ContextGAPNemo( FamilyObj( nemomat1 ) );
    return C!.MatrixWrapped( C, Julia.Nemo.kronecker_product( nemomat1,
                                                              nemomat2 ) );
    end );

# InstallMethod( Unfold,
#     IsCollsElms,
#     [ "IsNemoMatrixObj", "IsNemoVectorObj" ],
#     function( nemomat, nemovec )
#     local C;
# 
#     C:= ContextGAPNemo( FamilyObj( nemomat ) );
#     return C!.VectorWrapped( C,
#                Julia.GAPNemoExperimental.unfoldedNemoMatrix( nemomat ) );
#     end );
# 
# InstallMethod( Fold,
# #T IsElmsXColls,
#     [ "IsNemoVectorObj", "IsPosInt", "IsNemoMatrixObj" ],
#     function( nemovec, ncols, nemomat )
#     local C;
# 
#     C:= ContextGAPNemo( FamilyObj( nemovec ) );
#     return C!.MatrixWrapped( C,
#                Julia.GAPNemoExperimental.foldedNemoVector( nemovec, ncols ) );
#     end );


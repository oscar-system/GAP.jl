##############################################################################
##
##  singular.g
##
##  This is an experimental interface from GAP to Singular,
##  using Julia's 'Singular.jl'.
##


DeclareSynonym( "IsSingularIdeal", IsSingularObject and IsIdealInParent );
#T needed?  correct?


#############################################################################
##
#M  ContextGAPSingular( Rationals )
##
##  On the Singular side, we have <C>Julia.Singular.QQ</C>.
##
InstallMethod( ContextGAPSingular,
    [ "IsRing and IsRationals and IsAttributeStoringRep" ],
    function( R )
    local m, juliaRing, efam, collfam, gen, type;

    # No check of the ring is necessary.

    # Create the Singular ring.
    juliaRing:= Julia.Singular.QQ;

    # Create the GAP wrappers.
    # Create a new family.
    efam:= NewFamily( "Singular_QQ_ElementsFamily", IsSingularObject, IsScalar );
    SetIsUFDFamily( efam, true );
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsSingularFieldElement and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsSingularObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsSingularRingElement and IsAttributeStoringRep );

    gen:= ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 1 ) );

    SetZero( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 0 ) ) );
    SetOne( efam, gen );

    type:= IsSingularField and IsAttributeStoringRep and
           IsCommutative and IsAssociative;

    return NewContextGAPSingular( rec(
      Name:= "<context for Rationals>",

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, infinity,
                      Name, "Singular_QQ" ),

      ElementType:= efam!.elementType,

      ElementGAPToSingular:= function( C, obj )
        return Julia.Base.\/\/( 
                   Julia.Singular.n_Q( NumeratorRat( obj ) ),
                   Julia.Singular.n_Q( DenominatorRat( obj ) ) );
      end,

      ElementSingularToGAP:= function( C, obj )
        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
#T hack: for rationals, carry back from Julia/Singular via string;
        return EvalString( JuliaToGAP( IsString, Julia.Base.string( obj ) ) );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToSingular:= function( C, vec )
        return Julia.Singular.matrix( C!.JuliaDomainPointer, 1, Length( vec ),
                   GAPToJulia( List( vec, x -> C!.ElementGAPToSingular( C, x ) ) ) );
      end,

      VectorSingularToGAP:= function( C, vec )
        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        return List( [ 1 .. Julia.Singular.cols( vec ) ],
                     j -> C!.ElementSingularToGAP( C, vec[ 1, j ] ) );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToSingular:= function( C, mat )
        return Julia.Singular.matrix( C!.JuliaDomainPointer,
                   NumberRows( mat ), NumberColumns( mat ),
                   GAPToJulia( List( Concatenation( mat ),
                                     x -> C!.ElementGAPToSingular( C, x ) ) ) );
      end,

      MatrixSingularToGAP:= function( C, mat )
        local n;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Singular.cols( mat );
        return List( [ 1 .. Julia.Singular.rows( mat ) ],
                     i -> List( [ 1 .. n ],
                                j -> C!.ElementSingularToGAP( C, mat[ i, j ] ) ) );
      end,
    ) );
    end );


#############################################################################
##
#M  ContextGAPSingular( PolynomialRing( R, n )[:<options>] )
##
##  On the Singular side, we have <C>Julia.Singular.PolynomialRing( ... )</C>.
##
##  The options <C>ordering1</C>, <C>ordering2</C>, <degree_bound</C> are
##  supported,
##  where the values of the former two options may be one of
##  <C>"lex"</C> (or <C>lp</C>),
##  <C>"revlex"</C> (or <C>rp</C>),
##  <C>"neglex"</C> (or <C>ls</C>),
##  <C>"negrevlex"</C> (or <C>rs</C>),
##  <C>"degrevlex"</C> (or <C>dp</C>),
##  <C>"deglex"</C> (or <C>Dp</C>),
##  <C>"negdegrevlex"</C> (or <C>ds</C>),
##  <C>"negdeglex"</C> (or <C>Ds</C>),
##  <C>"comp1max"</C> (or <C>c</C>),
##  <C>"comp1min"</C> (or <C>C</C>),
##  and the values for the last option may be a positive integer.
##
#T see "~/.julia/v0.6/Singular/test/poly/PolyRing-test.jl" for variants!!!
#T update this comment!
##
InstallMethod( ContextGAPSingular,
    [ "IsPolynomialRing and IsAttributeStoringRep" ],
    function( R )
    local F, FContext, indetnames, names, available_orderings, ordering,
          ordering2, degree_bound, dict, juliaRing, efam, collfam, indets,
          type;

    # No check of the ring is necessary.
    F:= LeftActingDomain( R );
    FContext:= ContextGAPSingular( F );
    indetnames:= List( IndeterminatesOfPolynomialRing( R ), String );
    if Length( indetnames ) = 1 then
      names:= GAPToJulia( indetnames[1] );
    else
      names:= Julia.Base.convert( JuliaEvalString( "Array{String,1}" ),
                                  GAPToJulia( indetnames ) );
    fi;

    # See '.julia/v0.6/Singular/src/Singular.jl'.
#T update the comment!
    available_orderings:= rec(
        lex:= "lex", lp:= "lex",
        revlex:= "revlex", rp:= "revlex",
        neglex:= "neglex", ls:= "neglex",
        negrevlex:= "negrevlex", rs:= "negrevlex",
        degrevlex:= "degrevlex", dp:= "degrevlex",
        negdegrevlex:= "negdegrevlex", ds:= "negdegrevlex",
        deglex:= "deglex", Dp:= "deglex",
        comp1max:= "comp1max", c:= "comp1max",
        comp1min:= "comp1min", C:= "comp1min",
    );

    # Check global options.
    ordering:= ValueOption( "ordering" );
    if ordering = fail then
      ordering:= "degrevlex";
    fi;
    if not IsBound( available_orderings.( ordering ) ) then
      Error( ordering, " is not admissible for ordering" );
    fi;
    ordering:= available_orderings.( ordering );

    ordering2:= ValueOption( "ordering2" );
    if ordering2 = fail then
      ordering2:= "comp1min";
    fi;
    if not IsBound( available_orderings.( ordering2 ) ) then
      Error( ordering2, " is not admissible for ordering2" );
    fi;
    ordering2:= available_orderings.( ordering2 );

    degree_bound:= ValueOption( "degree_bound" );
    if degree_bound = fail then
      degree_bound:= 0;
    fi;

    # Create the Singular ring.
    # If we would be able to deal with keyword arguments
    # then wrapping would not be needed here.
    dict:= GAPToJulia( rec( ring:= FContext!.JuliaDomainPointer,
                          indeterminates:= names,
                          cached:= true,
                          ordering:= JuliaSymbol( ordering ),
                          ordering2:= JuliaSymbol( ordering2 ),
                          degree_bound:= degree_bound ) );
    juliaRing:= Julia.GAPSingularModule.SingularPolynomialRingWrapper( dict );

    # Create the GAP wrappers.
    # Create a new family.
    # Note that elements from two Singular polynomial rings cannot be compared,
    efam:= NewFamily( "Singular_PolynomialsFamily", IsSingularObject, IsScalar );
#   SetIsUFDFamily( efam, true );
#T ?
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsSingularPolynomial and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsSingularObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsSingularRingElement and IsAttributeStoringRep );

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
    type:= IsSingularPolynomialRing and IsAttributeStoringRep and IsFreeLeftModule
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

    return NewContextGAPSingular( rec(
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
                      Name, "Singular_PolynomialRing" ),

      ElementType:= efam!.elementType,

      ElementGAPToSingular:= function( C, obj )
        local FContext, indets, pol, one, i, mon, v, j;

        FContext:= ContextGAPSingular( LeftActingDomain( C!.GAPDomain ) );

        if IsPolynomial( obj ) then
          obj:= ExtRepPolynomialRatFun( obj );
        fi;
        indets:= List( IndeterminatesOfPolynomialRing( C!.JuliaDomain ),
                       JuliaPointer );
        pol:= Julia.Base.zero( indets[1] );
        one:= Julia.Base.one( indets[1] );
        for i in [ 1 .. Length( obj )/2 ] do
          mon:= one;
          v:= obj[ 2*i-1 ];
          for j in [ 1, 3 .. Length( v ) - 1 ] do
            mon:= mon * indets[ v[j] ]^v[ j+1 ];
          od;
          pol:= pol +
                FContext!.ElementGAPToSingular( FContext, obj[ 2*i ] ) * mon;
        od;

        return pol;
      end,

      ElementSingularToGAP:= function( C, obj )
        local descr, FC, coeffs, exps, n, i, mon, v, j;

        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
        descr:= Julia.GAPSingularModule.GAPExtRepOfSingularPolynomial( obj );
        FC:= ContextGAPSingular( LeftActingDomain( C!.GAPDomain ) );
        coeffs:= List( JuliaToGAP( IsList, descr[1] ),
                       x -> SingularToGAP( FC, x ) );
        exps:= JuliaToGAP( IsList, descr[2], true );
        n:= Length( exps[1] );
        for i in [ 1 .. Length( exps ) ] do
          mon:= [];
          v:= exps[i];
          for j in [ 1 .. n ] do
            if v[j] <> 0 then
              Append( mon, [ i, v[j] ] );
            fi;
          od;
          exps[i]:= mon;
        od;

        descr:= Concatenation( TransposedMat( [ exps, coeffs ] ) );
        return PolynomialByExtRep(
# NC?
                   ElementsFamily( FamilyObj( LeftActingDomain( C!.GAPDomain ) ) ), descr );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToSingular:= function( C, vec )
        return Julia.Singular.matrix( C!.JuliaDomainPointer, 1, Length( vec ),
                   GAPToJulia( List( vec, x -> C!.ElementGAPToSingular( C, x ) ) ) );
      end,

      VectorSingularToGAP:= function( C, vec )
        if HasJuliaPointer( vec ) then
          vec:= JuliaPointer( vec );
        fi;
        return List( [ 1 .. Julia.Singular.cols( vec ) ],
                     j -> C!.ElementSingularToGAP( C, vec[ 1, j ] ) );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToSingular:= function( C, mat )
        return Julia.Singular.matrix( C!.JuliaDomainPointer,
                   NumberRows( mat ), NumberColumns( mat ),
                   GAPToJulia( List( Concatenation( mat ),
                                     x -> C!.ElementGAPToSingular( C, x ) ) ) );
      end,

      MatrixSingularToGAP:= function( C, mat )
        local n;

        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        n:= Julia.Singular.cols( mat );
        return List( [ 1 .. Julia.Singular.rows( mat ) ],
                     i -> List( [ 1 .. n ],
                                j -> C!.ElementSingularToGAP( C, mat[ i, j ] ) ) );
      end,
    ) );
    end );


#############################################################################
##
##  We need Singular's ZZ and QQ for creating polynomial rings.
##
BindGlobal( "Singular_ZZ", Objectify(
    NewType( CollectionsFamily( NewFamily( "Singular_ZZ_ElementsFamily" ) ),
             IsAttributeStoringRep and IsSingularObject and IsRing ),
    rec() ) );

SetName( Singular_ZZ, "Singular_ZZ" );
SetLeftActingDomain( Singular_ZZ, Singular_ZZ );
SetSize( Singular_ZZ, infinity );
SetJuliaPointer( Singular_ZZ, Julia.Singular.ZZ );
ElementsFamily( FamilyObj( Singular_ZZ ) )!.MatrixType:= NewType(
    CollectionsFamily( FamilyObj( Singular_ZZ ) ),
    IsMatrixObj and IsSingularObject and IsAttributeStoringRep );

BindGlobal( "Singular_QQ", Objectify(
    NewType( CollectionsFamily( NewFamily( "Singular_QQ_ElementsFamily" ) ),
             IsAttributeStoringRep and IsSingularObject and IsField and IsPrimeField ),
    rec() ) );

SetName( Singular_QQ, "Singular_QQ" );
SetLeftActingDomain( Singular_QQ, Singular_QQ );
SetSize( Singular_QQ, infinity );
SetJuliaPointer( Singular_QQ, Julia.Singular.QQ );
ElementsFamily( FamilyObj( Singular_QQ ) )!.MatrixType:= NewType(
    CollectionsFamily( FamilyObj( Singular_QQ ) ),
    IsMatrixObj and IsSingularObject and IsAttributeStoringRep );


#############################################################################
##
#F  SingularElement( <template>, <jpointer> )
##
##  is used to wrap polynomials or ...
#T or what?
#T this approach can create only those objects which are defined by their
#T 'JuliaPointer' value plus their type info;
#T this does not hold for ideals (they need attribute information)
##
BindGlobal( "SingularElement", function( template, jpointer )
    local type, result;

    if IsDomain( template ) then
#T needed?
      type:= ContextGAPSingular( FamilyObj( template ) )!.ElementType;
    elif IsVectorObj( template ) then
      type:= ContextGAPSingular( FamilyObj( template ) )!.VectorType;
    elif IsMatrixObj( template ) then
      type:= ContextGAPSingular( FamilyObj( template ) )!.MatrixType;
    else
      type:= ContextGAPSingular( FamilyObj( template ) )!.ElementType;
    fi;

    result:= ObjectifyWithAttributes( rec(), type, JuliaPointer, jpointer );
    if HasParent( template ) then
      SetParent( result, Parent( template ) );
    fi;

    return result;
end );



#############################################################################
##
##  We need polynomial rings in order to create polynomials.
##

InstallMethod( AssignGeneratorVariables,
    [ "IsSingularPolynomialRing" ],
    function( R )
    DoAssignGenVars( IndeterminatesOfPolynomialRing( R ) );
    end );

InstallMethod( String,
    [ "IsSingularObject and HasJuliaPointer" ], 100,
    sing_obj -> String( JuliaPointer( sing_obj ) ) );

InstallMethod( PrintObj,
    [ "IsSingularObject and HasJuliaPointer" ], 100,
    function( sing_obj )
    Print( PrintString( sing_obj ) );
    end );


#############################################################################
##
#F  SingularPolynomialRing( <R>, <names> )
##
##  The options <C>ordering1</C>, <C>ordering2</C>, <degree_bound</C> are
##  supported,
##  where the values of the former two options may be one of
##  <C>"lex"</C> (or <C>lp</C>),
##  <C>"revlex"</C> (or <C>rp</C>),
##  <C>"neglex"</C> (or <C>ls</C>),
##  <C>"negrevlex"</C> (or <C>rs</C>),
##  <C>"degrevlex"</C> (or <C>dp</C>),
##  <C>"deglex"</C> (or <C>Dp</C>),
##  <C>"negdegrevlex"</C> (or <C>ds</C>),
##  <C>"negdeglex"</C> (or <C>Ds</C>),
##  <C>"comp1max"</C> (or <C>c</C>),
##  <C>"comp1min"</C> (or <C>C</C>),
##  and the values for the last option may be a positive integer.

#T see "~/.julia/v0.6/Singular/test/poly/PolyRing-test.jl" for variants!!!

BindGlobal( "SingularPolynomialRing", function( R, names )
    local filter, available_orderings, ordering, ordering2, degree_bound,
          dict, juliaobj, efam, indets;

    filter:= IsSingularPolynomialRing and IsAttributeStoringRep
           and IsFreeLeftModule and IsFLMLORWithOne;

    # Check the arguments.
    if IsIdenticalObj( R, Integers ) or IsIdenticalObj( R, Singular_ZZ ) then
      R:= Singular_ZZ;
      filter:= filter and IsCommutative and IsAssociative
               and IsSingularObject;
    elif IsIdenticalObj( R, Rationals ) or IsIdenticalObj( R, Singular_QQ ) then
      R:= Singular_QQ;
      filter:= filter and IsAlgebraWithOne
               and IsCommutative and IsAssociative
               and IsRationalsPolynomialRing
               and IsSingularObject;
    elif not HasJuliaPointer( R ) then
#T admit also *finite* field in GAP (-> IsFiniteFieldPolynomialRing)
#T admit algebraic extensions (-> IsAlgebraicExtensionPolynomialRing)
#T admit GAP's abelian number fields (-> IsAbelianNumberFieldPolynomialRing)
      Error( "usage: ..." );
    fi;
    if not ( IsList( names ) and ForAll( names, IsString ) ) then
      Error( "<names> must be a list of strings" );
    fi;

    # See '.julia/v0.6/Singular/src/Singular.jl'.
    available_orderings:= rec(
        lex:= "lex", lp:= "lex",
        revlex:= "revlex", rp:= "revlex",
        neglex:= "neglex", ls:= "neglex",
        negrevlex:= "negrevlex", rs:= "negrevlex",
        degrevlex:= "degrevlex", dp:= "degrevlex",
        negdegrevlex:= "negdegrevlex", ds:= "negdegrevlex",
        deglex:= "deglex", Dp:= "deglex",
        comp1max:= "comp1max", c:= "comp1max",
        comp1min:= "comp1min", C:= "comp1min",
    );

    # Check global options.
    ordering:= ValueOption( "ordering" );
    if ordering = fail then
      ordering:= "degrevlex";
    fi;
    if not IsBound( available_orderings.( ordering ) ) then
      Error( ordering, " is not admissible for ordering" );
    fi;
    ordering:= available_orderings.( ordering );

    ordering2:= ValueOption( "ordering2" );
    if ordering2 = fail then
      ordering2:= "comp1min";
    fi;
    if not IsBound( available_orderings.( ordering2 ) ) then
      Error( ordering2, " is not admissible for ordering2" );
    fi;
    ordering2:= available_orderings.( ordering2 );

    degree_bound:= ValueOption( "degree_bound" );
    if degree_bound = fail then
      degree_bound:= 0;
    fi;

    # Convert the names list from "Array{Any,1}" to "Array{String,1}".
    names:= Julia.Base.convert( JuliaEvalString( "Array{String,1}" ),
                                GAPToJulia( names ) );

    # Create the julia objects.
    # If we would be able to deal with keyword arguments
    # then wrapping would not be needed here.
    dict:= GAPToJulia( rec( ring:= JuliaPointer( R ),
                          indeterminates:= names,
                          cached:= true,
                          ordering:= JuliaSymbol( ordering ),
                          ordering2:= JuliaSymbol( ordering2 ),
                          degree_bound:= degree_bound ) );
    juliaobj:= Julia.GAPSingularModule.SingularPolynomialRingWrapper( dict );

    # Create the GAP wrapper.
    # Note that elements from two Singular polynomial rings cannot be compared,
    # so we create always a new family.
#T Is this a good idea?
#T In Singular.jl, the ring constructor uses a cache.
    efam:= NewFamily( "Singular_PolynomialsFamily", IsSingularObject, IsScalar );

    # Create the object and set attributes.
    R:= ObjectifyWithAttributes( rec(),
            NewType( CollectionsFamily( efam ), filter ),
            JuliaPointer, juliaobj[1],
            LeftActingDomain, R,
            IsFinite, false,
            IsFiniteDimensional, false,
            Size, infinity,
            CoefficientsRing, R );
#T set also one and zero?

    # Store a back reference to the (GAP) polynomial ring in the type,
    # such that each polynomial can access is;
    # functions like 'DefaultRing' will need this.
    efam!.ElementType:= NewType( efam,
        IsPolynomial and IsSingularObject and IsAttributeStoringRep, R );

    # Store the GAP list of wrapped Julia indeterminates.
    indets:= List( JuliaToGAP( IsList, juliaobj[2] ),
                   x -> SingularElement( R, x ) );
    SetIndeterminatesOfPolynomialRing( R, indets );
    SetGeneratorsOfLeftOperatorRingWithOne( R, indets );

    return R;
end );


InstallOtherMethod( \in,
    IsElmsColls,
    [ "IsSingularPolynomial", "IsSingularPolynomialRing" ],
    function( elm, R )

    if not IsIdenticalObj( R, DataType( TypeObj( elm ) ) ) then
!
#T This is not correct!
      return false;
    fi;

    return true;
    end );


InstallOtherMethod( IsSubset,
    IsIdenticalObj,
    [ "IsSingularPolynomialRing", "IsHomogeneousList" ],
    function( R, elms )
    local elm;

    for elm in elms do
      if not IsIdenticalObj( R, DataType( TypeObj( elm ) ) ) then
#T This may be not correct.
        return false;
      fi;
    od;

    return true;
    end );


InstallOtherMethod( DefaultRingByGenerators,
    [ "IsSingularObjectCollection and IsList" ],
    function( gens )
    local R, i;

    R:= DataType( TypeObj( gens[1] ) );
    for i in [ 2 .. Length( gens ) ] do
      if not IsIdenticalObj( R, DataType( TypeObj( gens[i] ) ) ) then
        Error( "no common ring for <gens>" );
      fi;
    od;

    return R;
    end );


InstallOtherMethod( GcdOp,
    [ "IsSingularPolynomialRing", "IsSingularPolynomial",
                                  "IsSingularPolynomial" ],
    function( R, f, g )
        return SingularElement( f, Julia.Base.gcd(
                   JuliaPointer( f ), JuliaPointer( g ) ) );
    end );


InstallOtherMethod( GcdOp,
    IsIdenticalObj,
    [ "IsSingularPolynomial", "IsSingularPolynomial" ],
    function( f, g )
        return SingularElement( f, Julia.Base.gcd(
                   JuliaPointer( f ), JuliaPointer( g ) ) );
    end );


InstallOtherMethod( IdealByGenerators,
#T IsIdenticalObj, ???
    [ "IsSingularPolynomialRing", "IsHomogeneousList" ], 100,
    function( R, gens )
    local filter, juliaobj, I;

    filter:= IsSingularIdeal and IsAttributeStoringRep
             and IsFreeLeftModule and IsFLMLOR
             and IsSingularObject;

    # Create the Singular ideal.
    # Note that 'Singular.Ideal' does not expect a list of generators.
    juliaobj:= CallFuncList( Julia.Singular.Ideal,
                   Concatenation( [ JuliaPointer( R ) ], gens ) );

    # Create the GAP domain.
    I:= ObjectifyWithAttributes( rec(),
            NewType( FamilyObj( R ), filter ),
            JuliaPointer, juliaobj,
            LeftActingDomain, LeftActingDomain( R ),
            LeftActingRingOfIdeal, R,
            RightActingRingOfIdeal, R,
            IsFinite, false,
            IsFiniteDimensional, false,
            Size, infinity,
            CoefficientsRing, CoefficientsRing( R ),
            GeneratorsOfTwoSidedIdeal, gens );

    # Transfer known associativity, commutativity etc. from 'R' to 'I'.
    UseSubsetRelation( R, I );

    return I;
    end );


#############################################################################
##
#F  GroebnerBasisIdeal( <I> )
##
##  For the ideal <I>, return an ideal that is equal to <I> and such that
##  the generators form a Groebner basis.
##
##  Note that Singular's <C>std</C> function returns an ideal not a list of
##  polynomials.
##

#T if the monomial ordering is fixed in the ring
#T then we can make the Groebner basis an attribute of I

BindGlobal( "GroebnerBasisIdeal", function( I )
    local filter, R, juliaobj, gens, G;

    filter:= IsSingularIdeal and IsAttributeStoringRep
             and IsFreeLeftModule and IsFLMLOR
             and IsSingularObject;

    # Create the Singular ideal.
    R:= LeftActingRingOfIdeal( I );
    juliaobj:= Julia.Base.std( JuliaPointer( I ) );
    gens:= List( [ 1 .. Julia.Singular.ngens( juliaobj ) ],
                 i -> SingularElement( R, juliaobj[i] ) );

    # Create the GAP domain.
    G:= ObjectifyWithAttributes( rec(),
            NewType( FamilyObj( I ), filter ),
            JuliaPointer, juliaobj,
            LeftActingDomain, LeftActingDomain( I ),
            LeftActingRingOfIdeal, LeftActingRingOfIdeal( I ),
            RightActingRingOfIdeal, RightActingRingOfIdeal( I ),
            IsFinite, false,
            IsFiniteDimensional, false,
            Size, infinity,
            CoefficientsRing, CoefficientsRing( I ),
            GeneratorsOfTwoSidedIdeal, gens );

    # Transfer known associativity, commutativity etc. from 'I' to 'G'.
    UseSubsetRelation( I, G );

    return G;
    end );


#############################################################################
##
##  constructors for polynomials
##


#############################################################################
##
##  methods for Singular's polynomials and polynomial rings
##
InstallOtherMethod( Zero, [ "IsSingularObject" ], 200,
    F -> SingularElement( F, Julia.Base.zero( JuliaPointer( F ) ) ) );

InstallOtherMethod( One, [ "IsSingularObject" ], 200,
    F -> SingularElement( F, Julia.Base.one( JuliaPointer( F ) ) ) );

#T avoid 'One' for an ideal?


#############################################################################
##
##  methods for Singular polynomials
##
##  There are high ranked methods for polynomials in GAP,
##  thus we have to increase the ranks of our methods.
##


##############################################################################
##
#M  Degree( <pol> ) . . . . . . . . . . . . . .  for a multivariate polynomial
##
InstallOtherMethod( Degree,
    [ "IsSingularPolynomial" ],
    pol -> Julia.Singular.degree( JuliaPointer( pol ) ) );


InstallOtherMethod( ViewString,
    [ "IsSingularObject" ],
    x -> Concatenation( "<", ViewString( JuliaPointer( x ) ), ">" ) );

InstallOtherMethod( \=,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return Julia.Base.\=\=( JuliaPointer( x ), JuliaPointer( y ) );
    end );

#T 'Singular.jl' does not define 'isless' methods for polynomials.
# InstallOtherMethod( \<,
#     [ "IsSingularObject", "IsSingularObject" ],
#     function( x, y )
#       return Julia.Base.isless( JuliaPointer( x ), JuliaPointer( y ) ) );
#     end );

InstallOtherMethod( \+,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.\+( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \+,
    [ "IsSingularObject", "IsInt" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.\+( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \+,
    [ "IsInt", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( y,
                 Julia.Base.\+( x, JuliaPointer( y ) ) );
    end );

InstallOtherMethod( AdditiveInverse,
    [ "IsSingularObject" ], 100,
    x -> SingularElement( x, Julia.Base.\-( JuliaPointer( x ) ) ) );

InstallOtherMethod( \-,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.\-( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \-,
    [ "IsSingularObject", "IsInt" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.\-( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \-,
    [ "IsInt", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( y,
                 Julia.Base.\-( x, JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \*,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.\*( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \*,
    [ "IsSingularObject", "IsInt" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.\*( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \*,
    [ "IsInt", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( y,
                 Julia.Base.\*( x, JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \/,
    [ "IsSingularObject", "IsInt" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Singular.divexact( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \^,
    [ "IsSingularObject", "IsPosInt" ], 100,
    function( x, n )
      return SingularElement( x, Julia.Base.\^( JuliaPointer( x ), n ) );
    end );


##############################################################################
##
#E


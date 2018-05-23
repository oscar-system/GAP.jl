##############################################################################
##
##  singular.g
##
##  This is an experimental interface from GAP to Singular,
##  using Julia's 'Singular.jl'.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "singular.jl" ) );

ImportJuliaModuleIntoGAP( "Core" );
ImportJuliaModuleIntoGAP( "Base" );
ImportJuliaModuleIntoGAP( "Nemo" );
ImportJuliaModuleIntoGAP( "Singular" );
ImportJuliaModuleIntoGAP( "GAPSingularModule" );


#############################################################################
##
##  Declare filters.
##
DeclareCategory( "IsSingularObject", IsObject );
DeclareCategoryCollections( "IsSingularObject" );

DeclareSynonym( "IsSingularPolynomial", IsSingularObject and IsPolynomial );
DeclareSynonym( "IsSingularPolynomialRing",
    IsSingularObject and IsPolynomialRing );
DeclareCategory( "IsSingularIdeal", IsSingularObject );


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
ElementsFamily( FamilyObj( Singular_ZZ ) )!.matrixType:= NewType(
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
ElementsFamily( FamilyObj( Singular_QQ ) )!.matrixType:= NewType(
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
      type:= ElementsFamily( FamilyObj( template ) )!.defaultType;
    else
      type:= FamilyObj( template )!.defaultType;
    fi;

    return ObjectifyWithAttributes( rec(), type, JuliaPointer, jpointer );
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
          dict, juliaobj, efam, getindex, indets;

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
                                JuliaBox( names ) );

    # Create the julia objects.
    # If we would be able to deal with keyword arguments
    # then wrapping would not be needed here.
    dict:= JuliaBox( rec( ring:= JuliaPointer( R ),
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
    efam:= NewFamily( "Singular_PolynomialsFamily", IsSingularObject );

    # Create the object and set attributes.
    getindex:= Julia.Base.getindex;
    R:= ObjectifyWithAttributes( rec(),
            NewType( CollectionsFamily( efam ), filter ),
            JuliaPointer, getindex( juliaobj, 1 ),
            LeftActingDomain, R,
            IsFinite, false,
            IsFiniteDimensional, false,
            Size, infinity,
            CoefficientsRing, R );
#T set also one and zero?

    # Store a back reference to the (GAP) polynomial ring in the type,
    # such that each polynomial can access is;
    # functions like 'DefaultRing' will need this.
    efam!.defaultType:= NewType( efam,
        IsPolynomial and IsSingularObject and IsAttributeStoringRep, R );

    # Store the GAP list of wrapped Julia indeterminates.
    indets:= List( JuliaUnbox( getindex( juliaobj, 2 ) ),
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
#T This is not correct!
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
        return SingularElement( f, Julia.Base.gcd( f, g ) );
    end );


InstallOtherMethod( GcdOp,
    IsIdenticalObj,
    [ "IsSingularPolynomial", "IsSingularPolynomial" ],
    function( f, g )
        return SingularElement( f, Julia.Base.gcd( f, g ) );
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
            CoefficientsRing, R,
            GeneratorsOfTwoSidedIdeal, gens );

    # Transfer known associativity, commutativity etc. from 'R' to 'I'.
    UseSubsetRelation( R, I );

    return I;
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
InstallOtherMethod( ViewString,
    [ "IsSingularObject" ],
    x -> Concatenation( "<", ViewString( JuliaPointer( x ) ), ">" ) );

InstallOtherMethod( \=,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return JuliaUnbox(
                 Julia.Base.("==")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

#T 'Singular.jl' does not define 'isless' methods for polynomials.
# InstallOtherMethod( \<,
#     [ "IsSingularObject", "IsSingularObject" ],
#     function( x, y )
#       return JuliaUnbox(
#                  Julia.Base.isless( JuliaPointer( x ), JuliaPointer( y ) ) );
#     end );

InstallOtherMethod( \+,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.("+")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \+,
    [ "IsSingularObject", "IsInt and IsSmallIntRep" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.("+")( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \+,
    [ "IsInt and IsSmallIntRep", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( y,
                 Julia.Base.("+")( x, JuliaPointer( y ) ) );
    end );

InstallOtherMethod( AdditiveInverse,
    [ "IsSingularObject" ], 100,
    x -> SingularElement( x, Julia.Base.("-")( JuliaPointer( x ) ) ) );

InstallOtherMethod( \-,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.("-")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \-,
    [ "IsSingularObject", "IsInt and IsSmallIntRep" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.("-")( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \-,
    [ "IsInt and IsSmallIntRep", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( y,
                 Julia.Base.("-")( x, JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \*,
    [ "IsSingularObject", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.("*")( JuliaPointer( x ), JuliaPointer( y ) ) );
    end );

InstallOtherMethod( \*,
    [ "IsSingularObject", "IsInt and IsSmallIntRep" ], 100,
    function( x, y )
      return SingularElement( x,
                 Julia.Base.("*")( JuliaPointer( x ), y ) );
    end );

InstallOtherMethod( \*,
    [ "IsInt and IsSmallIntRep", "IsSingularObject" ], 100,
    function( x, y )
      return SingularElement( y,
                 Julia.Base.("*")( x, JuliaPointer( y ) ) );
    end );

#T Calling 'divexact' causes a segmentation fault in Julia!
#T Is there an easier way to create rational coefficients in Singular?
InstallOtherMethod( \/,
    [ "IsSingularObject", "IsInt and IsSmallIntRep" ], 100,
    function( x, y )
      local c;

      c:= Julia.Singular.divexact( Julia.Singular.QQ( 1 ),
                                   Julia.Singular.QQ( y ) );
      return SingularElement( x,
                 Julia.Base.("*")( c, JuliaPointer( x ) ) );
    end );

InstallOtherMethod( \^,
    [ "IsSingularObject", "IsPosInt and IsSmallIntRep" ], 100,
    function( x, n )
      return SingularElement( x, Julia.Base.("^")( JuliaPointer( x ), n ) );
    end );


##############################################################################
##
#E


##############################################################################
##
##  loewy.gi
##
##  This file contains implementations of GAP functions for studying 
##  the Loewy structure of Singer algebras $A(q,n,e)$.
##


#############################################################################
##
#M  LoewyStructureInfo( <A> )
##
##  Call a Julia function, convert its result to a record,
##  but keep the record components in Julia.
##
InstallMethod( LoewyStructureInfo,
    [ "IsSingerAlgebra" ],
    A -> CallFuncList( Julia.LoewyStructure.LoewyLayersData,
             List( ParametersOfSingerAlgebra( A ), GAPToJulia ) ) );


#############################################################################
##
#M  DimensionsLoewyFactors( <A> )
##
##  Compute the Loewy vector in Julia and then convert it to GAP.
##
InstallMethod( DimensionsLoewyFactors,
    [ "IsSingerAlgebra" ],
    A -> JuliaToGAP( IsList,
             Julia.LoewyStructure.LoewyVector( LoewyStructureInfo( A ) ),
             true ) );


#############################################################################
##
#F  SingerAlgebra( <q>, <n>, <e>[, <R>] )
##
##  The algebra returned by this function claims to be a structure constants
##  algebra (via the filter 'IsSCAlgebraObjCollection'),
##  but the structure constants table is not created until one asks for
##  something that needs it.
##  Currently a special method for 'CanonicalBasis' makes sure that the
##  relevant data get stored.
##
InstallGlobalFunction( SingerAlgebra, function( q, n, e, R... )
    local z, zero, filter, Fam, A;

    if Length( R ) = 0 then
      R:= Rationals;
    else
      R:= R[1];
    fi;

    if not ( IsPosInt( q ) and IsPosInt( n ) and IsPosInt( e ) ) then
      Error( "<q>, <n>, <e> must be positive integers" );
    elif q = 1 then
      Error( "<q> must be an integer > 1" );
    fi;

    z:= ( q^n - 1 ) / e;
    if not IsInt( z ) then
      Error( "<e> must divide <q>^<n> - 1" );
    fi;

    # Create the algebra as far as necessary.
    zero := Zero( R );
    filter:= IsSCAlgebraObj;
    if IsAdditivelyCommutativeElementFamily( FamilyObj( zero ) ) then
      filter:= filter and IsAdditivelyCommutativeElement;
    fi;
    Fam:= NewFamily( "SCAlgebraObjFamily", filter );
    if Zero( ElementsFamily( FamilyObj( R ) ) ) <> fail then
      SetFilterObj( Fam, IsFamilyOverFullCoefficientsFamily );
    else
      Fam!.coefficientsDomain:= R;
    fi;
    Fam!.zerocoeff := zero;
    SetCharacteristic( Fam, Characteristic( R ) );
    SetCoefficientsFamily( Fam, ElementsFamily( FamilyObj( R ) ) );

    A:= Objectify( NewType( CollectionsFamily( Fam ),
                   IsSingerAlgebra and IsAttributeStoringRep ),
                   rec() );
    SetLeftActingDomain( A, R );
    SetParametersOfSingerAlgebra( A, [ q, n, e ] );
    SetDimension( A, z+1 );
    SetName( A, Concatenation( "A(", String( q ), ",", String( n ), ",",
                               String( e ), ")" ) );
    Fam!.fullSCAlgebra:= A;
    SetIsFullSCAlgebra( A, true );

    return A;
    end );


#############################################################################
##
#M  CanonicalBasis( <A> )
##
##  This method provides the internal data for treating the Singer algebra
##  <A> as a structure constants algebra in GAP.
##
##  Formally, we require those filters that are required also by the library
##  method for full s.c. algebras, in order to guarantee a higher rank
##  for our method;
##  these filters are set in algebras returned by 'SingerAlgebra'.
##
InstallMethod( CanonicalBasis,
    [ "IsSingerAlgebra and IsFreeLeftModule and IsSCAlgebraObjCollection and IsFullSCAlgebra" ],
    function( A )
    local paras, q, n, e, dim, coeffs, T, empty, i, j, R, zero, Fam, gens;

    # Create the structure constants table.
    paras:= ParametersOfSingerAlgebra( A );
    q:= paras[1];
    n:= paras[2];
    e:= paras[3];
    dim:= Dimension( A );
    coeffs:= List( [ 0, e .. q^n-1 ], ke -> CoefficientsQadic( ke, q ) );
    T:= [];
    empty:= MakeImmutable( [ [], [] ] );
    for i in [ 1 .. dim ] do
      T[i]:= [];
      for j in [ 1 .. i-1 ] do
        T[i][j]:= T[j][i];
      od;
      for j in [ i .. dim ] do
        if q <= MaximumList( coeffs[i] + coeffs[j], 0 ) then
          T[i][j]:= empty;
        else
          T[i][j]:= MakeImmutable( [ [ i+j-1 ], [ 1 ] ] );
        fi;
      od;
    od;
    R:= LeftActingDomain( A );
    zero:= Zero( R );
    T[ dim+1 ]:= 1;
    T[ dim+2 ]:= zero;

    # Set the necessary entries in the family.
    Fam:= ElementsFamily( FamilyObj( A ) );
    Fam!.sctable:= T;
    Fam!.names:= MakeImmutable( List( [ 0 .. dim-1 ],
                     i -> Concatenation( "b", String( i ) ) ) );
    Fam!.zerocoeff:= zero;
    Fam!.defaultTypeDenseCoeffVectorRep :=
        NewType( Fam, IsSCAlgebraObj and IsDenseCoeffVectorRep );
    SetZero( Fam, ObjByExtRep( Fam, ListWithIdenticalEntries( dim, zero ) ) );

    # Set the algebra generators.
    gens:= MakeImmutable( List( IdentityMat( dim, R ),
               x -> ObjByExtRep( Fam, x ) ) );
    SetGeneratorsOfAlgebra( A, gens );
    SetGeneratorsOfAlgebraWithOne( A, gens );
    SetOne( A, gens[1] );

    # Delegate to the library method for full s.c. algebras,
    # which has a lower rank.
    TryNextMethod();
    end );


#############################################################################
##
#M  Representative( <A> )
#M  GeneratorsOfAlgebra( <A> )
#M  GeneratorsOfAlgebraWithOne( <A> )
##
##  Note that we cannot use 'RedispatchOnCondition' here,
##  because we have only the attribute tester 'HasCanonicalBasis'
##  that may be missing,
##  whereas 'RedispatchOnCondition' checks for missing property values
##  plus their testers.
##
InstallMethod( Representative,
    [ "IsSingerAlgebra" ],
    function( A )
    if HasCanonicalBasis( A ) then
      TryNextMethod();
    fi;

    # Set the necessary data and redispatch.
    CanonicalBasis( A );
    return Representative( A );
    end );


InstallMethod( GeneratorsOfAlgebra,
    [ "IsSingerAlgebra" ],
    function( A )
    if HasCanonicalBasis( A ) then
      TryNextMethod();
    fi;

    # Set the necessary data and redispatch.
    CanonicalBasis( A );
    return GeneratorsOfAlgebra( A );
    end );


InstallMethod( GeneratorsOfAlgebraWithOne,
    [ "IsSingerAlgebra" ],
    function( A )
    if HasCanonicalBasis( A ) then
      TryNextMethod();
    fi;

    # Set the necessary data and redispatch.
    CanonicalBasis( A );
    return GeneratorsOfAlgebraWithOne( A );
    end );


#############################################################################
##
#M  MinimalDegreeOfSingerAlgebra( <A> )
#M  MinimalDegreeOfSingerAlgebra( <q>, <e> )
##
##  If the <Ref Attr="LoewyStructureInfo"/> value of the Singer algebra
##  <A>A</A> is known then use it.
##  If the cheap criteria suffice then take their result.
#T  (TODO: Add more such criteria!)
##  If the dimension of the algebra is small then use the algebra
##  also if just the parameters <A>q</A> and <A>e</A> are given.
##  Otherwise, call the hard method for <A>q</A> and <A>e</A>.
##
InstallMethod( MinimalDegreeOfSingerAlgebra,
    [ "IsSingerAlgebra" ],
    function( A )
    local paras, m, z, data;

    if HasLoewyStructureInfo( A ) then
      return JuliaToGAP( IsInt,
                 Julia.Base.get( LoewyStructureInfo( A ),
                                 JuliaSymbol( "m" ), 0 ) );
    fi;
    paras:= ParametersOfSingerAlgebra( A );
    m:= JuliaToGAP( IsInt, Julia.LoewyStructure.MinimalDegreeCheap(
            paras[1], paras[2], paras[3] ) );
    if m <> 0 then
      return m;
    fi;
    z:= ( paras[1] ^ paras[2] - 1 ) / paras[3];
    if z < 10^6 then
      return JuliaToGAP( IsInt,
                 Julia.Base.get( LoewyStructureInfo( A ),
                                 JuliaSymbol( "m" ), 0 ) );
    else
      return MinimalDegreeOfSingerAlgebra( paras[1], paras[3] );
    fi;
    end );
    
InstallMethod( MinimalDegreeOfSingerAlgebra,
    [ "IsPosInt", "IsPosInt" ],
    function( q, e )
    if q = 1 then
      Error( "<q> must be an integer > 1" );
    fi;
    return JuliaToGAP( IsInt,
               Julia.LoewyStructure.MinimalDegree( q, GAPToJulia( e ) ) );
    end );


#############################################################################
##
#M  LoewyLength( <A> )
#M  LoewyLength( <q>, <n>, <e> )
##
##  If <A> is given then compute its Loewy vector (hopefully just fetching
##  stored data).
##  If the parameters are given then compute the complete information.
##
#T  TODO: In both cases, do not compute these data when we know
#T        that the upper bound is attained
#T        (for that, refer to the paper when it has appeared).
##
InstallMethod( LoewyLength,
    [ "IsSingerAlgebra" ],
    A -> Length( DimensionsLoewyFactors( A ) ) );

InstallMethod( LoewyLength,
    [ "IsPosInt", "IsPosInt", "IsPosInt" ],
    function( q, n, e )
    local res;

    if q = 1 then
      Error( "<q> must be an integer > 1" );
    fi;
    res:= Julia.LoewyStructure.LoewyLayersData( q, n, e );
    res:= Julia.Base.get( res, JuliaSymbol( "ll" ), 0 );
    return JuliaToGAP( IsInt, res );
    end );


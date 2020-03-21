##############################################################################
##
##  finvar.gi
##
##  functionality for polynomial invariants of finite groups
##
##  K a field,
##  G a permutation group on n points or matrix group over K of dimension n,
##  P = K[x_1, ..., x_n] a polynomial ring
##  R = P^G the ring of invariants, a subset of P
##


##############################################################################
##
##  some auxiliary functions
##
InstallMethod( Value,
    IsElmsCollsX,
    [ "IsSingularObject and IsPolynomial", "IsHomogeneousList", "IsList" ],
    function( pol, vars, imgs )
    local n, res, ppol, len, i, c, exp, j;

    n:= Length( vars );
    res:= JuliaPointer( Zero( imgs[1] ) );
    ppol:= JuliaPointer( pol );
    len:= Julia.Base.length( ppol );
    for i in [ 0 .. len-1 ] do
      c:= Julia.Singular.coeff( ppol, i );
#T Note:
#T We cannot convert this from Julia,
#T the coefficients are Singular.n_Q,
#T and there is no conversion back to rationals!
      exp:= JuliaToGAP( IsList, Julia.Singular.exponent( ppol, i ) );
      if IsZero( exp ) then
        c:= c * JuliaPointer( One( imgs[1] ) );
#T We want a generic function, thus we would need generic \*!
#T (At the moment, this is possible only if both vars and imgs live in Julia,
#T one more reason to move this code to Julia.)
      else
        for j in [ 1 .. n ] do
          if exp[j] <> 0 then
            c:= c * JuliaPointer( imgs[j] )^exp[j];
          fi;
        od;
      fi;
      res:= res + c;
    od;

    return SingularElement( pol, res );
    end );


ValueX:= function( pol, vars, imgs, bas, tpowers )
    local n, extrep, res, one, i, mon, coe, c, j, pos;

    vars:= List( vars, IndeterminateNumberOfUnivariateRationalFunction );
    n:= Length( vars );
    extrep:= ExtRepPolynomialRatFun( pol );
    if Length( extrep ) = 0 then
      return Zero( imgs[1] );
    fi;
    res:= Zero( imgs[1] );
    one:= One( imgs[1] );

    for i in [ 2, 4 .. Length( extrep ) ] do
      mon:= extrep[ i-1 ];
      coe:= Coefficients( bas, extrep[i] ) * tpowers;
      if IsEmpty( mon ) then
        c:= tpowers[1];
      else
        c:= one;
        for j in [ 2, 4 .. Length( mon ) ] do
          pos:= Position( vars, mon[j-1] );
          c:= c * imgs[ pos ]^mon[j];
        od;
      fi;
      res:= res + coe * c;
    od;

    return res;
    end;


##############################################################################
##
#M  InvariantRing( <G> )
#M  InvariantRing( <G>, <K> )
#M  InvariantRing( <G>, <K>, <n> )
#M  InvariantRing( <G>, <P> )
##
InstallMethod( InvariantRing,
    [ "IsPermGroup" ],
    G -> InvariantRing( G,
             PolynomialRing( Rationals, LargestMovedPoint( G ) ) ) );

InstallMethod( InvariantRing,
    [ "IsMatrixGroup" ],
    G -> InvariantRing( G,
             PolynomialRing( Rationals, DimensionOfMatrixGroup( G ) ) ) );

InstallMethod( InvariantRing,
    [ "IsPermGroup", "IsField" ],
    function( G, K )
    return InvariantRing( G, PolynomialRing( K, LargestMovedPoint( G ) ) );
    end );

InstallMethod( InvariantRing,
    [ "IsMatrixGroup", "IsField" ],
    function( G, K )
    return InvariantRing( G, PolynomialRing( K, DimensionOfMatrixGroup( G ) ) );
    end );

InstallMethod( InvariantRing,
    [ "IsPermGroup", "IsField", "IsPosInt" ],
    function( G, K, n )
    return InvariantRing( G, PolynomialRing( K, n ) );
    end );

InstallMethod( InvariantRing,
    [ "IsGroup", "IsPolynomialRing" ],
    function( G, P )
    local n;

    n:= Length( IndeterminatesOfPolynomialRing( P ) );
    if IsPermGroup( G ) then
      if n < LargestMovedPoint( G ) then
        Error( "<G> moves a point larger than the number of indet." );
      fi;
    elif IsMatrixGroup( G ) then
      if n <> DimensionOfMatrixGroup( G ) then
        Error( "the number of indeterminates differs from ",
               "the dimension of <G>" );
      elif not IsSubset( LeftActingDomain( P ), FieldOfMatrixGroup( G ) ) then
        Error( "field of <G> not contained in coeff. field of <P>" );
      fi;
    else
      Error( "<G> must be a permutation group or a matrix group" );
    fi;

    # Just create the object.
    return ObjectifyWithAttributes( rec(), NewType( FamilyObj( P ),
               IsAlgebraWithOne and IsInvariantRing and IsAttributeStoringRep ),
               LeftActingDomain, LeftActingDomain( P ),
               UnderlyingGroup, G,
               ParentAttr, P );
    end );


##############################################################################
##
#M  ImageOfPolynomial( <R>, <pol>, <mat> )
#M  ImageOfPolynomial( <R>, <pol>, <perm> )
##
InstallMethod( ImageOfPolynomial,
    [ "IsPolynomialRing", "IsPolynomial", "IsMatrixObj" ],
    function( R, pol, mat )
    local indets;

    indets:= IndeterminatesOfPolynomialRing( R );
    return Value( pol, indets, indets * mat, One( R ) );
    end );

InstallMethod( ImageOfPolynomial,
    [ "IsPolynomialRing", "IsPolynomial", "IsPerm" ],
    function( R, pol, perm )
    local indets;

    indets:= IndeterminatesOfPolynomialRing( R );
    return Value( pol, indets, Permuted( indets, perm ), One( R ) );
    end );


##############################################################################
##
#M  IsInvariant( <R>, <pol>, <g> )
#M  IsInvariant( <R>, <pol>, <G> )
##
InstallMethod( IsInvariant,
    [ "IsPolynomialRing", "IsPolynomial", "IsMatrixObj" ],
    function( R, pol, mat )
      return ImageOfPolynomial( R, pol, mat ) = pol;
    end );

InstallMethod( IsInvariant,
    [ "IsPolynomialRing", "IsPolynomial", "IsMatrixGroup" ],
    function( R, pol, G )
      return ForAll( GeneratorsOfGroup( G ), x -> IsInvariant( R, pol, x ) );
    end );

InstallMethod( IsInvariant,
    [ "IsPolynomialRing", "IsPolynomial", "IsPerm" ],
    function( R, pol, mat )
      return ImageOfPolynomial( R, pol, mat ) = pol;
    end );

InstallMethod( IsInvariant,
    [ "IsPolynomialRing", "IsPolynomial", "IsPermGroup" ],
    function( R, pol, G )
      return ForAll( GeneratorsOfGroup( G ), x -> IsInvariant( R, pol, x ) );
    end );


##############################################################################
##
#M  \in( <f>, <R> )
##
InstallMethod( \in,
    IsElmsColls,
    [ "IsPolynomial", "IsInvariantRing" ],
    function( pol, R )
      return IsInvariant( Parent( R ), pol, UnderlyingGroup( R ) );
    end );


##############################################################################
##
#M  MolienInfo( <R> )
##
##  Store a list of length three,
##  coefficients of the numerator, coefficients of the denominator,
##  known coefficients (initially empty).
##
InstallMethod( MolienInfo,
    [ "IsInvariantRing" ],
    function( R )
    local P, G, vars, interval, z, I, num, den, i, elms, n, D, new, g;

    P:= Parent( R );
    if Characteristic( P ) <> 0 then
      Error( "<R> is expected to have characteristic 0" );
    fi;
    G:= UnderlyingGroup( R );

    vars:= IndeterminatesOfPolynomialRing( P );

    interval:= 10;

    z:= vars[1];  # indet. for the Molien series
    I:= One( G );
    num:= Zero( z );
    den:= z^0;
    i:= 0;
    elms:= Elements( G );
# better run over conjugacy class representatives ...
    if IsPermGroup( G ) then
      n:= LargestMovedPoint( G );
      elms:= List( elms, x -> PermutationMat( x, n ) );
      I:= elms[1];
    fi;
    for D in elms do
      i:= i + 1;
      new:= Determinant( I - z * D );
#T for Singular objects: DeterminantMatDivFree?
      num:= num * new + den;
      den:= den * new;
      if i mod interval = 0 then
        g:= Gcd( num, den );
        num:= num / g;
        den:= den / g;
      fi;
    od;

    # Normalize the constant terms of numerator and denominator.
    # (This takes care also of the division by the group order.)
    num:= CoefficientsOfUnivariatePolynomial( num );
    if num[1] <> 1 then
      num:= num / num[1];
    fi;
    den:= CoefficientsOfUnivariatePolynomial( den );
    if den[1] <> 1 then
      den:= den / den[1];
    fi;

    return [ num, den, [] ];
    end );


##############################################################################
##
#F  EvaluateRationalFunction( <numcoeffs>, <dencoeffs>, <d>, <init> )
##
##  This is an auxiliary function for 'EvaluateMolienSeries'.
##  It computes the first '<d>+1' coefficients of the series expansion of the
##  quotient of the polynomials whose coefficients are given by
##  <numcoeffs> and <dencoeffs>.
##  Initial values which are stored in the list <init> are used,
##  this list is changed in place.
##
##  If numerator and denominator are <M>\sum_{{i=0}}^n a_i z^i</M> and
##  <M>\sum_{{i=0}}^m b_i z^i</M>, respectively,
##  then their quotient is <M>\sum_{{i=0}}^{\infty} c_i z^i</M>,
##  with <M>c_i = ( a_i - \sum_{{k=1}}^i b_k c_{{i-k}} ) / b_0</M>.
##
BindGlobal( "EvaluateRationalFunction",
    function( numcoeffs, dencoeffs, d, init )
    local n, m, i, new, k;

    n:= Length( numcoeffs );
    m:= Length( dencoeffs );
    for i in [ Length( init )+1 .. d+1 ] do
      # degree i-1
      if i <= n then
        new:= numcoeffs[i];
      else
        new:= 0;
      fi;
      for k in [ 1 .. Minimum( i, m )-1 ] do
        new:= new - dencoeffs[k+1] * init[i-k];
      od;
      init[i]:= new / dencoeffs[1];
    od;

    return init;
    end );


##############################################################################
##
#F  EvaluateMolienSeries( <R>, <d> )
##
InstallGlobalFunction( EvaluateMolienSeries, function( R, d )
    local info;

    if not IsInvariantRing( R ) then
      Error( "<R> must be an invariant ring" );
    fi;
    info:= MolienInfo( R );
    return EvaluateRationalFunction( info[1], info[2], d, info[3] );
    end );


##############################################################################
##
#F  MonomialsOfGivenDegree( <R>, <d> )
##
InstallGlobalFunction( MonomialsOfGivenDegree, function( R, d )
    if not IsInt( d ) or d < 0 then
      Error( "<d> must be a nonnegative integer" );
    elif d = 0 then
      return [ One( R ) ];
    fi;

    return List( UnorderedTuples( IndeterminatesOfPolynomialRing( R ), d ),
                 Product );
    end );


##############################################################################
##
#M  ReynoldsOperator( <R> )
##
InstallMethod( ReynoldsOperator,
    [ "IsInvariantRing" ],
    function( R )
    local vars, G;

    vars:= IndeterminatesOfPolynomialRing( Parent( R ) );
    G:= UnderlyingGroup( R );
    if IsPermGroup( G ) then
      return List( Elements( G ), p -> Permuted( vars, p ) );
    else
      return List( Elements( G ), m -> vars * m );
    fi;
    end );


##############################################################################
##
#M  ReynoldsOperator( <R>, <pol> )
##
InstallMethod( ReynoldsOperator,
    [ "IsInvariantRing", "IsPolynomial" ],
    function( R, pol )
    local vars, res, rey, row;

    vars:= IndeterminatesOfPolynomialRing( Parent( R ) );
    res:= Zero( pol );
    rey:= ReynoldsOperator( R );
    for row in rey do
      res:= res + Value( pol, vars, row );
    od;

#   return res / NumberRows( rey );
#T NumberRows is not applicable to a list of lists of Singular polynomials!
    return res / Length( rey );
    end );


##############################################################################
##
#M  ComputedBasesOfInvariantsOfGivenDegree( <R> )
##
InstallMethod( ComputedBasesOfInvariantsOfGivenDegree,
    [ "IsInvariantRing" ],
    R -> [ [ One(R) ] ] );


##############################################################################
##
#F  BasisOfInvariantsOfGivenDegree( <R>, <d> )
##
#T  in homalg:
#T  use BasisOfRowModule?
#T  (RingsForHomalg/gap/Singular.gi)

InstallGlobalFunction( BasisOfInvariantsOfGivenDegree, function( R, d )
    local known, dim, mat, mon, extmon, zero, rey, m, res, ext, row, i;

    if not IsInvariantRing( R ) then
      Error( "<R> must be an invariant ring" );
    fi;

    if Characteristic( R ) <> 0 then
      Error( "currently only in characteristic zero" );
    fi;

    known:= ComputedBasesOfInvariantsOfGivenDegree( R );
    if IsBound( known[ d+1 ] ) then
      return known[ d+1 ];
    fi;

    dim:= EvaluateMolienSeries( R, d )[ d+1 ];
    if dim = 0 then
      known[ d+1 ]:= [];
      return known[ d+1 ];
    fi;

    # Take all monomials of degree d.
    # (There are $(d+n-1 \choose d)$ such monomials.)
    mat:= [];
    mon:= MonomialsOfGivenDegree( Parent( R ), d );
    extmon:= List( mon, m -> ExtRepPolynomialRatFun( m )[1] );
    SortParallel( extmon, mon );
    zero:= 0 * [ 1 .. Length( mon ) ];

    # Apply the Reynolds operator.
    for m in mon do
      res:= ReynoldsOperator( R, m );
      if not IsZero( res ) then
        ext:= ExtRepPolynomialRatFun( res );
#T here we cannot use Nemo or Singular polynomials!
        row:= ShallowCopy( zero );
        for i in [ 1, 3 .. Length( ext )-1 ] do
          row[ PositionSorted( extmon, ext[i] ) ]:= ext[ i+1 ];
        od;
        Add( mat, row );
      fi;
    od;

    if Length( mat ) = 0 then
      Error( "there should be an invariant monomial of degree <d>, ",
             "according to the Molien series" );
    fi;
    res:= List( SemiEchelonMatDestructive( mat ).vectors, x -> x * mon );
    if Length( res ) <> dim then
      Error( "wrong dimension?" );
    fi;

    known[ d+1 ]:= res;
    return res;
    end );


##############################################################################
##
##  auxiliary functions for using Homalg
##
DeclareAttribute( "HomalgDataForFinvar", IsInvariantRing );

InstallMethod( HomalgDataForFinvar,
    [ "IsInvariantRing" ],
    function( R )
    local vars, n, F, q, r, bas, tpowers, minpol, cond, root, minpolstr, t, i;

    vars:= IndeterminatesOfPolynomialRing( Parent( R ) );
    n:= Length( vars );
    F:= LeftActingDomain( R );
    if IsPrimeField( F ) then
      q:= HomalgFieldOfRationalsInSingular();
      r:= PolynomialRing( q,
              List( [1 .. n ], i -> Concatenation( "x", String(i) ) ) );
      bas:= fail;
      tpowers:= fail;
    else
      # supply the minimal polynomial
      if IsAlgebraicExtension( F ) and HasDefiningPolynomial( F ) then
        # holds for fields in
        minpol:= DefiningPolynomial( F );
        bas:= CanonicalBasis( F );
      elif IsCyclotomicCollection( F ) and IsCyclotomicField( F ) then
        cond:= Conductor( F );
        minpol:= CyclotomicPolynomial( Rationals, cond );
        root:= E( cond );
        bas:= Basis( F, List( [ 0 .. Phi( cond )-1 ], i -> root^i ) );
      elif Length( GeneratorsOfField( F ) ) = 1 then
        root:= GeneratorsOfField( F )[1];
        minpol:= MinimalPolynomial( Rationals, root );
        bas:= Basis( F, List( [ 0 .. Degree( minpol )-1 ], i -> root^i ) );
      else
        Error( "cannot determine a defining polynomial for <F> ",
               "over its prime field" );
      fi;

      minpolstr:= StringOfUnivariateRationalPolynomialByCoefficients(
                      CoefficientsOfLaurentPolynomial( minpol )[1], "t" );
      q:= HomalgFieldOfRationalsInSingular( "t", minpolstr );
      r:= PolynomialRing( q,
              List( [1 .. n ], i -> Concatenation( "x", String(i) ) ) );
      t:= HomalgExternalRingElement(
              homalgSendBlocking( [ "t" ], [ "poly" ], homalgStream( q ) ),
              r  );
      tpowers:= [ 1, t ];
      for i in [ 2 .. Degree( minpol )-1 ] do
        Add( tpowers,
             homalgSendBlocking( [ Concatenation( "t^", String(i) ) ],
                                 [ "poly" ], homalgStream( q ) ) );
      od;
    fi;

    return rec(
                q:= q,
                r:= r,
                bas:= bas,
                tpowers:= tpowers,
                singindets:= IndeterminatesOfPolynomialRing( r ),
              );
    end );

BindGlobal( "PolynomialsToSingular",
    function( pols, indets, homalgdata )
    if homalgdata.bas = fail then
      return List( pols, p -> Value( p, indets, homalgdata.singindets ) );
    else
      # Also the coefficients must be mapped.
      return List( pols, p -> ValueX( p, indets, homalgdata.singindets,
                                  homalgdata.bas, homalgdata.tpowers ) );
    fi;
    end );

BindGlobal( "IdealDimension",
    function( singpols )
    local cmd, dim;

    # Create the first argument.
    cmd:= Concatenation( [ "dim(std(ideal(" ], singpols, [ ")))" ] );

    # Call the Homalg function.
    dim:= homalgSendBlocking( cmd, "need_output",
              HOMALG_IO.Pictograms.AffineDimension );

    return Int( dim );
    end );


##############################################################################
##
#M  PrimaryInvariants( <R> )
##
InstallMethod( PrimaryInvariants,
    [ "IsInvariantRing" ],
    function( R )
    local vars, n, homalgdata, d, P, i, B, dom, iter, ddim, coeffs, p, cand;

    if Characteristic( R ) <> 0 then
      Error( "<R> is expected to have characteristic 0" );
    fi;

    vars:= IndeterminatesOfPolynomialRing( Parent( R ) );
    n:= Length( vars );

    homalgdata:= HomalgDataForFinvar( R );

    # We have to find n primary invariants.
    d:= 1;
    P:= [];
    i:= n;

    while i > 0 do
      # Compute with invariants of degree d.
      Info( InfoInvariants, 1,
            "PrimaryInvariants: consider degree ", d );
      B:= BasisOfInvariantsOfGivenDegree( R, d );
      if Length( B ) = 1 then
        if i > IdealDimension( PolynomialsToSingular( Concatenation( P, B ), vars, homalgdata ) ) then
          P:= Concatenation( P, B );
          i:= i-1;
        fi;
      elif 0 < Length( B ) then
        dom:= Integers^Length( B );
        iter:= Iterator( dom );
#T should be an iterator for the ring of integers of K
        ddim:= IdealDimension( PolynomialsToSingular( Concatenation( P, B ), vars, homalgdata ) );
        while i > ddim do
          # Find a linear combination p of the invariants of degree d,
          # over the ring of integers of K,
          # such that the dimension of the ideal spanned by
          # 'Concatenation( P, [ p ] )' is less than 'i'.
          while true do
            coeffs:= NextIterator( iter );
            while Gcd( coeffs ) <> 1 do
              coeffs:= NextIterator( iter );
            od;
            p:= coeffs * B;
#T here p may have coefficients over an ext. field
            cand:= Concatenation( P, [ p ] );
            Info( InfoInvariants, 1,
                  "PrimaryInvariants: test coeffs ", coeffs );
            if IdealDimension( PolynomialsToSingular( cand, vars, homalgdata ) ) < i then
              P:= cand;
              i:= i - 1;
              Info( InfoInvariants, 1,
                    "PrimaryInvariants: set i to ", i );
              break;
            fi;
          od;
        od;
      fi;
      d:= d + 1;
    od;

    return P;
    end );


##############################################################################
##
#M  Degree( <pol> ) . . . . . . . . . . . . . .  for a multivariate polynomial
##
InstallOtherMethod( Degree,
    [ "IsRationalFunction" ],
    function( pol )
    local extnum, extden;

    extnum:= ExtRepNumeratorRatFun( pol );
    extden:= ExtRepDenominatorRatFun( pol );

    return MaximumList( List( extnum{ [ 1, 3 .. Length( extnum ) - 1 ] },
                          l -> Sum( l{ [ 2, 4 .. Length( l ) ] }, 0 ) ), 0 )
         - MaximumList( List( extden{ [ 1, 3 .. Length( extden ) - 1 ] },
                          l -> Sum( l{ [ 2, 4 .. Length( l ) ] }, 0 ) ), 0 );
    end );


##############################################################################
##
#F  DegreesOfSecondaryInvariants( <R>, <primary> )
##
BindGlobal( "DegreesOfSecondaryInvariants", function( R, primary )
    local info, fam, molnum, molden, z, primden;

    info:= MolienInfo( R );
    fam:= FamilyObj( 0 );
    molnum:= UnivariatePolynomialByCoefficients( fam, info[1] );
    molden:= UnivariatePolynomialByCoefficients( fam, info[2] );
    z:= UnivariatePolynomialByCoefficients( fam, [ 0, 1 ] );
    primden:= Product( List( primary, Degree ), d -> 1 - z^d );

    return CoefficientsOfUnivariatePolynomial( molnum * primden / molden );
    end );


##############################################################################
##
#M  SecondaryInvariants( <R>[, <primary>] )
##
InstallMethod( SecondaryInvariants,
    [ "IsInvariantRing" ],
    R -> SecondaryInvariants( R, PrimaryInvariants( R ) ) );

InstallMethod( SecondaryInvariants,
    [ "IsInvariantRing", "IsList" ],
    function( R, primary )
    local vars, homalgdata, stream, singpols, degrees, result, i, B, tofind,
          pol, singpol;

    # Alg. 3.5.2
    # Compute a Groebner basis of the ideal spanned by the primary invariants.
    vars:= IndeterminatesOfPolynomialRing( Parent( R ) );
    homalgdata:= HomalgDataForFinvar( R );
    stream:= homalgStream( homalgdata.q );
    singpols:= PolynomialsToSingular( PrimaryInvariants( R ), vars, homalgdata );
    homalgSendBlocking(
        Concatenation( [ "ideal gb = std( ideal( " ], singpols, [ " ) )" ] ),
        "need_command", stream );

    # Calculate the degrees of the secondary invariants,
    # using the Molien series and the degrees of the primary invariants.
    degrees:= DegreesOfSecondaryInvariants( R, primary );

    result:= [ One( R ) ];

    for i in [ 2 .. Length( degrees ) ] do
      if degrees[i] <> 0 then
        # Calculate a basis of the homogeneous component of degree i-1.
        B:= BasisOfInvariantsOfGivenDegree( R, i-1 );
        tofind:= degrees[i];
        for pol in B do
          # Find an element from this basis whose reduction modulo the
          # above Groebner basis lies outside the space which we have already.
          singpol:= PolynomialsToSingular( [ pol ], vars, homalgdata )[1];
          if homalgSendBlocking( [ "reduce( ", singpol, ", gb, 1 )" ],
                 "need_output", stream ) <> "0" then
            Add( result, pol );
            Add( singpols, singpol );
            homalgSendBlocking(
                Concatenation( [ "ideal gb = std( ideal( " ], singpols, [ " ) )" ] ),
                "need_command", stream );
            tofind:= tofind - 1;
            if tofind = 0 then
              break;
            fi;
          fi;
        od;
      fi;
    od;

    if HasPrimaryInvariants( R ) and PrimaryInvariants( R ) = primary then
      SetSecondaryInvariants( R, result );
    fi;

    return result;
    end );


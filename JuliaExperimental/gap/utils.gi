


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "utils.jl" ) );

ImportJuliaModuleIntoGAP( "GAPUtilsExperimental" );


#############################################################################
##
##  Declare filters.
##


#############################################################################
##
##
##
DeclareAttribute( "JuliaPointer", IsObject );


##############################################################################
##
#! @Arguments obj
#! @Returns a &Julia; object
#! @Description
#!  For an object <A>obj</A> with attribute <Ref Attr="JuliaPointer"/>,
#!  this function returns the value of this attribute.
InstallMethod( ConvertedToJulia,
    [ "HasJuliaPointer" ],
    obj -> JuliaPointer( obj ) );


#############################################################################
##
##
##  'result' is bound only if <A>func</A> returned a value.
##
##  'Julia_time' measures the wall clock time between the start and the end
##  of the computations;
##  this includes both the &GAP; and the &Julia; computations.
##
##  'GAP_time' measures the &GAP; runtime of the computations;
##  this does apparently include most of the time needed by computations
##  in &Julia;, but for example *not* times spent in <C>sleep</C> calls.
##
##  Try to understand better how this works!
##
BindGlobal( "CallFuncListWithTimings", function( func, args )
    local tic, toq, start, result, diff, stop;

    tic:= Julia.Base.tic;
    toq:= Julia.Base.toq;
    start:= Runtime();
    tic();
    result:= CallFuncListWrap( func, args );
    stop:= Runtime();
    diff:= toq();

    if Length( result ) = 1 then
      return rec( result:= result,
                  GAP_time:= stop - start,
                  Julia_time:= Int( 1000 * ConvertedFromJulia( diff ) ) );
    else
      return rec( result:= result,
                  GAP_time:= stop - start,
                  Julia_time:= Int( 1000 * ConvertedFromJulia( diff ) ) );
    fi;
    end );


#############################################################################
##
#F  JuliaArrayOfFmpz( <coeffs> )
##
##  For a list <A>coeffs</A> of integers, this function creates
##  a &Julia; array that contains the corresponding &Julia; objects of type
##  <C>fmpz</C>.
##
BindGlobal( "JuliaArrayOfFmpz", function( coeffs )
    local arr, i, fmpz, parse, alp, entry, map;

    arr:= [];
    i:= 1;
    fmpz:= JuliaFunction( "fmpz", "Nemo" );
    parse:= JuliaFunction( "parse", "Base" );
    alp:= ConvertedToJulia( 16 );
    for entry in coeffs do
      if IsSmallIntRep( entry ) then
        arr[i]:= entry;
      else
        arr[i]:= parse( fmpz, HexStringInt( entry ), alp );
      fi;
      i:= i + 1;
    od;
    map:= JuliaFunction( "map", "Base" );
    arr:= map( fmpz, ConvertedToJulia( arr ) );

    return arr;
    end );


#############################################################################
##
#F  JuliaArrayOfFmpq( <coeffs> )
##
##  For a list <A>coeffs</A> of rationals, this function creates
##  a &Julia; array that contains the corresponding &Julia; objects of type
##  <C>fmpq</C>.
##
BindGlobal( "JuliaArrayOfFmpq", function( coeffs )
    local arr, i, fmpz, fmpq, div, parse, alp, entry, num, den, map;

    arr:= [];
    i:= 1;
    fmpz:= JuliaFunction( "fmpz", "Nemo" );
    fmpq:= JuliaFunction( "fmpq", "Nemo" );
    div:= Julia.Base.("//");
    parse:= JuliaFunction( "parse", "Base" );  # why???
    alp:= ConvertedToJulia( 16 );
    for entry in coeffs do
      if IsSmallIntRep( entry ) then
        arr[i]:= entry;
      elif IsInt( entry ) then
        arr[i]:= parse( fmpz, HexStringInt( entry ), alp );
      else
        num:= NumeratorRat( entry );
        den:= DenominatorRat( entry );
        if not IsSmallIntRep( num ) then
          num:= parse( fmpz, HexStringInt( num ), alp );
        fi;
        if not IsSmallIntRep( den ) then
          den:= parse( fmpz, HexStringInt( den ), alp );
        fi;
        arr[i]:= div( fmpq( num ), fmpq( den ) );
      fi;
      i:= i + 1;
    od;
    map:= JuliaFunction( "map", "Base" );
    arr:= map( fmpq, ConvertedToJulia( arr ) );

    return arr;
    end );


##############################################################################
##
#F  JuliaMatrixFromGapMatrix( <gapmatrix> )
##
##  <gapmatrix> must be a matrix of small integers.
##
BindGlobal( "JuliaMatrixFromGapMatrix", function( gapmatrix )
    local juliamatrix;

    juliamatrix:= ConvertedToJulia( gapmatrix );  # nested array
    return Julia.GAPUtilsExperimental.MatrixFromNestedArray( juliamatrix );
    end );


#############################################################################
##
#E


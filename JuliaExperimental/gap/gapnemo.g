


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "gapnemo.jl" ) );


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


#############################################################################
##
#E


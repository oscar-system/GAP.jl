


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
    return Julia.Base.map( Julia.Nemo.fmpz, GAPToJulia( coeffs ) );
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
    local arr, i, fmpz, fmpq, div, entry, num, den;

    arr:= [];
    i:= 1;
    fmpz:= Julia.Nemo.fmpz;
    fmpq:= Julia.Nemo.fmpq;
    div:= Julia.Base.("//");
    for entry in coeffs do
      if IsInt( entry ) then
        arr[i]:= entry;
      else
        num:= GAPToJulia( NumeratorRat( entry ) );
        den:= GAPToJulia( DenominatorRat( entry ) );
        arr[i]:= div( fmpq( num ), fmpq( den ) );
      fi;
      i:= i + 1;
    od;
    arr:= Julia.Base.map( fmpq, GAPToJulia( arr ) );

    return arr;
    end );


#############################################################################
##
#E


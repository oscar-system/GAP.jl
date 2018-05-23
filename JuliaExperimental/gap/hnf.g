##############################################################################
##
##  hnf.g
##
##  an example for calling a Nemo function for computing a result in GAP,
##  compute the Hermite normal form of a GAP integer matrix
##
##  The Julia utilities are implemented in 'julia/hnf.jl'.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "hnf.jl" ) );

ImportJuliaModuleIntoGAP( "GAPHNFModule" );
ImportJuliaModuleIntoGAP( "Nemo" );


#! @Arguments intmat
#! @Returns a Julia object
#! @Description
#!  For a matrix <A>intmat</A> of integers,
#!  this function creates the matrix of <C>Nemo.fmpz</C> integers in Julia
#!  that has the same entries.
BindGlobal( "NemoIntegerMatrix_Eval", function( mat )
    local str, row;

    # Turn the integers into strings, and use 'JuliaEvalString'.
    str:= "Nemo.ZZ[";
    for row in mat do
      Append( str, JoinStringsWithSeparator( List( row, String ), " " ) );
      Append( str, ";" );
    od;
    str[ Length( str ) ]:= ']';
    return JuliaEvalString( str );
end );


##
##  <mat> is assumed to be a list of lists of rationals.
##
BindGlobal( "NemoMatrix_fmpq", function( mat )
    local arr, i, fmpz, fmpq, div, parse, map, alp, row, entry, num, den, s;

    # Convert the entries to 'Nemo.fmpq' objects,
    # and use 'MatrixSpace' for creating the matrix in Julia.
    arr:= [];
    i:= 1;
    fmpz:= Julia.Nemo.fmpz;
    fmpq:= Julia.Nemo.fmpq;
    div:= Julia.Base.( "//" );
    parse:= Julia.Base.parse;
    map:= Julia.Base.map;
    alp:= JuliaBox( 16 );
    for row in mat do
      for entry in row do
        if IsSmallIntRep( entry ) then
          arr[i]:= entry;
        elif IsInt( entry ) then
          arr[i]:= parse( fmpz, HexStringInt( entry ), alp );
        else
          num:= parse( fmpz, HexStringInt( NumeratorRat( entry ) ), alp );
          den:= parse( fmpz, HexStringInt( DenominatorRat( entry ) ), alp );
          arr[i]:= div( num, den );
        fi;
        i:= i + 1;
      od;
    od;
    arr:= map( fmpq, JuliaBox( arr ) );
    s:= JuliaFunction( "MatrixSpace", "Nemo" );
    s:= s( Julia.Nemo.QQ, NumberRows( mat ), NumberColumns( mat ) );

    return s( arr );
end );



##
##  <mat> is assumed to be a list of lists of integers.
##
BindGlobal( "NemoMatrix_fmpz", function( mat )
    local arr, i, fmpz, parse, alp, row, entry, map, s;

    # Convert the entries to 'Nemo.fmpz' objects,
    # and use 'MatrixSpace' for creating the matrix in Julia.
    arr:= [];
    i:= 1;
    fmpz:= JuliaFunction( "fmpz", "Nemo" );
    parse:= JuliaFunction( "parse", "Base" );
    alp:= JuliaBox( 16 );
    for row in mat do
      for entry in row do
        if IsSmallIntRep( entry ) then
          arr[i]:= entry;
        else
          arr[i]:= parse( fmpz, HexStringInt( entry ), alp );
        fi;
        i:= i + 1;
      od;
    od;
    map:= JuliaFunction( "map", "Base" );
    arr:= map( fmpz, JuliaBox( arr ) );
    s:= JuliaFunction( "MatrixSpace", "Nemo" );
    s:= s( Julia.Nemo.ZZ, NumberRows( mat ), NumberColumns( mat ) );

    return s( arr );
end );


##
##  The argument can be created with different methods ...
##
BindGlobal( "HermiteNormalFormIntegerMatUsingNemo", function( juliamat )
    local juliahnf, result, getindex;

    # Compute the HNF in Julia.
    juliahnf:= Julia.Nemo.hnf( juliamat );

    # Reformat in Julia s. t. the result can be translated back to GAP.
    result:= Julia.GAPHNFModule.unpackedNemoMatrixFmpz( juliahnf );

    # Translate the Julia object to GAP.
    getindex:= Julia.Base.getindex;
    if JuliaUnbox( getindex( result, 1 ) ) = "int" then
      # The entries are small integers.
      return JuliaStructuralUnbox( getindex( result, 2 ) );
    else
      # The entries are hex strings encoding integers.
      return List( JuliaUnbox( getindex( result, 2 ) ),
                   row -> List( JuliaUnbox( row ),
                                x -> IntHexString( JuliaUnbox( x ) ) ) );
    fi;
end );


##############################################################################
##
#E


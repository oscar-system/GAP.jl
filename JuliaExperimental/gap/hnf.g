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


# provide the GAP function that creates the right Nemo object
# (here: a matrix of type 'Nemo.fmpz_mat') from a GAP matrix
#T 'BigInt' is currently not supported by JuliaInterface,
#T I have no better idea than calling 'JuliaEvalString'
#T for translating the GAP matrix to Julia.
BindGlobal( "NemoIntegerMatrix", function( mat )
    local str, row;

    str:= "ZZ[";
    for row in mat do
      Append( str, JoinStringsWithSeparator( List( row, String ), " " ) );
      Append( str, ";" );
    od;
    str[ Length( str ) ]:= ']';
    return JuliaEvalString( str );
end );


BindGlobal( "HNFIntMatUsingNemo", function( gapmat )
    local juliamat, juliahnf, result;

    # Translate to Julia.
    juliamat:= NemoIntegerMatrix( gapmat );

    # Compute the HNF in Julia.
    juliahnf:= Julia.Nemo.hnf( juliamat );

    # Reformat in Julia s. t. the result can be translated back to GAP.
    result:= Julia.GAPHNFModule.unpackedNemoMatrix( juliahnf );

    # Translate the Julia object to GAP.
    return JuliaUnbox( result );
end );


##############################################################################
##
#E


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

JuliaImportPackage( "Nemo" );


##
##  <mat> is assumed to be a list of lists of rationals.
##
BindGlobal( "NemoMatrix_fmpq", function( mat )
    local arr, i, fmpz, div, row, entry;

    # Convert the entries to 'Nemo.fmpq' objects,
    # and use 'MatrixSpace' for creating the matrix in Julia.
    arr:= [];
    i:= 1;
    fmpz:= Julia.Nemo.fmpz;
    div:= Julia.Base.( "//" );
    for row in mat do
      for entry in row do
        if IsInt( entry ) then
          arr[i]:= entry;
        else
          arr[i]:= div( fmpz( NumeratorRat( entry ) ),
                        fmpz( DenominatorRat( entry ) ) );
        fi;
        i:= i + 1;
      od;
    od;

    return Julia.Nemo.matrix( Julia.Nemo.QQ,
               NumberRows( mat ), NumberColumns( mat ),
               Julia.Base.map( Julia.Nemo.fmpq, GAPToJulia( arr ) ) );
end );


#! @Arguments intmat
#! @Returns a Julia object
#! @Description
#!  For a matrix <A>intmat</A> of integers,
#!  this function creates the matrix of <C>Nemo.fmpz</C> integers in Julia
#!  that has the same entries.
BindGlobal( "NemoMatrix_fmpz",
    mat -> Julia.Nemo.matrix( Julia.Nemo.ZZ,
               NumberRows( mat ), NumberColumns( mat ),
               Julia.Base.map( Julia.Nemo.fmpz,
                   GAPToJulia( Concatenation( mat ) ) ) ) );


##  ...
BindGlobal( "GAPMatrix_fmpz_mat", function( nemomat )
    local result;

     # Reformat in Julia s. t. the result can be translated back to GAP.
    result:= Julia.GAPHNFModule.unpackedNemoMatrixFmpz( nemomat );

    # Translate the Julia object to GAP.
    return JuliaToGAP( IsList, result, true );
end );


##
##  The argument can be created with different methods.
##
BindGlobal( "HermiteNormalFormIntegerMatUsingNemo", function( juliamat )
    local juliahnf;

    # Compute the HNF in Julia.
    juliahnf:= Julia.Nemo.hnf( juliamat );

    # Translate the Julia object to GAP.
    return GAPMatrix_fmpz_mat( juliahnf );
end );


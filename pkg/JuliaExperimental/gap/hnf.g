#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
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
    local arr, i, ZZRingElem, div, row, entry;

    # Convert the entries to 'Nemo.QQFieldElem' objects,
    # and use 'matrix_space' for creating the matrix in Julia.
    arr:= [];
    i:= 1;
    ZZRingElem:= Julia.Nemo.ZZRingElem;
    div:= Julia.Base.( "//" );
    for row in mat do
      for entry in row do
        if IsInt( entry ) then
          arr[i]:= entry;
        else
          arr[i]:= div( ZZRingElem( NumeratorRat( entry ) ),
                        ZZRingElem( DenominatorRat( entry ) ) );
        fi;
        i:= i + 1;
      od;
    od;

    return Julia.Nemo.matrix( Julia.Nemo.QQ,
               NumberRows( mat ), NumberColumns( mat ),
               Julia.Base.map( Julia.Nemo.QQFieldElem, GAPToJulia( arr ) ) );
end );


#! @Arguments intmat
#! @Returns a Julia object
#! @Description
#!  For a matrix <A>intmat</A> of integers,
#!  this function creates the matrix of <C>Nemo.ZZRingElem</C> integers in Julia
#!  that has the same entries.
BindGlobal( "NemoMatrix_fmpz",
    mat -> Julia.Nemo.matrix( Julia.Nemo.ZZ,
               NumberRows( mat ), NumberColumns( mat ),
               Julia.Base.map( Julia.Nemo.ZZRingElem,
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


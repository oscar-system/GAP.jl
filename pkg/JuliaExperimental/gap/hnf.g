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


##############################################################################
##
##  Notify the Julia part.
##
JuliaImportPackage( "Nemo" );


##
##  <mat> is assumed to be a list of lists of rationals.
##
BindGlobal( "NemoMatrix_fmpq", mat -> Julia.Nemo.QQMatrix( mat ) );


#! @Arguments intmat
#! @Returns a Julia object
#! @Description
#!  For a matrix <A>intmat</A> of integers,
#!  this function creates the matrix of <C>Nemo.ZZRingElem</C> integers in Julia
#!  that has the same entries.
BindGlobal( "NemoMatrix_fmpz",  mat -> Julia.Nemo.ZZMatrix( mat ) );


##  ...
BindGlobal( "GAPMatrix_fmpz_mat", nemomat -> GAP_jl.GapObj( nemomat ) );


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


#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "utils.jl" ) );


#############################################################################
##
##  Declare filters.
##


##############################################################################
##
#F  JuliaMatrixFromGapMatrix( <gapmatrix> )
##
##  <gapmatrix> must be a matrix of small integers.
##
BindGlobal( "JuliaMatrixFromGapMatrix", function( gapmatrix )
    local juliamatrix;

    juliamatrix:= GAPToJulia( gapmatrix );  # nested array
    return Julia.GAPUtilsExperimental.MatrixFromNestedArray( juliamatrix );
    end );


#############################################################################
##
#E


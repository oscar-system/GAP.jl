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
##  some general utility functions
##

module GAPUtilsExperimental

"""
    MatrixFromNestedArray( lst )
> Return a 2-dim array created from the 1-dim array of 1-dim arrays `lst`.
> (Note that GAP's `GAPToJulia` creates nested arrays.)
"""
function MatrixFromNestedArray( lst ) return copy( hcat( lst... )' ) end


"""
    NestedArrayFromMatrix( lst )
> Return an array of 1-dim arrays created from the 2-dim array `lst`.
> (Note that GAP's `JuliaToGAP` expects nested arrays.)
"""
function NestedArrayFromMatrix( mat )
    return map( i -> mat[i,:], 1:size(mat,1) )
end

end


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

module GAPHNFModule

import Nemo

function fitsGAPSmallIntRep( x::Nemo.ZZRingElem )
    return -2^60 <= x && x < 2^60
end

"""
    unpackedNemoMatrixFmpz( nemomat::Nemo.ZZMatrix )
> Return a 1-dim. array of 1-dim. arrays of Julia integers,
> corresponding to the rows of `nemomat`.
"""
function unpackedNemoMatrixFmpz( nemomat::Nemo.ZZMatrix )
    # Turn the Nemo matrix into a 2-dim. Julia array of integers.
    mat = Matrix{BigInt}( nemomat )

    # Turn the 2-dim. array into a 1-dim. array of 1-dim. arrays
    # of small integers (which can then be unboxed with 'JuliaToGAP').
    return Main.GAPUtilsExperimental.NestedArrayFromMatrix( mat )
end

end


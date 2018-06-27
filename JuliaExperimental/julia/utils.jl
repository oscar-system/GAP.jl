##############################################################################
##
##  utils.jl
##
##  some general utility functions
##

module GAPUtilsExperimental

export MatrixFromNestedArray

doc"""
    MatrixFromNestedArray( lst )
> Return a 2-dim array created from the 1-dim array of 1-dim arrays `lst`.
> (Note that GAP's `ConvertedToJulia` creates nested arrays.)
"""
function MatrixFromNestedArray( lst ) return hcat( lst... )' end

end


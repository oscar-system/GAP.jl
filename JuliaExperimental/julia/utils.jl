##############################################################################
##
##  utils.jl
##
##  some general utility functions
##

module GAPUtilsExperimental

export MatrixFromNestedArray

##  Turn a nested 1-dim. array (as created by 'JuliaBox'
##  into a 2-dim. array

doc"""
    MatrixFromNestedArray( lst )
> Return a 2-dim array from the 1-dim array of 1-dim arrays `lst`
"""
function MatrixFromNestedArray( lst ) return hcat( lst... )' end

end


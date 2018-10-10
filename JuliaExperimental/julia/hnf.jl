###############################################################################
##
##  hnf.jl
##

module GAPHNFModule

using Nemo

export unpackedNemoMatrixFmpz

function fitsGAPSmallIntRep( x::Nemo.fmpz )
    return -2^60 <= x && x < 2^60
end

"""
    unpackedNemoMatrixFmpz( nemomat::Nemo.fmpz_mat[, tryint::Bool = true] )
> Return a tuple `(<kind>, <arr>)` where <arr> is a 1-dim. array
> of 1-dim. arrays (corresponding to the rows of `nemomat`),
> and <kind> is either `"int"` (the entries are small integers)
> or `"string"` (the entries are hex strings).
> This format is suitable for calling `ConvertedFromJulia` from GAP.
"""
function unpackedNemoMatrixFmpz( nemomat::Nemo.fmpz_mat, tryint::Bool = true )
    m, n = size( nemomat )

    if tryint == true
      # Check whether the entries are small enough for being unboxed
      # to small integers in GAP, i. e., in the range '[ -2^60 .. 2^60-1 ]'.
      fits = [ fitsGAPSmallIntRep( nemomat[i,j] ) for i in 1:m, j in 1:n ]
      if all( fits )
        # Turn the Nemo matrix into a 2-dim. Julia array of integers.
        mat = Matrix{Int}( nemomat )

        # Turn the 2-dim. array into a 1-dim. array of 1-dim. arrays
        # of small integers (which can then be unboxed with 'ConvertedFromJulia').
        return ( "int", map( i -> mat[i,:], 1:size(mat,1) ) )
      end
    end

    # Either we *want* to create a nested array of strings,
    # or some entry is too large.
    # Turn the 2-dim. array into a 1-dim. array of 1-dim. arrays
    # (which can then be unboxed with 'ConvertedFromJulia').
    return ( "string", [ [ hex( nemomat[i,j] ) for j in 1:n ] for i in 1:n ] )
end

end


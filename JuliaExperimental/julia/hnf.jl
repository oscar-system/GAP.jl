###############################################################################
##
##  hnf.jl
##

module GAPHNFModule

using Nemo

export unpackedNemoMatrix

function unpackedNemoMatrix( nemomat )
    mat = Matrix{Int}( nemomat )
    return map( i -> mat[i,:], 1:size(mat,1) )
end

end



##  auxiliary code for translating between GAP's cyclotomics
##  and Nemo's number field elements

using Nemo

juliabox_cycs = function( lst, denom, N, mode )
    local f, x, n, m, mat, d, res

    f, x = Nemo.AnticCyclotomicField( N, "x" )
    n = length( lst )
    m = MatrixSpace( ZZ, n, length( lst[1] ) )
    mat = m( hcat( lst... )' )
    d = Nemo.fmpz( denom )
    res = Array{Any}( n )
    for i = 1:n
      res[i] = Nemo.elem_from_mat_row( f, mat, i, d )
    end

    if mode == 0
      return res[1]
    else
      return res
    end
end


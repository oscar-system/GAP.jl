##############################################################################
##
##  numfield.jl
##
##  some utility functions needed in 'gap/numfield.g'
##

module GAPNumberFields

import Base: length, similar, zeros, ==, isless, *, one, inv, ^, /

using Nemo
# using Hecke

export MatrixFromNestedArray, Nemo_Matrix_over_NumberField
# export JuliaBox_Cyclotomics


##  Turn a nested 1-dim. array (as created by 'JuliaBox'
##  into a 2-dim. array

function MatrixFromNestedArray( lst ) return hcat( lst... )' end


##  Create an 'm' by 'n' matrix of elements in the field 'f'
##  from a list 'lst' (of length 'm' times 'n')
##  of integer coefficient vectors,
##  for which 'denom' is the common denominator.

function Nemo_Matrix_over_NumberField( f, m, n, lst, denom )
    local pos, mat, d, i, j

    pos = 1
    mat = Array{Any}( m, n )
    d = Nemo.fmpz( denom )
    for i = 1:m
      for j = 1:n
        mat[i,j] = Nemo.elem_from_mat_row( f, lst, pos, d )
        pos = pos + 1
      end
    end

    return matrix( f, mat )
#   return matrix( f, m, n, mat )  # in older Nemo versions ...
end


#T as soon as 'Qab.jl' is officially available in Hecke:
# ##  Translate between GAP's cyclotomics and Hecke's QabElem objects.
# ##  'lst' is a list of integral coefficient vectors w.r.t.
# ##  the 'N'-th cyclotomic field,
# ##  'denom' is the common denominator.
# ##
# ##  The result is an array of field elements.
# 
# JuliaBox_Cyclotomics = function( N, lst, denom )
#     local f, x, n, m, mat, d, res
# 
#     f, x = Nemo.CyclotomicField( N, "x" )
#     n = length( lst )
#     m = MatrixSpace( ZZ, n, length( lst[1] ) )
#     mat = m( hcat( lst... )' )
#     d = Nemo.fmpz( denom )
#     res = Array{Any}( n )
#     for i = 1:n
#       res[i] = QabElem( Nemo.elem_from_mat_row( f, mat, i, d ), N )
#     end
# 
#     return res
# end

end


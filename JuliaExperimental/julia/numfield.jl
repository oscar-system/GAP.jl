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

export MatrixFromNestedArray, Nemo_Matrix_over_NumberField,
       CoefficientVectorsNumDenOfNumberFieldElement,
       MatricesOfCoefficientVectorsNumDen

# export ConvertedToJulia_Cyclotomics


##  Turn a nested 1-dim. array (as created by 'ConvertedToJulia'
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


##  Create the coefficient vector of the element `elm`,
##  as an array of length `d` and consisting of `fmpq` objects.

function CoefficientVectorOfNumberFieldElement( elm, d )
    local arr, i

    arr = Array{Nemo.fmpq,1}( d )
    for i = 1:d
      arr[i] = Nemo.coeff( elm, i-1 )
    end

    return arr
end


##  Create the vectors for numerator and denominator
##  of the coefficient vector of the element `elm`,
##  as arrays of length `d` and consisting of `fmpz` objects.

function CoefficientVectorsNumDenOfNumberFieldElement( elm, d )
    local num, den, i

    num = Array{Nemo.fmpz,1}( d )
    den = Array{Nemo.fmpz,1}( d )
    for i = 1:d
      num[i] = numerator( Nemo.coeff( elm, i-1 ) )
      den[i] = denominator( Nemo.coeff( elm, i-1 ) )
    end

    return num, den
end


##  2-dim. (m n) times d arrays of Nemo.fmpz elements

function MatricesOfCoefficientVectorsNumDen( nemomat, d )
    local m, n, num, den, i, j, resnum, resden

    m, n = size( nemomat )
    num = Array{Any,1}( 0 )
    den = Array{Any,1}( 0 )
    for i = 1:m
      for j = 1:n
        resnum, resden = CoefficientVectorsNumDenOfNumberFieldElement(
                             getindex( nemomat, i, j ), d )
        push!( num, resnum )
        push!( den, resden )
      end
    end

    return Nemo.matrix( Nemo.ZZ, hcat( num... )' ),
           Nemo.matrix( Nemo.ZZ, hcat( den... )' )
end


#T as soon as 'Qab.jl' is officially available in Hecke:
# ##  Translate between GAP's cyclotomics and Hecke's QabElem objects.
# ##  'lst' is a list of integral coefficient vectors w.r.t.
# ##  the 'N'-th cyclotomic field,
# ##  'denom' is the common denominator.
# ##
# ##  The result is an array of field elements.
# 
# ConvertedToJulia_Cyclotomics = function( N, lst, denom )
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


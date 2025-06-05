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
##  some utility functions needed in 'gap/numfield.g'
##

module GAPNumberFields

import Base: length, similar, zeros, ==, isless, *, one, inv, ^, /

import Nemo
# immport Hecke

function VectorToArray( mat )
    return map( i -> mat[1,i], 1:size( mat, 2 ) )
end


"""
    NemoElementOfNumberField( f, lst, denom )
> Return the element in the number field `f` for which `lst` is the array
> of numerators of the coefficients w.r.t. the defining polynomial of `f`,
> and `denom` is the common denominator.
"""
function NemoElementOfNumberField( f, lst, denom::Int )
    return Nemo.elem_from_mat_row( f, lst, 1, Nemo.ZZRingElem( denom ) )
end


"""
    Nemo_Matrix_over_NumberField( f, m, n, lst, denom )
> Return an `m` by `n` matrix of elements in the Nemo number field `f`
> from the list `lst` (which has length `m` times `n`)
> of integer coefficient vectors,
> for which `denom` is the common denominator.
"""
function Nemo_Matrix_over_NumberField( f, m::Int, n::Int, lst, denom::Int )
    local pos, mat, d, i, j

    pos = 1
    mat = Array{Any}( undef, m, n )
    d = Nemo.ZZRingElem( denom )
    for i = 1:m
      for j = 1:n
        mat[i,j] = Nemo.elem_from_mat_row( f, lst, pos, d )
        pos = pos + 1
      end
    end

    return matrix( f, mat )
#   return matrix( f, m, n, mat )  # in older Nemo versions ...
end


"""
    CoefficientVectorOfNumberFieldElement( elm::Nemo.nf_elem, d::Int )
> Return the coefficient vector of the number field element `elm`,
> as an array of length `d` and consisting of `Nemo.QQFieldElem` objects.
"""
function CoefficientVectorOfNumberFieldElement( elm::Nemo.nf_elem, d::Int )
    local arr, i

    arr = Vector{Nemo.QQFieldElem}( undef, d )
    for i = 1:d
      arr[i] = Nemo.coeff( elm, i-1 )
    end

    return arr
end


"""
    CoefficientVectorsNumDenOfNumberFieldElement( elm::Nemo.nf_elem, d::Int )
> Return the tuple that consists of the coefficient vectors
> of the numerators and the denominators of the coefficient vector
> of the number field element `elm`,
> as arrays of length `d` and consisting of `Nemo.ZZRingElem` objects.
"""
function CoefficientVectorsNumDenOfNumberFieldElement( elm, d )
    local num, den, i, onecoeff

    num = Vector{Nemo.ZZRingElem}( undef, d )
    den = Vector{Nemo.ZZRingElem}( undef, d )
    for i = 1:d
      onecoeff = Nemo.coeff( elm, i-1 )
      num[i] = numerator( onecoeff )
      den[i] = denominator( onecoeff )
    end

    return num, den
end


"""
    MatricesOfCoefficientVectorsNumDen( nemomat, d )
> Return the tuple that consists of two 2-dim. (m n) times `d` arrays
> of `Nemo.ZZRingElem` objects that describe the numerators and the denominators
> of the number field elements in the matrix `nemomat`.
"""
function MatricesOfCoefficientVectorsNumDen( nemomat, d )
    local m, n, num, den, i, j, resnum, resden

    m, n = size( nemomat )
    num = Vector{Any}( undef, 0 )
    den = Vector{Any}( undef, 0 )
    for i = 1:m
      for j = 1:n
        resnum, resden = CoefficientVectorsNumDenOfNumberFieldElement(
                             getindex( nemomat, i, j ), d )
        push!( num, resnum )
        push!( den, resden )
      end
    end

    return Nemo.matrix( Nemo.ZZ, copy( transpose( hcat( num... ) ) ) ),
           Nemo.matrix( Nemo.ZZ, copy( transpose( hcat( den... ) ) ) )
end


#T as soon as 'Qab.jl' is officially available in Hecke:
# """
#     GAPToJulia_Cyclotomics( N, lst, denom )
# > Return an array of n `QabElem` objects,
# > which correspond to the n entries of the array `lst`.
# > Each entry is the vector of numerators of the coefficient vector
# > of an element in the `N`-th cyclotomic field,
# > and `denom` is the common denominator.
# """
# GAPToJulia_Cyclotomics = function( N, lst, denom )
#     local f, x, n, m, mat, d, res
# 
#     f, x = Nemo.CyclotomicField( N, "x" )
#     n = length( lst )
#     m = matrix_space( Nemo.ZZ, n, length( lst[1] ) )
#     mat = m( copy( transpose( hcat( lst... ) ) ) )
#     d = Nemo.ZZRingElem( denom )
#     res = Array{Any}( undef, n )
#     for i = 1:n
#       res[i] = QabElem( Nemo.elem_from_mat_row( f, mat, i, d ), N )
#     end
# 
#     return res
# end

end


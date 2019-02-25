##############################################################################
##
##  gapnemo.jl
##
##  some utility functions for creating Nemo objects
##

module GAPNemoExperimental

import Nemo

"""
    fitsGAPSmallIntRep( x::Nemo.fmpz )
> Return `true` if `x` corresponds to a GAP integer in `IsSmallIntRep`,
> and `false` otherwise.
"""
function fitsGAPSmallIntRep( x::Nemo.fmpz )
    return -2^60 <= x && x < 2^60
end


function CoefficientsOfUnivarateNemoPolynomial( pol )
    return map( i -> Nemo.coeff( pol, i ), 0:(length(pol)-1) )
end

function CompanionMatrix( pol )
    coeff = CoefficientsOfUnivarateNemoPolynomial( pol )
    n = Nemo.length( pol )
    R = Nemo.base_ring( Nemo.parent( pol ) )
    mat = Nemo.zero_matrix( R, n, n )
    oneelm = one( R )
    for i in 1:n
      setindex!( mat, -coeff[i], n, i )
    end
    for i in 2:n
      setindex!( mat, oneelm, i-1, i )
    end
    return mat
end

"""
    CoefficientsNumDenOfFmpqArray( arr::Array{Nemo.fmpq,1}[, tryint::Bool = true] )
> Return a tuple `(<kind>, <arrnum>, <arrden>)` where <arrnum>, <arrden>
> are 1-dim. arrays of the numerators and denominators of the values in <arr>,
> and <kind> is either `"int"` (the entries are small integers)
> or `"string"` (the entries are hex strings).
> This format is suitable for calling `JuliaToGAP` from GAP.
"""
function CoefficientsNumDenOfFmpqArray( arr::Array{Nemo.fmpq,1}, tryint::Bool = true )
    n = length( arr )
    coeffsnum = map( i -> numerator( arr[i] ), 1:n )
    coeffsden = map( i -> denominator( arr[i] ), 1:n )

    if tryint == true
      # Check whether the entries are small enough for being unboxed
      # to small integers in GAP, i. e., in the range '[ -2^60 .. 2^60-1 ]'.
      fits = [ fitsGAPSmallIntRep( coeffsnum[i] ) for i in 1:n ]
      if all( [ fitsGAPSmallIntRep( coeffsnum[i] ) for i in 1:n ] ) &&
         all( [ fitsGAPSmallIntRep( coeffsden[i] ) for i in 1:n ] )
        return ( "int", map( Int, coeffsnum ), map( Int, coeffsden ) )
      end
    end

    # Either we *want* to create a nested array of strings,
    # or some entry is too large.
    # Turn the 2-dim. array into a 1-dim. array of 1-dim. arrays
    # (which can then be unboxed with 'JuliaToGAP').
    return ( "string", [ hex( coeffsnum[i] ) for i in 1:n ],
                       [ hex( coeffsden[i] ) for i in 1:n ] )
end

"""
    unfoldedNemoMatrix( nemomat )
> Return the `1 x (m n)` matrix obtained from the `m x n` matrix `nemomat`
> by concatenating its rows.
"""
function unfoldedNemoMatrix( nemomat )
    R = Nemo.base_ring( Nemo.parent( nemomat ) )
    T = Nemo.elem_type( R )
    m = Nemo.nrows( nemomat )
    n = Nemo.ncols( nemomat )
    l = T[]
    for i in 1:m
      for j in 1:n
        push!( l, nemomat[ i, j ] )
      end
    end
#T There must be a clever way to do this ....

    return Nemo.matrix( R, 1, n*m, l )
end

"""
    foldedNemoVector( nemovec, n )
> Return the `m x n` matrix obtained from the `1 x (m n)` matrix `nemovec`,
> by splitting `nemovec` into rows of length `n`.
"""
function foldedNemoVector( nemovec, n )
    R = Nemo.base_ring( Nemo.parent( nemovec ) )
    T = Nemo.elem_type( R )
    m = Nemo.ncols( nemovec )
    l = T[ nemovec[ 1, j ] for j in 1:m ]
    m = div( m, n )
#T There must be a clever way to do this ....

    return Nemo.matrix( R, m, n, l )
end

end


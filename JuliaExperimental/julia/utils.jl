##############################################################################
##
##  utils.jl
##
##  some general utility functions
##

module GAPUtilsExperimental

import Nemo

export MatrixFromNestedArray, CoefficientsNumDenOfNemoPolynomialFmpq,
       JuliaSourceFile

"""
    MatrixFromNestedArray( lst )
> Return a 2-dim array created from the 1-dim array of 1-dim arrays `lst`.
> (Note that GAP's `ConvertedToJulia` creates nested arrays.)
"""
function MatrixFromNestedArray( lst ) return hcat( lst... )' end


"""
    fitsGAPSmallIntRep( x::Nemo.fmpz )
> Return `true` if `x` corresponds to a GAP integer in `IsSmallIntRep`,
> and `false`otherwise.
"""
function fitsGAPSmallIntRep( x::Nemo.fmpz )
    return -2^60 <= x && x < 2^60
end


function CoefficientsOfUnivarateNemoPolynomialFmpq( pol::Nemo.fmpq_poly )
    return map( i -> Nemo.coeff( pol, i ), 0:(length(pol)-1) )
end


function NestedArrayFromMatrix( mat )
    return map( i -> mat[i,:], 1:size(mat,1) )
end


"""
    CoefficientsNumDenOfFmpqArray( arr::Array{Nemo.fmpq,1}[, tryint::Bool = true] )
> Return a tuple `(<kind>, <arrnum>, <arrden>)` where <arrnum>, <arrden>
> are 1-dim. arrays of the numerators and denominators of the values in <arr>,
> and <kind> is either `"int"` (the entries are small integers)
> or `"string"` (the entries are hex strings).
> This format is suitable for calling `ConvertedFromJulia` from GAP.
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
    # (which can then be unboxed with 'ConvertedFromJulia').
    return ( "string", [ hex( coeffsnum[i] ) for i in 1:n ],
                       [ hex( coeffsden[i] ) for i in 1:n ] )
end

"""
    JuliaSourceFile( func, types )
> Return the tuple `( filename, startline )`
> such that the source code of the method `func`
> that expects arguments of the types given in the tuple `types`
> can be found in the file `filename`, starting at line `startline`.
"""
function JuliaSourceFile( func, types )
    local meth::Method

    meth = which( func, types )
    return ( string( meth.file ), meth.line )
end

end


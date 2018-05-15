###############################################################################
##
##  realcyc.jl
##

module GAPRealCycModule

using Nemo

export arbCyc, isPositiveRealPartCyc, testRunCyc

doc"""
    arbCyc( coeffs::Array{Any,1}, R::Nemo.ArbField )
> Return the element in the Arb field that is defined by the real part
> of the cyclotomic integer with conductor `N = length( coeffs )`
> for which the integer `coeffs[k]` defines the coefficient
> of the root of unity `exp( 2*pi*I*(k-1) // N )`.
"""
function arbCyc( coeffs::Array{Any,1}, R::Nemo.ArbField )
    val::Nemo.arb = zero( R )
    N::Int = length( coeffs )

    for k = 1:N
      if coeffs[k] != 0
        val = val + coeffs[k] * cospi( fmpq( 2 * (k-1) // N ), R )
      end
    end

    return val
end

doc"""
    isPositiveRealPartCyc( coeffs::Array{Any,1} )
> Return `true` if the cyclotomic integer defined by the coefficients
> `coeffs` (see `arbCyc`) has positive real part, and `false` otherwise.
"""
function isPositiveRealPartCyc( coeffs::Array{Any,1} )
    prec::Int = 64
    while true
      R::Nemo.ArbField = Nemo.ArbField( prec )
      x::Nemo.arb = arbCyc( coeffs, R )
      if Nemo.ispositive( x )
        return true
      elseif Nemo.isnegative( x )
        return false
      end
      prec = 2 * prec
    end
end

function testRunCyc( coeffs::Array{Any,1}, num::Int )
    res = true
    for i = 1:num
      res = isPositiveRealPartCyc( coeffs )
    end
    return res
end

function arbCyc( coeffs::Array{Nemo.fmpz,1}, R::Nemo.ArbField )
    val::Nemo.arb = zero( R )
    N::Int = length( coeffs )

    for k = 1:N
      if coeffs[k] != 0
        val = val + coeffs[k] * cospi( fmpq( 2 * (k-1) // N ), R )
      end
    end

    return val
end

function isPositiveRealPartCyc( coeffs::Array{Nemo.fmpz,1} )
    prec::Int = 64
    while true
      R::Nemo.ArbField = Nemo.ArbField( prec )
      x::Nemo.arb = arbCyc( coeffs, R )
      if Nemo.ispositive( x )
        return true
      elseif Nemo.isnegative( x )
        return false
      end
      prec = 2 * prec
    end
end

end


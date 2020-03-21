###############################################################################
##
##  realcyc.jl
##

module GAPRealCycModule

import Nemo

"""
    arbCyc( coeffs::Vector, R::Nemo.ArbField )
> Return the element in the Arb field that is defined by the real part
> of the cyclotomic integer with conductor `N = length( coeffs )`
> for which the integer `coeffs[k]` defines the coefficient
> of the root of unity `exp( 2*pi*I*(k-1) // N )`.
"""
function arbCyc( coeffs::Vector, R::Nemo.ArbField )
    val::Nemo.arb = zero( R )
    N::Int = length( coeffs )
    for k = 1:N
      if coeffs[k] != 0
        val = val + coeffs[k] * cospi( Nemo.fmpq( 2 * (k-1) // N ), R )
      end
    end
    return val
end

"""
    isPositiveRealPartCyc( coeffs::Vector )
> Return a tuple `( bool, prec )`
> where `bool` is `true` if the cyclotomic integer defined by the coefficients
> vector `coeffs` (see `arbCyc`) has positive real part,
> and `false` otherwise,
> and `prec` is the precision (in bits) that was needed to decide the question.
> Note that this question can be answered whenever `coeffs` is not the
> zero vector and the precision is high enough.
"""
function isPositiveRealPartCyc( coeffs::Vector )
    prec::Int = 16
    while true
      R::Nemo.ArbField = Nemo.ArbField( prec )
      x::Nemo.arb = arbCyc( coeffs, R )
      if Nemo.ispositive( x )
        return ( true, prec )
      elseif Nemo.isnegative( x )
        return ( false, prec )
      end
      prec = 2 * prec
    end
end

function test_this_module()
    ok::Bool = true

    function shiftby( array, int )
      sum = map( x -> x + int, array )
      sum[1] = 0
      return sum
    end

    sqrt5 = [ 0, 1, -1, -1, 1 ]
    if ! isPositiveRealPartCyc( shiftby( 100 * sqrt5, 223 ) )[1]
      ok = false
    end
    if isPositiveRealPartCyc( shiftby( 100 * sqrt5, 224 ) )[1]
      ok = false
    end
    if ! isPositiveRealPartCyc( shiftby( 1000 * sqrt5, 2236 ) )[1]
      ok = false
    end
    if isPositiveRealPartCyc( shiftby( 1000 * sqrt5, 2237 ) )[1]
      ok = false
    end

    return ok
end

end


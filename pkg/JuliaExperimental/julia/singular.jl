###############################################################################
##
##  singular.jl
##

module GAPSingularModule

import Singular

function GAPExtRepOfSingularPolynomial( poly )
    coeffs = []
    exps = []
    for i in 0:(length( poly )-1)
      push!( coeffs, Singular.coeff( poly, i ) )
      push!( exps, Singular.exponent( poly, i ) )
    end
    return (coeffs, exps)
end

end


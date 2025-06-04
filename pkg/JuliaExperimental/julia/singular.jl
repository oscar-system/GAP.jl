#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
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


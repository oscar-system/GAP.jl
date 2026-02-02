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
##  some utility functions for creating Nemo objects
##

module GAPNemoExperimental

import Nemo

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

end


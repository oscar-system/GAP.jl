###############################################################################
##
##  singular.jl
##

module GAPSingularModule

using Singular

export SingularPolynomialRingWrapper

doc""" 
    The purpose of this function is just to handle *keyword arguments*.
    The following works:

    # keyword argument
    Singular.PolynomialRing( Singular.QQ, [ "x", "y" ], ordering = :lex )

    # (key, value) pairs after ';'
    Singular.PolynomialRing( Singular.QQ, [ "x", "y" ]; (:ordering, :lex) )

    # iterable expression after ';'
    Singular.PolynomialRing( Singular.QQ, [ "x", "y" ]; :ordering => :lex )

    But none of these has a suitable syntax for 'jl_call'.
    (Note the semicolon in the last two cases above.)
"""
function SingularPolynomialRingWrapper( dict::Dict{Any,Any} )
    return Singular.PolynomialRing( dict[ "ring" ], dict[ "indeterminates" ];
               cached = dict[ "cached" ],
               ordering = dict[ "ordering" ],
               ordering2 = dict[ "ordering2" ],
               degree_bound = dict[ "degree_bound" ] )
end

end


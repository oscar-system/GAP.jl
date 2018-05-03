function IsPrimeInt(a)
    return GAP.IsPrimeInt(a)
end

function Power2(a)
    # can be done automatic
    number = Int((Int(a.ptr)-1)/4)
    number = number ^ 2
    # is automatic
    number = number*4 + 1
    # can be done automatic
    return GAP.GapObj( Ptr{Void}( number ) )
end
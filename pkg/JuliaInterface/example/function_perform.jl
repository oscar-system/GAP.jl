module GapFunctionPerform

import Main.ForeignGAP: MPtr

function typed_func( a::MPtr, b::MPtr )
    return a;
end

function typed_func( a::MPtr, b::Int64 )
    return a;
end

function typed_func( a::Int64, b::MPtr )
    return a;
end

function typed_func( a::Int64, b::Int64 )
    return a;
end

end

function untyped_func(a, b)
    return a
end

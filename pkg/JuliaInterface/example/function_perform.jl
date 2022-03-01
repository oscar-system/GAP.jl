module GapFunctionPerform

import GAP_jll: GapObj

function typed_func(a::GapObj, b::GapObj)
    return a
end

function typed_func(a::GapObj, b::Int64)
    return a
end

function typed_func(a::Int64, b::GapObj)
    return a
end

function typed_func(a::Int64, b::Int64)
    return a
end

end

function untyped_func(a, b)
    return a
end

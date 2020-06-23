## Deprecated function names

function EvalString(cmd::String)
    @warn "Use GAP.evalstr instead of GAP.EvalString"
    return evalstr(cmd)
end

## Deprecated signatures

function julia_to_gap(obj::Any, recursive::Val{Recursive},
    recursion_dict = IdDict()) where {Recursive}
    return julia_to_gap(obj, recursion_dict; recursive = Recursive)
end

## Deprecated function names

function EvalString(cmd::String)
    @warn "Use GAP.evalstr instead of GAP.EvalString"
    return evalstr(cmd)
end

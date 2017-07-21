include("libgap.jl")

import Base: length

type Record
end

type List
end

type Permutation{sz}
end

# function EvalString(str :: String)
# #   Create stringstream
# #     readall
# #     return list of obj
# #     win.
# end

to_gap(str :: String)         = libgap_StringObj_String(str)
to_gap(v :: Int32)            = libgap_IntObj_Int(v)
to_gap(v :: Int64)            = libgap_IntObj_Int(v)

function to_gap(v :: Array{GapObj, 1})
    l = libgap_NewPList(length(v))
    libgap_SetLenPList(l, length(v))
    for i in 1:length(v)
        libgap_SetElmPList(l, i, v[i])
    end
    return l
end

function to_gap(v :: Array{Any, 1}) :: Array{GapObj, 1}
    return to_gap(map(to_gap, v))
end

function GAPFunctionPointer( name :: String )
    return libgap_ValueGlobal(name)
end

function GAPFunction(name :: String)
    return function(args...)
        func = libgap_ValueGlobal(name)
        gargs = []
        return libgap_CallFuncList(func, gargs)
    end
end

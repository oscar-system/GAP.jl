include("libgap.jl")

module GAP

import Base: length
import libgap

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

to_gap(str :: String)         = libgap.StringObj_String(str)
to_gap(v :: Int32)            = libgap.IntObj_Int(v)
to_gap(v :: Int64)            = libgap.IntObj_Int(v)

function to_gap(v :: Array{GapObj, 1}) :: GapObj
    l = libgap.NewPList(length(v))
    libgap.SetLenPList(l, length(v))
    for i in 1:length(v)
        libgap.SetElmPList(l, i, v[i])
    end
    return l
end

function to_gap(v :: AbstractArray) :: Array{GapObj, 1}
    return map(to_gap, v)
end

function GAPFunctionPointer( name :: String )
    return libgap.ValueGlobal(name)
end

function GAPFunction(name :: String)
    return function(args...)
        func = libgap.ValueGlobal(name)
        gargs = []
        return libgap.CallFuncList(func, gargs)
    end
end

end

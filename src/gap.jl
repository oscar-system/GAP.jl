include("libgap.jl")

type Record
end

type List
end

type Permutation{sz}
end

function EvalString(str :: String)
#   Create stringstream
#     readall
#     return list of obj
#     win.
end

to_gap(str :: String)         = libgap_StringObj_String(str)
to_gap(v :: Int32)            = libgap_IntObj_Int(v);
to_gap(v :: Int64)            = libgap_IntObj_Int(v);

function to_gap(v :: Array{GapObj, 1})

end

function to_gap(v :: Array{Any, 1})
    return to_gap(map(to_gap, v))
end

function GAPFunction(name :: String)
    return function(args...)
        func = libgap_ValueGlobal(name)
        gargs = []
        return libgap_CallFuncList(func, gargs)
    end
end

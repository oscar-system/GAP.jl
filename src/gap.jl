include("libgap.jl")

type Record
end

type List
end

type Permutation{sz}
end

function EvalString(str :: String)
    // Create stringstream
    // readall
    // return list of obj
    // win.
end

function to_gap(str :: String)
    return libgap_StringObj_String(str)
end

function to_gap(v :: Int32)
    return libgap_IntObj_Int(v)
end

function to_gap(v :: Int64)
    return libgap_IntObj_Int(v)
end

function to_gap(v :: Array{GapObj, 1})
end

function GAPFunction(str::name)
    return function(args...)
        func = libgap_ValueGlobal(name)
        gargs = []
        return libgap_CallFuncList(func, gargs)
    end
end

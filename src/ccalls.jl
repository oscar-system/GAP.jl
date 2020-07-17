## Internal ccall's

import Base: getproperty, hasproperty, setproperty!, propertynames

function RAW_GAP_TO_JULIA(ptr::Ptr{Cvoid})
    return ccall(:julia_gap, Any, (Ptr{Cvoid},), ptr)
end

function RAW_JULIA_TO_GAP(val::Any)::Ptr{Cvoid}
    return ccall(:gap_julia, Ptr{Cvoid}, (Any,), val)
end

function evalstr_ex(cmd::String)
    res = ccall(:GAP_EvalString, Any, (Ptr{UInt8},), cmd)
    return res
end

"""
    evalstr(cmd::String)

Let GAP execute the command(s) given by `cmd`;
if the last command has a result then return it,
otherwise return `nothing`.

# Examples
```jldoctest
julia> GAP.evalstr( "1+2" )
3

julia> GAP.evalstr( "x:= []" )
GAP: [  ]

julia> GAP.evalstr( "y:= 2; Add( x, 1 )" )

julia> GAP.evalstr( "x" )
GAP: [ 1 ]

```
"""
function evalstr(cmd::String)
    res = evalstr_ex(cmd * ";")
    if Globals.ISB_LIST( res[end], 2 )
      return res[end][2]
    else
      return
    end
end

function ValueGlobalVariable(name::String)
    gvar = ccall(:GAP_ValueGlobalVariable, Ptr{Cvoid}, (Ptr{UInt8},), name)
    return RAW_GAP_TO_JULIA(gvar)
end

function CanAssignGlobalVariable(name::String)
    # TODO: use symbol_to_gvar here, too`? Or conversely: convert
    ccall(:GAP_CanAssignGlobalVariable, Bool, (Ptr{UInt8},), name)
end

function AssignGlobalVariable(name::String, value::Any)
    if !CanAssignGlobalVariable(name)
        error("cannot assing to $name in GAP")
    end
    tmp = RAW_JULIA_TO_GAP(value)
    ccall(:GAP_AssignGlobalVariable, Cvoid, (Ptr{UInt8}, Ptr{Cvoid}), name, tmp)
end

function MakeString(val::String)::GapObj
    string = ccall(:GAP_MakeString, Any, (Ptr{UInt8},), val)
    return string
end

function CSTR_STRING(val::GapObj)::String
    char_ptr = ccall(:GAP_CSTR_STRING, Ptr{UInt8}, (Any,), val)
    return deepcopy(unsafe_string(char_ptr))
end

function CSTR_STRING_AS_ARRAY(val::GapObj)::Array{UInt8,1}
    string_len = Int64(ccall(:GAP_LenString, Cuint, (Any,), val))
    char_ptr = ccall(:GAP_CSTR_STRING, Ptr{UInt8}, (Any,), val)
    return deepcopy(unsafe_wrap(Array{UInt8,1}, char_ptr, string_len))
end


function NewPlist(length::Int64)
    o = ccall(:GAP_NewPlist, Any, (Int64,), length)
    return o
end

function NewPrecord(capacity::Int64)
    o = ccall(:GAP_NewPrecord, Any, (Int64,), capacity)
    return o
end

function NEW_MACFLOAT(x::Float64)
    o = ccall(:NEW_MACFLOAT, Any, (Cdouble,), x)
    return o
end

function ValueMacFloat(x::GapObj)
    o = ccall(:GAP_ValueMacFloat, Cdouble, (Any,), x)
    return o
end

function CharWithValue(x::Cuchar)
    o = ccall(:GAP_CharWithValue, Any, (Cuchar,), x)
    return o
end

function ElmList(x::GapObj, position)
    o = ccall(:GAP_ElmList, Ptr{Cvoid}, (Any, Culong), x, Culong(position))
    return RAW_GAP_TO_JULIA(o)
end

function NewJuliaFunc(x::Function)
    o = ccall(:NewJuliaFunc, Any, (Any,), x)
    return o
end

"""
    call_gap_func(func::GapObj, args...; kwargs...)

Call the GAP object `func` as a function,
with arguments `args...` and global GAP options `kwargs...`,
and returns the result if there is one, and `nothing` otherwise.

There is no argument number checking here, all checks on the arguments
are done by GAP itself.

For convenience, one can use the syntax `func(args...; kwargs...)`.

# Examples
```jldoctest
julia> GAP.Globals.Factors( 12 )
GAP: [ 2, 2, 3 ]

julia> g = GAP.Globals.SylowSubgroup( GAP.Globals.SymmetricGroup( 6 ), 2 )
GAP: Group([ (1,2), (3,4), (1,3)(2,4), (5,6) ])

julia> GAP.Globals.StructureDescription( g )
GAP: "C2 x D8"

julia> g = GAP.Globals.SylowSubgroup( GAP.Globals.SymmetricGroup( 6 ), 2 );

julia> GAP.Globals.StructureDescription( g, short = true )
GAP: "2xD8"

```
"""
function call_gap_func(func::GapObj, args...; kwargs...)
    global Globals
    options = false
    if length(kwargs) > 0
        kwargs_dict = Dict(kwargs)
        kwargs_rec = julia_to_gap(kwargs_dict)
        Globals.PushOptions(kwargs_rec)
        options = true
    end
    result = nothing
    try
        result = ccall(:call_gap_func, Any, (Any, Any), func, args)
    catch e
        if options
            Globals.ResetOptionsStack()
        end
        rethrow(e)
    end
    if options
        Globals.PopOptions()
    end
    return result
end

(func::GapObj)(args...; kwargs...) = call_gap_func(func, args...; kwargs...)


struct GlobalsType end

Base.show(io::IO, ::GlobalsType) = Base.show(io, "table of global GAP objects")

"""
    Globals

This is a global object that gives access to all global variables of the
current GAP session via `getproperty` and `setproperty!`.

# Examples
```jldoctest
julia> GAP.Globals.Size    # a global GAP function
GAP: <Attribute "Size">

julia> GAP.Globals.size    # there is no GAP variable with this name
ERROR: GAP variable size not bound
[...]

julia> hasproperty( GAP.Globals, :size )
false

julia> GAP.Globals.size = 17;

julia> hasproperty( GAP.Globals, :size )
true

julia> GAP.Globals.size
17

julia> GAP.Globals.Julia   # Julia objects can be values of GAP variables
Main

```
"""
const Globals = GlobalsType()

function getproperty(::GlobalsType, name::Symbol)
    v = ccall(:GAP_ValueGlobalVariable, Ptr{Cvoid}, (Ptr{UInt8},), name)
    if v === C_NULL
        error("GAP variable ", name, " not bound")
    end
    v = RAW_GAP_TO_JULIA(v)
    return v
end

function hasproperty(::GlobalsType, name::Symbol)
    v = ccall(:GAP_ValueGlobalVariable, Ptr{Cvoid}, (Ptr{UInt8},), name)
    return v !== C_NULL
end

function setproperty!(::GlobalsType, name::Symbol, val::Any)
    tmp = (val === nothing) ? C_NULL : RAW_JULIA_TO_GAP(val)
    ccall(:GAP_AssignGlobalVariable, Cvoid, (Ptr{UInt8}, Ptr{Cvoid}), name, tmp)
end

propertynames(::GlobalsType) = gap_to_julia(Vector{Symbol}, Globals.NamesGVars())

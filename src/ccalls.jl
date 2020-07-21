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
    res = res[end]
    if Globals.ISB_LIST(res, 2)
      return res[2]
    else
      return
    end
end

# We use @pure to notify Julia about the fact that the GAP kernel function
# GVarName is indeed pure, i.e., if called repeatedly with identical input,
# it will always produce the same output. This means the compiler can hoist
# it out of loops.
Base.@pure function GVarName(name::Union{AbstractString,Symbol})
    return ccall(:GVarName, Csize_t, (Ptr{UInt8},), name)
end

# low-level GAP kernel function for accessing the content of a global GAP
# variable; returns C_NULL if the variable is unbound.
function ValAutoGVar(gvar::Csize_t)
    return ccall(:ValAutoGVar, Ptr{Cvoid}, (Csize_t,), gvar)
end

function AssGVar(gvar::Csize_t, val::Ptr{Cvoid})
    ccall(:AssGVar, Cvoid, (Csize_t, Ptr{Cvoid}), gvar, val)
end

function IsReadOnlyGVar(gvar::Csize_t)
    return ccall(:IsReadOnlyGVar, Csize_t, (Csize_t,), gvar) != 0
end

function IsConstantGVar(gvar::Csize_t)
    return ccall(:IsConstantGVar, Csize_t, (Csize_t,), gvar) != 0
end


# Retrieve the value of a global GAP variable given its name. This function
# returns a raw Ptr value, and should only be called by plumbing code.
#
# We don't use the "official" libgap API to allow the Julia compiler to better
# optimize the code.
function _ValueGlobalVariable(name::Union{AbstractString,Symbol})
    #return ccall(:GAP_ValueGlobalVariable, Ptr{Cvoid}, (Ptr{UInt8},), name)
    return ValAutoGVar(GVarName(name))
end

function ValueGlobalVariable(name::Union{AbstractString,Symbol})
    v = _ValueGlobalVariable(name)
    return RAW_GAP_TO_JULIA(v)
end

# Test whether the global GAP variable with the given name can be assigned to.
#
# We don't use the "official" libgap API to allow the Julia compiler to better
# optimize the code.
function CanAssignGlobalVariable(name::Union{AbstractString,Symbol})
    #ccall(:GAP_CanAssignGlobalVariable, Bool, (Ptr{UInt8},), name)
    gvar = GVarName(name)
    return !IsReadOnlyGVar(gvar) && !IsConstantGVar(gvar)
end

# Assign a value to the global GAP variable with the given name. This function
# assigns a raw Ptr value, and should only be called by plumbing code.
#
# We don't use the "official" libgap API to allow the Julia compiler to better
# optimize the code.
function _AssignGlobalVariable(name::Union{AbstractString,Symbol}, value::Ptr{Cvoid})
    #ccall(:GAP_AssignGlobalVariable, Cvoid, (Ptr{UInt8}, Ptr{Cvoid}), name, value)
    return AssGVar(GVarName(name), value)
end

# Assign a value to the global GAP variable with the given name.
function AssignGlobalVariable(name::Union{AbstractString,Symbol}, value::Any)
    if !CanAssignGlobalVariable(name)
        error("cannot assing to $name in GAP")
    end
    tmp = RAW_JULIA_TO_GAP(value)
    _AssignGlobalVariable(name, tmp)
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
    try
        result = ccall(:call_gap_func, Any, (Any, Any), func, args)
        if options
            Globals.PopOptions()
        end
        return result
    catch
        if options
            Globals.ResetOptionsStack()
        end
        rethrow()
    end
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
    v = _ValueGlobalVariable(name)
    if v === C_NULL
        error("GAP variable ", name, " not bound")
    end
    v = RAW_GAP_TO_JULIA(v)
    return v
end

function hasproperty(::GlobalsType, name::Symbol)
    return _ValueGlobalVariable(name) !== C_NULL
end

function setproperty!(::GlobalsType, name::Symbol, val::Any)
    tmp = (val === nothing) ? C_NULL : RAW_JULIA_TO_GAP(val)
    _AssignGlobalVariable(name, tmp)
end

propertynames(::GlobalsType) = gap_to_julia(Vector{Symbol}, Globals.NamesGVars())

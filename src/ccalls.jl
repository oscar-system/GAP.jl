## Internal ccall's

import Base: getproperty, hasproperty, setproperty!, propertynames

#
# low-level GAP -> Julia conversion
#
function RAW_GAP_TO_JULIA(ptr::Ptr{Cvoid})
    # convert immediate ints and FFEs directly, to void (un)boxing
    as_int = reinterpret(Int, ptr)
    if as_int & 1 == 1
        return as_int >> 2
    elseif as_int & 2 == 2
        return reinterpret(FFE, ptr)
    end
    return ccall(:julia_gap, Any, (Ptr{Cvoid},), ptr)
end

#
# low-level Julia -> GAP conversion
#
function RAW_JULIA_TO_GAP(val::Any)::Ptr{Cvoid}
    return ccall(:gap_julia, Ptr{Cvoid}, (Any,), val)
end
#RAW_JULIA_TO_GAP(x::Bool) = x ? gap_true : gap_false
RAW_JULIA_TO_GAP(x::FFE) = reinterpret(Ptr{Cvoid}, x)
RAW_JULIA_TO_GAP(x::GapObj) = pointer_from_objref(x)
function RAW_JULIA_TO_GAP(x::Int)
    # convert x into a GAP immediate integer if it fits
    if x in -1<<60:(1<<60-1)
        return Ptr{Cvoid}(x << 2 | 1)
    end
    return ccall(:ObjInt_Int, Ptr{Cvoid}, (Int,), x)
end


function evalstr_ex(cmd::String)
    res = ccall(:GAP_EvalString, GapObj, (Ptr{UInt8},), cmd)
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


# Retrieve the value of a global GAP variable given its name. This function
# returns a raw Ptr value, and should only be called by plumbing code.
function _ValueGlobalVariable(name::Union{AbstractString,Symbol})
    return ccall(:GAP_ValueGlobalVariable, Ptr{Cvoid}, (Ptr{UInt8},), name)
end

function ValueGlobalVariable(name::Union{AbstractString,Symbol})
    v = _ValueGlobalVariable(name)
    return RAW_GAP_TO_JULIA(v)
end

# Test whether the global GAP variable with the given name can be assigned to.
function CanAssignGlobalVariable(name::Union{AbstractString,Symbol})
    ccall(:GAP_CanAssignGlobalVariable, Bool, (Ptr{UInt8},), name)
end

# Assign a value to the global GAP variable with the given name. This function
# assigns a raw Ptr value, and should only be called by plumbing code.
function _AssignGlobalVariable(name::Union{AbstractString,Symbol}, value::Ptr{Cvoid})
    ccall(:GAP_AssignGlobalVariable, Cvoid, (Ptr{UInt8}, Ptr{Cvoid}), name, value)
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
    string = ccall(:GAP_MakeString, GapObj, (Ptr{UInt8},), val)
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
    o = ccall(:GAP_NewPlist, GapObj, (Int64,), length)
    return o
end

function NewPrecord(capacity::Int64)
    o = ccall(:GAP_NewPrecord, GapObj, (Int64,), capacity)
    return o
end

function NEW_MACFLOAT(x::Float64)
    o = ccall(:NEW_MACFLOAT, GapObj, (Cdouble,), x)
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
    o = ccall(:NewJuliaFunc, GapObj, (Any,), x)
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
# this is the generic method which supports keyword arguments (mapped to GAP options)
# and goes through JuliaInterface, which is convenient but a bit slow.
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

# make all GapObj callable
(func::GapObj)(args...; kwargs...) = call_gap_func(func, args...; kwargs...)

#
# below several "fastpath" methods for call_gap_func follow which directly
# jump to the C handler functions, bypassing JuliaInterface, for optimal
# performance.
#

# 0 arguments
function call_gap_func(func::GapObj)
    fptr = GET_FUNC_PTR(func, 0)
    ret = ccall(fptr, Ptr{Cvoid}, (Ptr{Cvoid},), pointer_from_objref(func))
    return RAW_GAP_TO_JULIA(ret)
end

# 1 argument
function call_gap_func(func::GapObj, a1::Obj)
    fptr = GET_FUNC_PTR(func, 1)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        RAW_JULIA_TO_GAP(a1),
    )
    return RAW_GAP_TO_JULIA(ret)
end

# 2 arguments
function call_gap_func(func::GapObj, a1::Obj, a2::Obj)
    fptr = GET_FUNC_PTR(func, 2)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        RAW_JULIA_TO_GAP(a1),
        RAW_JULIA_TO_GAP(a2),
    )
    return RAW_GAP_TO_JULIA(ret)
end

# 3 arguments
function call_gap_func(func::GapObj, a1::Obj, a2::Obj, a3::Obj)
    fptr = GET_FUNC_PTR(func, 3)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        RAW_JULIA_TO_GAP(a1),
        RAW_JULIA_TO_GAP(a2),
        RAW_JULIA_TO_GAP(a3),
    )
    return RAW_GAP_TO_JULIA(ret)
end

# 4 arguments
function call_gap_func(func::GapObj, a1::Obj, a2::Obj, a3::Obj, a4::Obj)
    fptr = GET_FUNC_PTR(func, 4)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        RAW_JULIA_TO_GAP(a1),
        RAW_JULIA_TO_GAP(a2),
        RAW_JULIA_TO_GAP(a3),
        RAW_JULIA_TO_GAP(a4),
    )
    return RAW_GAP_TO_JULIA(ret)
end

# 5 arguments
function call_gap_func(func::GapObj, a1::Obj, a2::Obj, a3::Obj, a4::Obj, a5::Obj)
    fptr = GET_FUNC_PTR(func, 5)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        RAW_JULIA_TO_GAP(a1),
        RAW_JULIA_TO_GAP(a2),
        RAW_JULIA_TO_GAP(a3),
        RAW_JULIA_TO_GAP(a4),
        RAW_JULIA_TO_GAP(a5),
    )
    return RAW_GAP_TO_JULIA(ret)
end

# 6 arguments
function call_gap_func(func::GapObj, a1::Obj, a2::Obj, a3::Obj, a4::Obj, a5::Obj, a6::Obj)
    fptr = GET_FUNC_PTR(func, 6)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
        ),
        pointer_from_objref(func),
        RAW_JULIA_TO_GAP(a1),
        RAW_JULIA_TO_GAP(a2),
        RAW_JULIA_TO_GAP(a3),
        RAW_JULIA_TO_GAP(a4),
        RAW_JULIA_TO_GAP(a5),
        RAW_JULIA_TO_GAP(a6),
    )
    return RAW_GAP_TO_JULIA(ret)
end


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
        error("GAP variable $name not bound")
    end
    return RAW_GAP_TO_JULIA(v)
end

function hasproperty(::GlobalsType, name::Symbol)
    return _ValueGlobalVariable(name) !== C_NULL
end

function setproperty!(::GlobalsType, name::Symbol, val::Any)
    if !CanAssignGlobalVariable(name)
        error("cannot assing to $name in GAP")
    end
    tmp = (val === nothing) ? C_NULL : RAW_JULIA_TO_GAP(val)
    _AssignGlobalVariable(name, tmp)
end

propertynames(::GlobalsType) = gap_to_julia(Vector{Symbol}, Globals.NamesGVars())

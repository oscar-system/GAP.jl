## Internal ccall's

import Base: getproperty, hasproperty, setproperty!, propertynames

#
# low-level GAP -> Julia conversion
#
function _GAP_TO_JULIA(ptr::Ptr{Cvoid})
    ptr == C_NULL && return nothing
    # convert immediate ints and FFEs directly, to avoid (un)boxing
    as_int = reinterpret(Int, ptr)
    as_int & 1 == 1 && return as_int >> 2
    as_int & 2 == 2 && return reinterpret(FFE, ptr)
    tnum = TNUM_OBJ(ptr)
    if tnum < FIRST_EXTERNAL_TNUM
        if tnum == T_BOOL
            ptr == unsafe_load(cglobal((:GAP_True, libgap), Ptr{Cvoid})) && return true
            ptr == unsafe_load(cglobal((:GAP_False, libgap), Ptr{Cvoid})) && return false
        end
        return unsafe_pointer_to_objref(ptr)
    end
    return ccall((:julia_gap, JuliaInterface_path()), Any, (Ptr{Cvoid},), ptr)
end

#
# low-level Julia -> GAP conversion
#
_JULIA_TO_GAP(val::Any) = ccall((:gap_julia, JuliaInterface_path()), Ptr{Cvoid}, (Any,), val)
#_JULIA_TO_GAP(x::Bool) = x ? gap_true : gap_false
_JULIA_TO_GAP(x::FFE) = reinterpret(Ptr{Cvoid}, x)
_JULIA_TO_GAP(x::GapObj) = pointer_from_objref(x)

ObjInt_Int(x::Int) = ccall((:ObjInt_Int, libgap), Ptr{Cvoid}, (Int,), x)
function _JULIA_TO_GAP(x::Int)
    # convert x into a GAP immediate integer if it fits
    if x in -1<<60:(1<<60-1)
        return Ptr{Cvoid}(x << 2 | 1)
    end
    return ObjInt_Int(x)
end


function evalstr_ex(cmd::String)
    res = ccall((:GAP_EvalString, libgap), GapObj, (Cstring,), cmd)
    return res
end

"""
    evalstr(cmd::String)

Let GAP execute the command(s) given by `cmd`;
if an error occurs then report this error,
otherwise if the last command has a result then return it,
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
    if any(x->x[1] == false, res)
      # error
      global last_error
      # HACK HACK HACK: if there is an error string on the GAP side, call
      # error_handler to copy it into `last_error`
      if !Wrappers.IsEmpty(Globals._JULIAINTERFACE_ERROR_BUFFER)
        error_handler()
      end
      error("Error thrown by GAP: $(last_error[])")
    end
    res = res[end]
    if Wrappers.ISB_LIST(res, 2)
      return res[2]
    else
      return
    end
end


# Retrieve the value of a global GAP variable given its name. This function
# returns a raw Ptr value, and should only be called by plumbing code.
function _ValueGlobalVariable(name::Union{AbstractString,Symbol})
    return ccall((:GAP_ValueGlobalVariable, libgap), Ptr{Cvoid}, (Cstring,), name)
end

function ValueGlobalVariable(name::Union{AbstractString,Symbol})
    v = _ValueGlobalVariable(name)
    return _GAP_TO_JULIA(v)
end

# Test whether the global GAP variable with the given name can be assigned to.
function CanAssignGlobalVariable(name::Union{AbstractString,Symbol})
    ccall((:GAP_CanAssignGlobalVariable, libgap), Bool, (Cstring,), name)
end

# Assign a value to the global GAP variable with the given name. This function
# assigns a raw Ptr value, and should only be called by plumbing code.
function _AssignGlobalVariable(name::Union{AbstractString,Symbol}, value::Ptr{Cvoid})
    ccall((:GAP_AssignGlobalVariable, libgap), Cvoid, (Cstring, Ptr{Cvoid}), name, value)
end

# Assign a value to the global GAP variable with the given name.
function AssignGlobalVariable(name::Union{AbstractString,Symbol}, value::Any)
    if !CanAssignGlobalVariable(name)
        error("cannot assign to $name in GAP")
    end
    tmp = _JULIA_TO_GAP(value)
    _AssignGlobalVariable(name, tmp)
end

MakeString(val::String) = GC.@preserve val ccall((:MakeStringWithLen, libgap), GapObj, (Ptr{UInt8}, Culong), val, sizeof(val))
#TODO: As soon as libgap provides :GAP_MakeStringWithLen, use it.

function CSTR_STRING(val::GapObj)
    char_ptr = ccall((:GAP_CSTR_STRING, libgap), Ptr{UInt8}, (Any,), val)
    len = ccall((:GAP_LenString, libgap), Culong, (Any,), val)
    return deepcopy(unsafe_string(char_ptr, len))::String
end

function CSTR_STRING_AS_ARRAY(val::GapObj)::Vector{UInt8}
    string_len = Int64(ccall((:GAP_LenString, libgap), Cuint, (Any,), val))
    char_ptr = ccall((:GAP_CSTR_STRING, libgap), Ptr{UInt8}, (Any,), val)
    return deepcopy(unsafe_wrap(Vector{UInt8}, char_ptr, string_len))
end


NewPlist(capacity::Int64) = ccall((:GAP_NewPlist, libgap), GapObj, (Int64,), capacity)
NewPrecord(capacity::Int64) = ccall((:GAP_NewPrecord, libgap), GapObj, (Int64,), capacity)
NewRange(len::Int64, low::Int64, inc::Int64) = ccall((:GAP_NewRange, libgap), GapObj, (Int64, Int64, Int64), len, low, inc)
NEW_MACFLOAT(x::Float64) = ccall((:NEW_MACFLOAT, libgap), GapObj, (Cdouble,), x)
ValueMacFloat(x::GapObj) = ccall((:GAP_ValueMacFloat, libgap), Cdouble, (Any,), x)
CharWithValue(x::Cuchar) = ccall((:GAP_CharWithValue, libgap), GapObj, (Cuchar,), x)

# `WrapJuliaFunc` and `UnwrapJuliaFunc` are intended to create a GAP function
# object that wraps a given Julia function, and to unwrap such a GAP function,
# respectively.
# Note that we do not *automatically* wrap Julia functions into GAP functions
# when they are accessed from the GAP side,
# and do not automatically unwrap Julia functions that are wrapped into
# GAP functions when they are accessed from the GAP side.
# For convenience, also non-`Function` Julia objects can be passed to
# `WrapJuliaFunc`, which then returns the input;
# the idea is that many callable Julia objects aren't `Function`s
# (and in general also aren't `Base.Callable`s),
# and that these objects can be called on the GAP side like functions.
# Thus the result of `WrapJuliaFunc` for a callable object is something
# that can be called on the GAP side.
# In the other direction, `UnwrapJuliaFunc` extracts the underlying Julia
# function from its argument if applicable, and otherwise returns the input.
WrapJuliaFunc(x::Any) = x
WrapJuliaFunc(x::Function) = ccall((:WrapJuliaFunc, JuliaInterface_path()), GapObj, (Any,), x)
UnwrapJuliaFunc(x::Any) = x
UnwrapJuliaFunc(x::GapObj) = ccall((:UnwrapJuliaFunc, JuliaInterface_path()), Any, (GapObj,), x)

function ElmList(x::GapObj, position)
    o = ccall((:GAP_ElmList, libgap), Ptr{Cvoid}, (Any, Culong), x, Culong(position))
    return _GAP_TO_JULIA(o)
end


"""
    call_gap_func(func::GapObj, args...; kwargs...)

Call the GAP object `func` as a function,
with arguments `args...` and global GAP options `kwargs...`,
and return the result if there is one, and `nothing` otherwise.

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
    # this is the generic method which supports keyword arguments (mapped to GAP options)
    # and goes through JuliaInterface, which is convenient but a bit slow.
    options = false
    if length(kwargs) > 0
        kwargs_rec = GapObj(Dict(kwargs))
        Wrappers.PushOptions(kwargs_rec)
        options = true
    end
    try
        return call_gap_func_nokw(func, args...)
    finally
        if options
            Wrappers.PopOptions()
        end
    end
end

# specialize call_gap_func for the no-keywords case, for performance
function call_gap_func_nokw(func::GapObj, args...)
    if TNUM_OBJ(func) == T_FUNCTION && length(args) <= 6
        _call_gap_func(func, args...)
    else
        ccall((:call_gap_func, JuliaInterface_path()), Any, (Any, Any), func, args)
    end
end

# make all GapObj callable
(func::GapObj)(args...; kwargs...) = call_gap_func(func, args...; kwargs...)

# specialize non-kwargs versions, which increases performance
(func::GapObj)() = call_gap_func_nokw(func)
(func::GapObj)(a1) = call_gap_func_nokw(func, a1)
(func::GapObj)(a1, a2) = call_gap_func_nokw(func, a1, a2)
(func::GapObj)(a1, a2, a3) = call_gap_func_nokw(func, a1, a2, a3)
(func::GapObj)(a1, a2, a3, a4) = call_gap_func_nokw(func, a1, a2, a3, a4)
(func::GapObj)(a1, a2, a3, a4, a5) = call_gap_func_nokw(func, a1, a2, a3, a4, a5)
(func::GapObj)(a1, a2, a3, a4, a5, a6) = call_gap_func_nokw(func, a1, a2, a3, a4, a5, a6)

#
# below several "fastpath" methods for call_gap_func follow which directly
# jump to the C handler functions, bypassing JuliaInterface, for optimal
# performance.
#

# 0 arguments
function _call_gap_func(func::GapObj)
    fptr = GET_FUNC_PTR(func, 0)
    ret = ccall(fptr, Ptr{Cvoid}, (Ptr{Cvoid},), pointer_from_objref(func))
    return _GAP_TO_JULIA(ret)
end

# 1 argument
function _call_gap_func(func::GapObj, a1)
    fptr = GET_FUNC_PTR(func, 1)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        _JULIA_TO_GAP(a1),
    )
    return _GAP_TO_JULIA(ret)
end

# 2 arguments
function _call_gap_func(func::GapObj, a1, a2)
    fptr = GET_FUNC_PTR(func, 2)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
    )
    return _GAP_TO_JULIA(ret)
end

# 3 arguments
function _call_gap_func(func::GapObj, a1, a2, a3)
    fptr = GET_FUNC_PTR(func, 3)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
    )
    return _GAP_TO_JULIA(ret)
end

# 4 arguments
function _call_gap_func(func::GapObj, a1, a2, a3, a4)
    fptr = GET_FUNC_PTR(func, 4)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
        _JULIA_TO_GAP(a4),
    )
    return _GAP_TO_JULIA(ret)
end

# 5 arguments
function _call_gap_func(func::GapObj, a1, a2, a3, a4, a5)
    fptr = GET_FUNC_PTR(func, 5)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        pointer_from_objref(func),
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
        _JULIA_TO_GAP(a4),
        _JULIA_TO_GAP(a5),
    )
    return _GAP_TO_JULIA(ret)
end

# 6 arguments
function _call_gap_func(func::GapObj, a1, a2, a3, a4, a5, a6)
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
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
        _JULIA_TO_GAP(a4),
        _JULIA_TO_GAP(a5),
        _JULIA_TO_GAP(a6),
    )
    return _GAP_TO_JULIA(ret)
end

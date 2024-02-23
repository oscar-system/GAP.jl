## Internal ccall's
import Compat # for Base.@assume_effects emulation in Julia <= 1.7

import Base: getproperty, hasproperty, setproperty!, propertynames

#
# low-level GAP -> Julia conversion
#
# The 'assume_effects' is needed for tab completion of "nested" constructs,
# e.g. when entering `GAP.Globals.MTX.S` on the REPL then pressing TAB.
Compat.@assume_effects :foldable !:consistent function _GAP_TO_JULIA(ptr::Ptr{Cvoid})
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


@doc raw"""
    evalstr_ex(cmd::String)

Assume that `cmd` consists of $n$ GAP statements, each terminated by `;` or `;;`.
Let GAP execute these statements and return a GAP list of length $n$ that
describes their results.
Each entry of the return value is a GAP list of length 5,
with the following meaning.

- The first entry is `true` if the statement was executed successfully,
  and `false` otherwise.
- If the first entry is `true`, then the second entry is bound to the
  result of the statement if there was one, and unbound otherwise.
- The third entry is unbound if an error occured,
  `true` if the statement ends in a double semicolon,
  and `false` otherwise.
- The fourth entry currently is always unbound.
- The fifth entry contains the captured output of the statement as a string.
  If there was no double semicolon then also the output of
  `GAP.Globals.ViewObj` applied to the result value in the second entry,
  if any, is part of that string.

# Examples
```jldoctest
julia> GAP.evalstr_ex( "1+2" )        # error due to missing semicolon
GAP: [ [ false,,,, "" ] ]

julia> GAP.evalstr_ex( "1+2;" )       # one statement with return value
GAP: [ [ true, 3, false,, "3" ] ]

julia> GAP.evalstr_ex( "1+2;;" )      # the same with suppressed output
GAP: [ [ true, 3, true,, "" ] ]

julia> GAP.evalstr_ex( "x:= []; Add(x, 1);" )  # two valid commands
GAP: [ [ true, [ 1 ], false,, "[  ]" ], [ true,, false,, "" ] ]

julia> GAP.evalstr_ex( "1/0; 1+1;" )  # one error, one valid command
GAP: [ [ false,,,, "" ], [ true, 2, false,, "2" ] ]

julia> GAP.evalstr_ex( "Print(1);" )  # no return value but output
GAP: [ [ true,, false,, "1" ] ]

julia> GAP.evalstr_ex( "" )           # empty input
GAP: [  ]
```
"""
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

julia> GAP.evalstr( "y:= 2; Add( x, y )" )

julia> GAP.evalstr( "x" )
GAP: [ 2 ]

julia> GAP.evalstr( "Print( x )" )
```

Note that screen outputs caused by evaluating `cmd` are not shown
by `evalstr`; use [`evalstr_ex`](@ref) for accessing both the outputs
and the return values of the command(s).

In general we recommend to avoid using `evalstr`, but it sometimes can
be a useful escape hatch to access GAP functionality that is otherwise
impossible to difficult to reach. But in most typical scenarios it
should not be necessary to use it at all.

Instead, use `GAP.GapObj` or `GAP.Obj` for constructing GAP objects
that correspond to given Julia objects,
and call GAP functions directly in the Julia session.
For example, executing `GAP.evalstr( "x:= []; Add( x, 2 )" )`
can be replaced by the Julia code `x = GAP.GapObj([]); GAP.Globals.Add(x, 2)`.
Note that the variable `x` in the former example lives in the GAP session,
i.e., it can be accessed as `GAP.Globals.x` after the call of `GAP.evalstr`,
whereas `x` in the latter example lives in the Julia session.
"""
function evalstr(cmd::String)
    res = evalstr_ex(cmd * ";")
    if any(x::GapObj->x[1] === false, res)
      # error
      global last_error
      # HACK HACK HACK: if there is an error string on the GAP side, call
      # error_handler to copy it into `last_error`
      if !Wrappers.IsEmpty(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj)
        error_handler()
      end
      error("Error thrown by GAP: $(last_error[])")
    end
    res = res[end]::GapObj
    if Wrappers.ISB_LIST(res, 2)
      return res[2]
    else
      return
    end
end


# Retrieve the value of a global GAP variable given its name. This function
# returns a raw Ptr value, and should only be called by plumbing code.
#
# The 'assume_effects' is needed for tab completion of "nested" constructs,
# e.g. when entering `GAP.Globals.MTX.S` on the REPL then pressing TAB.
Compat.@assume_effects :foldable !:consistent function _ValueGlobalVariable(name::Union{AbstractString,Symbol})
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
    len = ccall((:GAP_LenString, libgap), Int, (Any,), val)
    char_ptr = ccall((:GAP_CSTR_STRING, libgap), Ptr{UInt8}, (Any,), val)
    return deepcopy(unsafe_string(char_ptr, len))::String
end

function CSTR_STRING_AS_ARRAY(val::GapObj)::Vector{UInt8}
    len = ccall((:GAP_LenString, libgap), Int, (Any,), val)
    char_ptr = ccall((:GAP_CSTR_STRING, libgap), Ptr{UInt8}, (Any,), val)
    return deepcopy(unsafe_wrap(Vector{UInt8}, char_ptr, len))
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

julia> GAP.Globals.Cyc(GAP.Obj(1.41421356))
GAP: 35355339/25000000

julia> GAP.Globals.Cyc(GAP.Obj(1.41421356); bits=20)
GAP: E(8)-E(8)^3
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

function slow_call_gap_func_nokw(func::GapObj, args)
    ccall((:call_gap_func, JuliaInterface_path()), Ptr{Cvoid}, (Any, Any), func, args)
end

is_func(func::GapObj) = TNUM_OBJ(func) == T_FUNCTION

# specialize call_gap_func for the no-keywords case, for performance
function call_gap_func_nokw(func::GapObj, args...)
    if is_func(func) && length(args) <= 6
        ret = _call_gap_func(func, args...)
    else
        ret = slow_call_gap_func_nokw(func, args)
    end
    return _GAP_TO_JULIA(ret)
end

# make all GapObj callable
(func::GapObj)(args...; kwargs...) = call_gap_func(func, args...; kwargs...)

# specialize non-kwargs versions, which increases performance
(f::GapObj)() = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f) : slow_call_gap_func_nokw(f, ()))
(f::GapObj)(a1) = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f, a1) : slow_call_gap_func_nokw(f, (a1,)))
(f::GapObj)(a1, a2) = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f, a1, a2) : slow_call_gap_func_nokw(f, (a1, a2)))
(f::GapObj)(a1, a2, a3) = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f, a1, a2, a3) : slow_call_gap_func_nokw(f, (a1, a2, a3)))
(f::GapObj)(a1, a2, a3, a4) = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f, a1, a2, a3, a4) : slow_call_gap_func_nokw(f, (a1, a2, a3, a4)))
(f::GapObj)(a1, a2, a3, a4, a5) = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f, a1, a2, a3, a4, a5) : slow_call_gap_func_nokw(f, (a1, a2, a3, a4, a5)))
(f::GapObj)(a1, a2, a3, a4, a5, a6) = _GAP_TO_JULIA(is_func(f) ? _call_gap_func(f, a1, a2, a3, a4, a5, a6) : slow_call_gap_func_nokw(f, (a1, a2, a3, a4, a5, a6)))

#
# below several "fastpath" methods for call_gap_func follow which directly
# jump to the C handler functions, bypassing JuliaInterface, for optimal
# performance.
#

# 0 arguments
function _call_gap_func(func::GapObj)
    fptr = GET_FUNC_PTR(func, 0)
    ret = ccall(fptr, Ptr{Cvoid}, (GapObj,), func)
    return ret
end

# 1 argument
function _call_gap_func(func::GapObj, a1)
    fptr = GET_FUNC_PTR(func, 1)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (GapObj, Ptr{Cvoid}),
        func,
        _JULIA_TO_GAP(a1),
    )
    return ret
end

# 2 arguments
function _call_gap_func(func::GapObj, a1, a2)
    fptr = GET_FUNC_PTR(func, 2)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (GapObj, Ptr{Cvoid}, Ptr{Cvoid}),
        func,
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
    )
    return ret
end

# 3 arguments
function _call_gap_func(func::GapObj, a1, a2, a3)
    fptr = GET_FUNC_PTR(func, 3)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (GapObj, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        func,
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
    )
    return ret
end

# 4 arguments
function _call_gap_func(func::GapObj, a1, a2, a3, a4)
    fptr = GET_FUNC_PTR(func, 4)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (GapObj, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        func,
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
        _JULIA_TO_GAP(a4),
    )
    return ret
end

# 5 arguments
function _call_gap_func(func::GapObj, a1, a2, a3, a4, a5)
    fptr = GET_FUNC_PTR(func, 5)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (GapObj, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        func,
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
        _JULIA_TO_GAP(a4),
        _JULIA_TO_GAP(a5),
    )
    return ret
end

# 6 arguments
function _call_gap_func(func::GapObj, a1, a2, a3, a4, a5, a6)
    fptr = GET_FUNC_PTR(func, 6)
    ret = ccall(
        fptr,
        Ptr{Cvoid},
        (
            GapObj,
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
            Ptr{Cvoid},
        ),
        func,
        _JULIA_TO_GAP(a1),
        _JULIA_TO_GAP(a2),
        _JULIA_TO_GAP(a3),
        _JULIA_TO_GAP(a4),
        _JULIA_TO_GAP(a5),
        _JULIA_TO_GAP(a6),
    )
    return ret
end

## Internal ccall's

import Base: getproperty, propertynames

function RAW_GAP_TO_JULIA(ptr::Ptr{Cvoid})::Any
    return ccall(:julia_gap,Any,(Ptr{Cvoid},),ptr)
end

function RAW_JULIA_TO_GAP(val::Any)::Ptr{Cvoid}
    return ccall(:gap_julia,Ptr{Cvoid},(Any,),val)
end

function EvalStringEx( cmd :: String )
    res = ccall( :GAP_EvalString, Any, 
                 (Ptr{UInt8},),
                 cmd );
    return res
end

function EvalString( cmd :: String )
    res = EvalStringEx(cmd * ";")
    return res[end][2]
end

function ValueGlobalVariable( name :: String )
    gvar = ccall( :GAP_ValueGlobalVariable, Ptr{Cvoid},
                      (Ptr{UInt8},),name)
    return RAW_GAP_TO_JULIA(gvar)
end

function CanAssignGlobalVariable(name::String)
    ccall(:GAP_CanAssignGlobalVariable, Bool,
             (Ptr{UInt8},), name)
end

function AssignGlobalVariable(name::String, value::Obj)
    if ! CanAssignGlobalVariable(name)
        error("cannot assing to $name in GAP")
    end
    tmp = RAW_JULIA_TO_GAP(value)
    ccall(:GAP_AssignGlobalVariable, Cvoid,
             (Ptr{UInt8}, Ptr{Cvoid}), name, tmp)
end

function MakeString( val::String )::MPtr
    string = ccall( :GAP_MakeString, Any,
                    ( Ptr{UInt8}, ),
                    val )
    return string
end

function CSTR_STRING( val::MPtr )::String
    char_ptr = ccall( :GAP_CSTR_STRING, Ptr{UInt8},
                      ( Any, ),
                      val )
    return deepcopy(unsafe_string(char_ptr))
end

function UNSAFE_CSTR_STRING( val::MPtr )::Array{UInt8,1}
    string_len = Int64( ccall( :GAP_LenString, Cuint,
                               ( Any, ),
                               val ) )
    char_ptr = ccall( :GAP_CSTR_STRING, Ptr{UInt8},
                      ( Any, ),
                      val )
    return unsafe_wrap( Array{UInt8,1}, char_ptr, string_len )
end


function NewPlist(length :: Int64)
    o = ccall( :GAP_NewPlist,
               Any,
               (Int64,),
               length )
    return o
end

function MakeObjInt(x::BigInt)
    o = ccall( :MakeObjInt,
               Ptr{Cvoid},
               (Ptr{UInt64},Cint),
               x.d, x.size )
    return RAW_GAP_TO_JULIA( o )
end

function NEW_MACFLOAT(x::Float64)
    o = ccall( :NEW_MACFLOAT,
               Any,
               (Cdouble,),
               x )
    return o
end

function ValueMacFloat(x::MPtr)
    o = ccall( :GAP_ValueMacFloat,
               Cdouble,
               (Any,),
               x )
    return o
end

function CharWithValue(x::Cuchar)
    o = ccall( :GAP_CharWithValue,
               Any,
               (Cuchar,),
               x )
    return o
end

function ElmList(x::MPtr,position)
    o = ccall( :GAP_ElmList,
               Ptr{Cvoid},
               (Any,Culong),
               x,Culong(position))
    return RAW_GAP_TO_JULIA(o)
end

function NewJuliaFunc(x::Function)
    o = ccall( :NewJuliaFunc,
               Any,
               (Any,),
               x )
    return o
end

"""
    (func::MPtr)(args...)

> This function makes it possible to call MPtr objects as functions.
> There is no argument number checking here, all checks on the arguments
> are done by GAP itself.
"""
(func::MPtr)(args...; kwargs...) = call_gap_func(func, args...; kwargs...)

function call_gap_func(func::MPtr, args...; kwargs...)
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

struct GlobalsType
    funcs::Dict{Symbol,Cuint}
end

Base.show(io::IO,::GlobalsType) = Base.show(io,"table of global GAP objects")

Globals = GlobalsType(Dict{Symbol,Cuint}())

function getproperty(funcobj::GlobalsType, name::Symbol)
    cache = getfield(funcobj,:funcs)

    gvar = get!(cache, name) do
        name_string = string(name)
        ccall(:GVarName, Cuint, (Ptr{UInt8},), name_string)
    end

    v = ccall(:ValGVar, Ptr{Cvoid}, (Cuint,), gvar)
    v = RAW_GAP_TO_JULIA(v)
    if v == nothing
        error("GAP variable ", name, " not bound")
    end
    return v
end

function propertynames(funcobj::GlobalsType,private)
    list = Globals.NamesGVars()
    list_converted = RAW_GAP_TO_JULIA( Array{Symbol,1}, list )
    return tuple(list_converted...)
end

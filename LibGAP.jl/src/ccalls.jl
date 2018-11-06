## Internal ccall's

import Base: getproperty

function GET_FROM_GAP(ptr::Ptr{Cvoid})::Any
    return ccall(:julia_gap,Any,(Ptr{Cvoid},),ptr)
end

function EvalString( cmd :: String )
    res = ccall( :GAP_EvalString, MPtr, 
                 (Ptr{UInt8},),
                 cmd );
    return res
end

function ValueGlobalVariable( name :: String )
    gvar = ccall( :GAP_ValueGlobalVariable, Ptr{Cvoid},
                      (Ptr{UInt8},),name)
    return GET_FROM_GAP(gvar)
end

function MakeString( val::String )::MPtr
    string = ccall( :GAP_MakeString, MPtr,
                    ( Ptr{UInt8}, ),
                    val )
    return string
end

function CSTR_STRING( val::MPtr )::String
    char_ptr = ccall( :GAP_CSTR_STRING, Ptr{UInt8},
                      ( MPtr, ),
                      val )
    return deepcopy(unsafe_string(char_ptr))
end


function NewPlist(length :: Int64)
    o = ccall( :GAP_NewPlist,
               MPtr,
               (Int64,),
               length )
    return o
end


"""
    (func::MPtr)(args...)

> This function makes it possible to call MPtr objects as functions.
> There is no argument number checking here, all checks on the arguments
> are done by GAP itself.
"""
function(func::MPtr)(args...)
    return ccall(:call_gap_func, Any, (MPtr, Any), func, args)
end

struct GlobalsType
    funcs::Dict{Symbol,Cuint}
end

Base.show(io::IO,::GlobalsType) = Base.show(io,"table of global GAP objects")

Globals = GlobalsType(Dict{Symbol,Cuint}())

function getproperty(funcobj::GlobalsType, name::Symbol)
    cache = getfield(funcobj,:funcs)
    if haskey(cache, name)
        gvar = cache[name]
    else
        name_string = string(name)
        gvar = ccall(:GVarName, Cuint, (Ptr{UInt8},), name_string)
        cache[name] = gvar
    end
    v = ccall(:ValGVar, Ptr{Cvoid}, (Cuint,), gvar)
    v = GET_FROM_GAP(v)
    if v == nothing
        error("GAP variable ", name, " not bound")
    end
    return v
end

# For backwards compatibility
# TODO: remove this again
GAPFuncs = Globals

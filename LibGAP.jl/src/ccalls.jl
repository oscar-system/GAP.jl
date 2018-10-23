## Internal ccall's

using ..libgap: gap_library

import Main: gap_julia_gap

import Main.GAP: GapFunc

### Internal stuff

function gap_sym( sym::Symbol )
    return Libdl.dlsym(gap_library, sym)
end

internal_to_gap(x::Int64) = Ptr{Cvoid}(x*8+1) ##FIXME

function GET_FROM_GAP(ptr::Ptr{Cvoid})::Any
    return ccall(Main.gap_julia_gap,Any,(Ptr{Cvoid},),ptr)
end

function EvalString( cmd :: String )
    res = ccall( ( :GAP_EvalString, "libgap"), Ptr{Cvoid}, 
                 (Ptr{UInt8},),
                 cmd );
    return GET_FROM_GAP(res)
end

function CallFunc( func :: MPtr, args... )
    return GET_FROM_GAP( GapFunc( func )(args...) )
end

function ValueGlobalVariable( name :: String )
    gvar = ccall( ( :GAP_ValueGlobalVariable, "libgap" ), Ptr{Cvoid},
                      (Ptr{UInt8},),name)
    return GET_FROM_GAP(gvar)
end

function MakeString( val::String )::MPtr
    string = ccall( ( :GAP_MakeString, "libgap" ), MPtr,
                    ( Ptr{UInt8}, ),
                    val )
    return string
end

function CSTR_STRING( val::MPtr )::String
    char_ptr = ccall( ( :GAP_CSTR_STRING, "libgap" ), Ptr{UInt8},
                      ( MPtr, ),
                      val )
    return deepcopy(unsafe_string(char_ptr))
end


function NewPlist(length :: Int64)
    o = ccall( ( :GAP_NewPlist, "libgap" ),
               MPtr,
               (Int64,),
               length )
    return o
end

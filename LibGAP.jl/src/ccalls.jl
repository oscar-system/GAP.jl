## Internal ccall's

import Main: gap_julia_gap

import Main.GAP: GapFunc

### Internal stuff

function GET_FROM_GAP(ptr::Ptr{Cvoid})::Any
    return ccall(Main.gap_julia_gap,Any,(Ptr{Cvoid},),ptr)
end

function EvalString( cmd :: String )
    res = ccall( ( :GAP_EvalString, "libgap"), MPtr, 
                 (Ptr{UInt8},),
                 cmd );
    return res
end

function CallFunc( func :: MPtr, args... )
    return GapFunc( func )(args...)
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

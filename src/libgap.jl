#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

module libgap

import Base: length, convert

export initialize, EvalString, IntObj_Int, Int_IntObj,
       CallFuncList, ValGVar, String_StringObj, StringObj_String,
       NewPList, SetElmPList, SetLenPList, ElmPList, LenPList

Libdl.dlopen("libgap", Libdl.RTLD_GLOBAL)

function error_handler(message)
    print(message)
end

error_handler_func = cfunction(error_handler,Void,(Ptr{Char},))

function initialize( argv::Array{String,1}, env::Array{String,1} )
    ccall( (:GAP_set_error_handler, "libgap")
            , Void
            , (Ptr{Void},)
            , error_handler_func)
    ccall( (:GAP_initialize, "libgap")
           , Void
           , (Int32, Ptr{Ptr{UInt8}},Ptr{Ptr{UInt8}})
           , length(argv)
           , argv
           , env )
end

function finalize( )
    ccall( (:GAP_finalize, "libgap")
           , Void
           , () )
end

immutable GapObj
    data :: Ptr{Void}
end

function convert(::Type{Ptr{UInt8}}, obj :: GapObj)
    return obj.data
end

function EvalString( cmd :: String )
    out = Array(UInt8, 32768)
    err = Array(UInt8, 32768)
    res = GapObj( ccall( (:GAP_EvalString, "libgap")
                          , Ptr{Void}
                          , (Ptr{UInt8},)
                          , cmd ) );
    return res
end

function IntObj_Int(val :: Int64)
     return GapObj( ccall( (:GAP_IntObj_Int, "libgap")
                           , Ptr{Void}
                           , (Int64, )
                           , val ) )
end

function Int_IntObj(obj :: GapObj)
     return ccall( (:GAP_Int_IntObj, "libgap")
                    , Cint
                    , (Ptr{Void}, )
                    , obj.data )
end

function CallFuncList( func :: GapObj, list :: GapObj )
    return GapObj( ccall( (:GAP_CallFuncList, "libgap")
                          , Ptr{Void}
                          , (Ptr{Void}, Ptr{Void})
                          , func.data, list.data ) )
end

function ValGVar( name :: String )
    return GapObj( ccall( (:GAP_ValGVar, "libgap")
                          , Ptr{Void}
                          , ( Ptr{UInt8}, )
                          , name ) )
end

function String_StringObj( str :: GapObj )
    return unsafe_string( ccall( (:GAP_CSTR_STRING, "libgap")
                                 , Ptr{Char}
                                 , (Ptr{Void}, )
                                 , str.data ) )
end

function StringObj_String(str :: String)
    return GapObj( ccall( (:GAP_MakeString, "libgap")
                   , Ptr{Void}
                   , (Ptr{UInt8}, Csize_t )
                   , str, length(str) ) )
end

function NewPList(length :: UInt64)
    o = GapObj( ccall( (:GAP_NewPList, "libgap")
                          , Ptr{UInt8}
                          , (UInt64,)
                          , length ) )
    return o
end

function NewPList(cap :: Int64)
    NewPList(UInt64(cap))
end

function SetLenPList(list :: GapObj, len :: Int64)
    ccall( (:GAP_SetLenPList, "libgap")
           , Void
           , (Ptr{UInt8}, UInt64)
           , list.data, len )
end

function SetElmPList(list :: GapObj, pos :: Int64, val :: GapObj)
    ccall( (:GAP_SetElmPList, "libgap")
           , Void
           , (Ptr{UInt8}, UInt64, Ptr{UInt8})
           , list.data, UInt64(pos), val.data )
end

function ElmPList(list :: GapObj, pos :: UInt64)
    return GapObj( ccall( (:GAP_ElmPList, "libgap")
                          , Ptr{UInt8}
                          , (Ptr{UInt8}, UInt64)
                          , list.data, pos ) ) 
end

libgap_ElmPList(list::GapObj,pos::Int64) = libgap_ElmPList(list,UInt64(pos))

function LenPList( list :: GapObj ) :: Int64
    return ccall( (:GAP_LenPlist, "libgap")
                          , Int64
                          , (Ptr{UInt8},)
                          , list.data, ) 
end



function GC_pin(obj :: GapObj)
    ccall( (:libgap_GC_pin, "libgap")
           , Void
           , ( Ptr{Void}, )
           , obj.data )
end

function GC_unpin(obj :: GapObj)
    ccall( (:libgap_GC_unpin, "libgap")
           , Void
           , ( Ptr{Void}, )
           , obj.data )
end

end

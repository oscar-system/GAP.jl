#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

import Base: length

Libdl.dlopen("libgap", Libdl.RTLD_GLOBAL)

function libgap_initialize( argv::Array{String,1}, env::Array{String,1} )
    ccall( (:libgap_initialize, "libgap")
           , Void
           , (Int32, Ptr{Ptr{UInt8}}, Ptr{Ptr{UInt8}})
           , length(argv)
           , argv
           , env )
end

function libgap_finalize( )
    ccall( (:libgap_finalize, "libgap")
           , Void
           , () )
end

immutable GapObj
    data :: Ptr{Void}
end

function libgap_eval_string( cmd :: String )
    out = Array(UInt8, 32768)
    err = Array(UInt8, 32768)
    res = GapObj( ccall( (:libgap_eval_string, "libgap")
                          , Ptr{Void}
                          , (Ptr{UInt8},Ptr{UInt8},Csize_t,Ptr{UInt8},Csize_t)
                          , cmd, out, sizeof(out), err, sizeof(err) ) );
    return (res, unsafe_string(pointer(out)), unsafe_string(pointer(err)))
end

function libgap_get_tnum(ref :: GapObj)
     return ccall( (:libgap_TNumObj, "libgap")
                   , UInt64
                   , (Ptr{Void}, )
                   , ref.data )
end

function libgap_IntObj_Int(val :: Int64)
     return GapObj( ccall( (:libgap_IntObj_Int, "libgap")
                           , Ptr{Void}
                           , (Int64, )
                           , val ) )
end

function libgap_Int_IntObj(obj :: GapObj)
     return GapObj( ccall( (:libgap_Int_IntObj, "libgap")
                           , Int64
                           , (Ptr{Void}, )
                           , obj.data ) )
end

function libgap_call_func_list( func :: GapObj, list :: GapObj )
    return GapObj( ccall( (:CallFuncList, "libgap")
                          , Ptr{Void}
                          , (Ptr{Void}, Ptr{Void})
                          , func.data, list.data ) )
end

function libgap_DoExecFunc0args( func :: GapObj )
    return GapObj( ccall( (:libgap_DoExecFunc0args, "libgap")
                   , Ptr{Void}
                   , (Ptr{Void},)
                   , func.data ) )
end

function libgap_DoExecFunc1args( func :: GapObj, arg1 :: GapObj )
    return GapObj( ccall( (:libgap_DoExecFunc1args, "libgap")
                   , Ptr{Void}
                   , (Ptr{Void}, Ptr{Void})
                   , func.data, arg1.data ) )
end

function libgap_DoOperation0args( func :: GapObj )
    return GapObj( ccall( (:libgap_DoOperation0args, "libgap")
                   , Ptr{Void}
                   , (Ptr{Void},)
                   , func.data ) )
end

function libgap_DoOperation1args( func :: GapObj, arg1 :: GapObj )
    return GapObj( ccall( (:libgap_DoOperation1args, "libgap")
                   , Ptr{Void}
                   , (Ptr{Void}, Ptr{Void})
                   , func.data, arg1.data ) )
end

function libgap_ValGVar( name :: String )
    return GapObj( ccall( (:libgap_ValGVar, "libgap")
                          , Ptr{Void}
                          , ( Ptr{UInt8}, )
                          , name ) )
end

function libgap_String_StringObj( str :: GapObj )
    return unsafe_string( ccall( (:libgap_String_StringObj, "libgap")
                                 , Ptr{UInt8}
                                 , (Ptr{Void}, )
                                 , str.data ) )
end

function libgap_StringObj_String(str :: String)
    return GapObj( ccall( (:libgap_StringObj_String, "libgap")
                   , Ptr{Void}
                   , (Ptr{UInt8}, )
                   , str ) )
end

function libgap_NewPList(cap :: UInt64)
    return GapObj( ccall( (:libgap_NewPList, "libgap")
                          , Ptr{UInt8}
                          , (UInt64,)
                          , cap ) )
end

function libgap_NewPList(cap :: UInt64)
    return GapObj( ccall( (:libgap_NewPRec, "libgap")
                          , Ptr{UInt8}
                          , (UInt64,)
                          , cap ) )
end

function libgap_GC_pin(obj :: GapObj)
    ccall( (:libgap_GC_pin, "libgap")
           , Void
           , ( Ptr{Void}, )
           , obj.data )
end

function libgap_GC_unpin(obj :: GapObj)
    ccall( (:libgap_GC_unpin, "libgap")
           , Void
           , ( Ptr{Void}, )
           , obj.data )
end


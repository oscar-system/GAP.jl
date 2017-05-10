#
# This is a very hacky prototype calling libgap from julia
#

import Base: length

function libgap_initialize( argv::Array{String,1} )
    ccall( (:libgap_initialize, "libgap")
           , Void
           , (Int32, Ptr{Ptr{UInt8}})
           , length(argv)
           , argv)
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
    return GapObj( ccall( (:libgap_eval_string, "libgap")
                          , Ptr{Void}
                          , (Ptr{UInt8},)
                          , cmd ) );
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
    return GapObj( ccall( (:CallFuncList, "libgap")
                   , Ptr{Void}
                   , (Ptr{Void},)
                   , func.data ) )
end

function libgap_DoExecFunc1args( func :: GapObj, arg1 :: GapObj )
    return GapObj( ccall( (:CallFuncList, "libgap")
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
    return bytestring( ccall( (:libgap_String_StringObj, "libgap")
                             , Ptr{UInt8}
                             , (Ptr{Void}, )
                             , str.data ) )
end

function libgap_unbox_int(ref :: GapObj)
    if libgap_get_tnum(ref) == 0
        return Nullable{Int64}(libgap_Int_IntObj(ref))
    else
        return Nullable{Int64}()
    end
end

function libgap_box_int(val :: Int64)
    return libgap_IntObj_Int(val)
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


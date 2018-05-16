#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

module LibGAP

import GAP

import Base: length, convert

import Main: gap_GET_JULIA_OBJ, gap_NewJuliaObj

export EvalString, IntObj_Int, Int_IntObj,
       CallFuncList, ValGVar, String_StringObj, StringObj_String,
       NewPList, SetElmPList, SetLenPList, ElmPList, LenPList

Libdl.dlopen("libgap", Libdl.RTLD_GLOBAL)

function convert(::Type{Ptr{UInt8}}, obj :: GAP.GapObj)
    return obj.ptr
end

function EvalString( cmd :: String )
    out = Array(UInt8, 32768)
    err = Array(UInt8, 32768)
    res = GAP.GapObj( ccall( (:GAP_EvalString, "libgap")
                          , Ptr{Void}
                          , (Ptr{UInt8},)
                          , cmd ) );
    return res
end

function IntObj_Int(val :: Int64)
     return GAP.GapObj( ccall( (:GAP_IntObj_Int, "libgap")
                           , Ptr{Void}
                           , (Int64, )
                           , val ) )
end

function Int_IntObj(obj :: GAP.GapObj)
     return ccall( (:GAP_Int_IntObj, "libgap")
                    , Cint
                    , (Ptr{Void}, )
                    , obj.ptr )
end

function CallFuncList( func :: GAP.GapObj, list :: GAP.GapObj )
    return GAP.GapObj( ccall( (:GAP_CallFuncList, "libgap")
                          , Ptr{Void}
                          , (Ptr{Void}, Ptr{Void})
                          , func.ptr, list.ptr ) )
end

function ValGVar( name :: String )
    return GAP.GapObj( ccall( (:GAP_ValGVar, "libgap")
                          , Ptr{Void}
                          , ( Ptr{UInt8}, )
                          , name ) )
end

function String_StringObj( str :: GAP.GapObj )
    return unsafe_string( ccall( (:GAP_CSTR_STRING, "libgap")
                                 , Ptr{UInt8}
                                 , (Ptr{Void}, )
                                 , str.ptr ) )
end

function StringObj_String(str :: String)
    return GAP.GapObj( ccall( (:GAP_MakeString, "libgap")
                   , Ptr{Void}
                   , (Ptr{UInt8}, Csize_t )
                   , str, length(str) ) )
end

function NewPList(length :: UInt64)
    o = GAP.GapObj( ccall( (:GAP_NewPList, "libgap")
                          , Ptr{Void}
                        , (UInt64,)
                          , length ) )
    return o
end

function NewPList(cap :: Int64)
    NewPList(UInt64(cap))
end

function SetLenPList(list :: GAP.GapObj, len :: Int64)
    ccall( (:GAP_SetLenPList, "libgap")
           , Void
           , (Ptr{UInt8}, UInt64)
           , list.ptr, len )
end

function SetElmPList(list :: GAP.GapObj, pos :: Int64, val :: GAP.GapObj)
    ccall( (:GAP_SetElmPList, "libgap")
           , Void
           , (Ptr{UInt8}, UInt64, Ptr{UInt8})
           , list.ptr, UInt64(pos), val.ptr )
end

function ElmPList(list :: GAP.GapObj, pos :: UInt64)
    return GAP.GapObj( ccall( (:GAP_ElmPList, "libgap")
                          , Ptr{Void}
                          , (Ptr{UInt8}, UInt64)
                          , list.ptr, pos ) ) 
end

libgap_ElmPList(list::GAP.GapObj,pos::Int64) = libgap_ElmPList(list,UInt64(pos))

function LenPList( list :: GAP.GapObj ) :: Int64
    return ccall( (:GAP_LenPList, "libgap")
                          , Int64
                          , (Ptr{UInt8},)
                          , list.ptr, ) 
end

function AsGAPPtr( obj ) :: GAP.GapObj
    ptr = pointer_from_objref( obj )
    gap_ptr = ccall( gap_NewJuliaObj, Ptr{Void}, (Ptr{Void},), ptr )
    return GAP.GapObj( gap_ptr )
end

function FromGAPPtr( obj :: GAP.GapObj )
    ptr = ccall( gap_GET_JULIA_OBJ, Ptr{Void},(Ptr{Void},), obj.ptr )
    return unsafe_pointer_to_objref( ptr )
end

function GC_pin(obj :: GAP.GapObj)
    ccall( (:libgap_GC_pin, "libgap")
           , Void
           , ( Ptr{Void}, )
           , obj.ptr )
end

function GC_unpin(obj :: GAP.GAP.GapObj)
    ccall( (:libgap_GC_unpin, "libgap")
           , Void
           , ( Ptr{Void}, )
           , obj.ptr )
end

include( "gap.jl" )
include( "conversion.jl" )

end

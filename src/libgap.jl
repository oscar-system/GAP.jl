#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

module LibGAP

using Libdl

import Main.GAP
import Main.GAPFuncs

import Base: length, convert

import Main: gap_GET_JULIA_OBJ, gap_NewJuliaObj

export EvalString, IntObj_Int, Int_IntObj,
       CallFuncList, ValGVar, String_StringObj, StringObj_String,
       NewPList, SetElmPList, SetLenPList, ElmPList, LenPList

dlopen("libgap", RTLD_GLOBAL)

function convert(::Type{Ptr{UInt8}}, obj :: GAP.GapObj)
    return obj.ptr
end

function EvalString( cmd :: String )
    out = Array(UInt8, 32768)
    err = Array(UInt8, 32768)
    res = GAP.GapObj( ccall( (:GAP_EvalString, "libgap")
                          , Ptr{Cvoid}
                          , (Ptr{UInt8},)
                          , cmd ) );
    return res
end

function IntObj_Int(val :: Int64)
     return GAP.GapObj( ccall( (:GAP_IntObj_Int, "libgap")
                           , Ptr{Cvoid}
                           , (Int64, )
                           , val ) )
end

function Int_IntObj(obj :: GAP.GapObj)
     return ccall( (:GAP_Int_IntObj, "libgap")
                    , Int64
                    , (Ptr{Cvoid}, )
                    , obj.ptr )
end

function CallFuncList( func :: GAP.GapObj, list :: GAP.GapObj )
    return GAP.GapObj( ccall( (:GAP_CallFuncList, "libgap")
                          , Ptr{Cvoid}
                          , (Ptr{Cvoid}, Ptr{Cvoid})
                          , func.ptr, list.ptr ) )
end

function ValGVar( name :: String )
    return GAP.GapObj( ccall( (:GAP_ValGVar, "libgap")
                          , Ptr{Cvoid}
                          , ( Ptr{UInt8}, )
                          , name ) )
end

function String_StringObj( str :: GAP.GapObj )
    return unsafe_string( ccall( (:GAP_CSTR_STRING, "libgap")
                                 , Ptr{UInt8}
                                 , (Ptr{Cvoid}, )
                                 , str.ptr ) )
end

function StringObj_String(str :: String)
    return GAP.GapObj( ccall( (:GAP_MakeString, "libgap")
                   , Ptr{Cvoid}
                   , (Ptr{UInt8}, Csize_t )
                   , str, length(str) ) )
end

function NewPList(length :: UInt64)
    o = GAP.GapObj( ccall( (:GAP_NewPList, "libgap")
                          , Ptr{Cvoid}
                        , (UInt64,)
                          , length ) )
    return o
end

function NewPList(cap :: Int64)
    NewPList(UInt64(cap))
end

function SetLenPList(list :: GAP.GapObj, len :: Int64)
    ccall( (:GAP_SetLenPList, "libgap")
           , Cvoid
           , (Ptr{UInt8}, UInt64)
           , list.ptr, len )
end

function SetElmPList(list :: GAP.GapObj, pos :: Int64, val :: GAP.GapObj)
    ccall( (:GAP_SetElmPList, "libgap")
           , Cvoid
           , (Ptr{UInt8}, UInt64, Ptr{UInt8})
           , list.ptr, UInt64(pos), val.ptr )
end

function ElmPList(list :: GAP.GapObj, pos :: UInt64)
    return GAP.GapObj( ccall( (:GAP_ElmPList, "libgap")
                          , Ptr{Cvoid}
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
    gap_ptr = ccall( gap_NewJuliaObj, Ptr{Cvoid}, (Ptr{Cvoid},), ptr )
    return GAP.GapObj( gap_ptr )
end

function FromGAPPtr( obj :: GAP.GapObj )
    ptr = ccall( gap_GET_JULIA_OBJ, Ptr{Cvoid},(Ptr{Cvoid},), obj.ptr )
    return unsafe_pointer_to_objref( ptr )
end

function GC_pin(obj :: GAP.GapObj)
    ccall( (:libgap_GC_pin, "libgap")
           , Cvoid
           , ( Ptr{Cvoid}, )
           , obj.ptr )
end

function GC_unpin(obj :: GAP.GapObj)
    ccall( (:libgap_GC_unpin, "libgap")
           , Cvoid
           , ( Ptr{Cvoid}, )
           , obj.ptr )
end

include( "gap.jl" )
include( "conversion.jl" )

end

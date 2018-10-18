#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

module LibGAP

using Libdl

import Main.GAP

import Base: length, convert

# export EvalString, IntObj_Int, Int_IntObj,
#        CallFuncList, ValGVar, String_StringObj, StringObj_String,
#        NewPList, SetElmPList, SetLenPList, ElmPList, LenPList

using ..libgap: gap_library

import Main: gap_julia_gap

using Main.ForeignGAP: MPtr

function GET_FROM_GAP(ptr::Ptr{Cvoid})::Any
    return ccall(Main.gap_julia_gap,Any,(Ptr{Cvoid},),ptr)
end

# function convert(::Type{Ptr{UInt8}}, obj :: GAP.GapObj)
#     return obj.ptr
# end

function EvalString( cmd :: String )
    res = ccall( Libdl.dlsym(gap_library, :GAP_EvalString)
                 , Ptr{Cvoid}
                 , (Ptr{UInt8},)
                 , cmd );
    return GET_FROM_GAP(res)
end

# function IntObj_Int(val :: Int64)
#      return GAP.GapObj( ccall( (:ObjInt_Int, "libgap")
#                            , Ptr{Cvoid}
#                            , (Int64, )
#                            , val ) )
# end

# function Int_IntObj(obj :: GAP.GapObj)
#      return ccall( (:GAP_Int_IntObj, "libgap")
#                     , Int64
#                     , (Ptr{Cvoid}, )
#                     , obj.ptr )
# end

# function CallFuncList( func :: GAP.GapObj, list :: GAP.GapObj )
#     return GAP.GapObj( ccall( (:GAP_CallFuncList, "libgap")
#                           , Ptr{Cvoid}
#                           , (Ptr{Cvoid}, Ptr{Cvoid})
#                           , func.ptr, list.ptr ) )
# end

# function ValGVar( name :: String )
#     return GAP.GapObj( ccall( (:GAP_ValGVar, "libgap")
#                           , Ptr{Cvoid}
#                           , ( Ptr{UInt8}, )
#                           , name ) )
# end

# function String_StringObj( str :: GAP.GapObj )
#     return unsafe_string( ccall( (:GAP_CSTR_STRING, "libgap")
#                                  , Ptr{UInt8}
#                                  , (Ptr{Cvoid}, )
#                                  , str.ptr ) )
# end

# function StringObj_String(str :: String)
#     return GAP.GapObj( ccall( (:GAP_MakeString, "libgap")
#                    , Ptr{Cvoid}
#                    , (Ptr{UInt8}, Csize_t )
#                    , str, length(str) ) )
# end

# function NewPList(length :: UInt64)
#     o = GAP.GapObj( ccall( (:GAP_NewPList, "libgap")
#                           , Ptr{Cvoid}
#                         , (UInt64,)
#                           , length ) )
#     return o
# end

# function NewPList(cap :: Int64)
#     NewPList(UInt64(cap))
# end

# function SetLenPList(list :: GAP.GapObj, len :: Int64)
#     ccall( (:GAP_SetLenPList, "libgap")
#            , Cvoid
#            , (Ptr{UInt8}, UInt64)
#            , list.ptr, len )
# end

# function SetElmPList(list :: GAP.GapObj, pos :: Int64, val :: GAP.GapObj)
#     ccall( (:GAP_SetElmPList, "libgap")
#            , Cvoid
#            , (Ptr{UInt8}, UInt64, Ptr{UInt8})
#            , list.ptr, UInt64(pos), val.ptr )
# end

function ElmPList(list :: MPtr, pos :: Integer)
    res =  ccall( Libdl.dlsym(gap_library, :ElmPlist)
           , Ptr{Cvoid}
           , (MPtr, UInt64)
           , list, UInt64(pos) )
    return GET_FROM_GAP( res )
end

# libgap_ElmPList(list::GAP.GapObj,pos::Int64) = libgap_ElmPList(list,UInt64(pos))

# function LenPList( list :: GAP.GapObj ) :: Int64
#     return ccall( (:GAP_LenPList, "libgap")
#                           , Int64
#                           , (Ptr{UInt8},)
#                           , list.ptr, ) 
# end

# include( "gap.jl" )
# include( "conversion.jl" )

end

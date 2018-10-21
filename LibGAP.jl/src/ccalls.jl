## Internal ccall's

using ..libgap: gap_library

import Main: gap_julia_gap

import Main.GAP: GapFunc

### Internal stuff

function gap_sym( sym::Symbol )
    return Libdl.dlsym(gap_library, sym)
end

GAPObj_types = Union{Ptr{Cvoid},MPtr,Int64}

internal_to_gap(x::MPtr) = x
internal_to_gap(x::Int64) = Ptr{Cvoid}(x*8+1) ##FIXME

GAP_T_PLIST = cglobal(gap_sym(:T_PLIST),Ptr{Cvoid})

function GET_FROM_GAP(ptr::Ptr{Cvoid})::Any
    return ccall(Main.gap_julia_gap,Any,(Ptr{Cvoid},),ptr)
end

function EvalString( cmd :: String )
    res = ccall( gap_sym(:GAP_EvalString), Ptr{Cvoid}, 
                 (Ptr{UInt8},),
                 cmd );
    return GET_FROM_GAP(res)
end

function CallFunc( func :: MPtr, args... )
    return GET_FROM_GAP( GapFunc( func )(args...) )
end

function ValGVar( name :: String )
    gvar_num = ccall( gap_sym( :GVarName ), UInt64,
                      (Ptr{UInt8},),name)
    gvar = ccall( gap_sym( :ValGVar), Ptr{Cvoid},
                  (UInt64,),gvar_num)
    return GET_FROM_GAP(gvar)
end

function NewPlist(length :: UInt64)
    o = ccall( gap_sym( :NEW_PLIST ),
               MPtr,
               (Ptr{Cvoid},UInt64),
               GAP_T_PLIST, length )
    ccall( gap_sym( :SetLenPlist),
           Cvoid, (MPtr,UInt64),
           o, length )
    return o
end

function NewPlist(cap :: Int64)
    NewPlist(UInt64(cap))
end

# function SetLenPList(list :: GAP.GapObj, len :: Int64)
#     ccall( (:GAP_SetLenPList, "libgap")
#            , Cvoid
#            , (Ptr{UInt8}, UInt64)
#            , list.ptr, len )
# end

function SetElmPlist(list :: MPtr, pos :: UInt64, val :: Int64)
    ccall( gap_sym( :SetElmPlist ),
           Cvoid,
           (MPtr, UInt64, Ptr{Cvoid}),
           list, pos, internal_to_gap(val) )
end

SetElmPlist(list :: MPtr, pos :: Int64, val :: Int64) =
    SetElmPlist(list,UInt64(pos),val)

function SetElmPlist(list :: MPtr, pos :: UInt64, val :: MPtr)
    ccall( gap_sym( :SetElmPlist ),
            Cvoid,
            (MPtr, UInt64, MPtr),
            list, pos, val )
end

SetElmPlist(list :: MPtr, pos :: Int64, val :: MPtr) =
    SetElmPlist(list,UInt64(pos),val)


function ElmPlist(list :: MPtr, pos :: Integer)
    res =  ccall( Libdl.dlsym(gap_library, :ElmPlist)
           , Ptr{Cvoid}
           , (MPtr, UInt64)
           , list, UInt64(pos) )
    return GET_FROM_GAP( res )
end

ElmPlist(list::GAP.GapObj,pos::Int64) = libgap_ElmPList(list,UInt64(pos))

# function LenPList( list :: GAP.GapObj ) :: Int64
#     return ccall( (:GAP_LenPList, "libgap")
#                           , Int64
#                           , (Ptr{UInt8},)
#                           , list.ptr, ) 
# end
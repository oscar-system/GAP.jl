## COnversion to GAP

to_gap(str :: String)         = StringObj_String(str)
to_gap(v :: Int32)            = IntObj_Int(v)
to_gap(v :: Int64)            = IntObj_Int(v)
to_gap(v :: GAP.GapObj)       = v

function to_gap( v :: Bool ) :: GAP.GapObj
    if v
        return True
    else
        return False
    end
end

function to_gap(v :: Array{GAP.GapObj, 1}) :: GAP.GapObj
    l = NewPList(length(v))
    SetLenPList(l, length(v))
    for i in 1:length(v)
        SetElmPList(l, i, v[i])
    end
    return l
end

convert(::Type{GAP.GapObj},m::Array{GAP.GapObj,1}) = to_gap(m)

function to_gap(v :: AbstractArray) :: Array{GAP.GapObj, 1}
    return map(to_gap, v)
end


## Conversion FROM GAP

function Int_IntObj(obj::MPtr)::Int64
    res = ccall( Libdl.dlsym(gap_library, :Int_ObjInt),
                 Int64, (MPtr,),
                 obj )
    return res
end

function from_gap_int16(obj :: GAP.GapObj) :: Int16
    x = Int_IntObj( obj )
    return Int16(x)
end

function from_gap_int32(obj :: GAP.GapObj) :: Int32
    x = Int_IntObj( obj )
    return Int32(x)
end

from_gap_int64(obj :: GAP.GapObj) = Int_IntObj(obj)

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

from_gap_string(obj :: GAP.GapObj) = String_StringObj(obj)

function from_gap_list( obj :: GAP.GapObj) :: Array{GAP.GapObj}
    len = LenPList( obj )
    array = Array{GAP.GapObj}(undef, len)
    for i in 1:len
        array[i] = ElmPList(obj,UInt(i))
    end
    return array
end

function from_gap_bool( obj :: GAP.GapObj ) :: Bool
    if obj.ptr == True.ptr
        return true
    elseif obj.ptr == False.ptr
        return false
    end
    ## Fail does not convert well
end

from_gap(x,::Type{Int16}) = from_gap_int16( x )
from_gap(x,::Type{Int32}) = from_gap_int32( x )
from_gap(x,::Type{Int64}) = from_gap_int64( x )
from_gap(x,::Type{String}) = from_gap_string( x )
from_gap(x,::Type{Bool}) = from_gap_bool( x )

function from_gap_list_type( obj :: GAP.GapObj, element_type :: DataType ) :: Array{Int64}
    converted_list = from_gap_list( obj )
    len_list = length(converted_list)
    new_array = Array{element_type}(undef, len_list)
    for i in 1:len_list
        new_array[ i ] = from_gap(converted_list[i],element_type)
    end
    return new_array
end

from_gap_list_int16( x ) = from_gap_list_type( x, Int16 )
from_gap_list_int32( x ) = from_gap_list_type( x, Int32 )
from_gap_list_int64( x ) = from_gap_list_type( x, Int64 )




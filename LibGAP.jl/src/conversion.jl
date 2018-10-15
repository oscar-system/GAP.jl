

function from_gap_int16(obj :: GAP.GapObj) :: Int16
    x = Int_IntObj( obj )
    return Int16(x)
end

function from_gap_int32(obj :: GAP.GapObj) :: Int32
    x = Int_IntObj( obj )
    return Int32(x)
end

from_gap_int64(obj :: GAP.GapObj) = Int64(Int_IntObj(obj))

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




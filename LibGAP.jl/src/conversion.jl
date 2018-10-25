## Conversion to GAP

to_gap(str :: String)         = MakeString(str)
to_gap(v :: Any)              = v


function to_gap( v :: Bool ) :: MPtr
    if v
        return True
    else
        return False
    end
end

function to_gap(v :: Array{T, 1} where T) :: MPtr
    l = NewPlist(length(v))
    for i in 1:length(v)
        l[i] = v[i]
    end
    return l
end

function to_gap(v :: AbstractArray)
    return map(to_gap, v)
end

from_gap_string(obj :: MPtr) = CSTR_STRING(obj)

function from_gap_list( obj :: MPtr)
    len = length( obj )
    array = Array{Any,1}( nothing, len)
    for i in 1:len
        array[i] = obj[i]
    end
    return array
end

function from_gap_bool( obj :: MPtr ) :: Bool
    return obj == True
end

from_gap(x,::Type{Any})    = x
from_gap(x,::Type{String}) = from_gap_string( x )
from_gap(x,::Type{Bool})   = from_gap_bool( x )

function from_gap_list_type( obj :: MPtr, element_type :: DataType ) 
    len_list = length(obj)
    new_array = Array{element_type}(len_list)
    for i in 1:len_list
        new_array[ i ] = from_gap(obj[i],element_type)
    end
    return new_array
end

from_gap_list_int16( x ) = from_gap_list_type( x, Int16 )
from_gap_list_int32( x ) = from_gap_list_type( x, Int32 )
from_gap_list_int64( x ) = from_gap_list_type( x, Int64 )

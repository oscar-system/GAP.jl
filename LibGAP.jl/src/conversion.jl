## COnversion to GAP

to_gap(str :: String)         = MakeString(str)
to_gap(v :: Int32)            = v
to_gap(v :: Int64)            = v
to_gap(v :: MPtr)       = v

function to_gap( v :: Bool ) :: MPtr
    if v
        return True
    else
        return False
    end
end

function to_gap(v :: Array{Any, 1}) :: MPtr
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
    array = Array{Any,1}( len)
    for i in 1:len
        array[i] = obj[i]
    end
    return array
end

function from_gap_bool( obj :: MPtr ) :: Bool
    return obj == True
end

# from_gap(x,::Type{Int16}) = from_gap_int16( x )
# from_gap(x,::Type{Int32}) = from_gap_int32( x )
# from_gap(x,::Type{Int64}) = from_gap_int64( x )
# from_gap(x,::Type{String}) = from_gap_string( x )
# from_gap(x,::Type{Bool}) = from_gap_bool( x )

# function from_gap_list_type( obj :: GAP.GapObj, element_type :: DataType ) :: Array{Int64}
#     converted_list = from_gap_list( obj )
#     len_list = length(converted_list)
#     new_array = Array{element_type}(undef, len_list)
#     for i in 1:len_list
#         new_array[ i ] = from_gap(converted_list[i],element_type)
#     end
#     return new_array
# end

# from_gap_list_int16( x ) = from_gap_list_type( x, Int16 )
# from_gap_list_int32( x ) = from_gap_list_type( x, Int32 )
# from_gap_list_int64( x ) = from_gap_list_type( x, Int64 )




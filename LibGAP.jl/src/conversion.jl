
to_gap(x::Int64) = x
to_gap(x::GapFFE) = x
to_gap(x::MPtr) = x

function to_gap(obj::Array{T,1}) where T
    len = length(obj)
    ret_val = NewPlist(len)
    for i in 1:len
        ret_val[i] = to_gap(obj[i])
    end
    return ret_val
end

from_gap(obj::Int64) = obj
from_gap(obj::Int64,::Any) = obj
from_gap(obj::MPtr) = from_gap(obj,Any)
from_gap(obj::MPtr,::Type{Symbol}) =  Symbol(from_gap(obj))

function from_gap( obj :: MPtr, ::Type{Array{Any,1}} )
    len_list = length(obj)
    new_array = Array{Any,1}( undef, len_list)
    for i in 1:len_list
        new_array[ i ] = obj[i]
    end
    return new_array
end

function from_gap( obj :: MPtr, ::Type{Array{T,1}} ) where T
    len_list = length(obj)
    new_array = Array{T,1}( undef, len_list)
    for i in 1:len_list
        new_array[ i ] = from_gap(obj[i],T)
    end
    return new_array
end

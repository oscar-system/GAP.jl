## Converters

julia_to_gap(x::Int64)  = x
julia_to_gap(x::Int32)  = Int64(x)
julia_to_gap(x::Int16)  = Int64(x)
julia_to_gap(x::Int8)   = Int64(x)
julia_to_gap(x::UInt64) = BigInt(x)
julia_to_gap(x::UInt32) = Int64(x)
julia_to_gap(x::UInt16) = Int64(x)
julia_to_gap(x::UInt8)  = Int64(x)




julia_to_gap(x::GapFFE) = x
julia_to_gap(x::MPtr) = x

function julia_to_gap(obj::Array{T,1}) where T
    len = length(obj)
    ret_val = NewPlist(len)
    for i in 1:len
        ret_val[i] = julia_to_gap(obj[i])
    end
    return ret_val
end

## Defaults

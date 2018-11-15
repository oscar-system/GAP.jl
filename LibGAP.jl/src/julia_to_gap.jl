## Converters

## Default
julia_to_gap(x::GAPInputType) = x


## Integers
julia_to_gap(x::Int128)  = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
#julia_to_gap(x::Int64)  = x
julia_to_gap(x::Int32)  = Int64(x)
julia_to_gap(x::Int16)  = Int64(x)
julia_to_gap(x::Int8)   = Int64(x)

## Unsigned Integers
julia_to_gap(x::UInt128) = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::UInt64) = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::UInt32) = Int64(x)
julia_to_gap(x::UInt16) = Int64(x)
julia_to_gap(x::UInt8)  = Int64(x)

## BigInts
julia_to_gap(x::BigInt)  = MakeObjInt(x)

## Rationals
# TODO

## Floats
julia_to_gap(x::Float64) = NEW_MACFLOAT(x)
julia_to_gap(x::Float32) = NEW_MACFLOAT(Float64(x))
julia_to_gap(x::Float16) = NEW_MACFLOAT(Float64(x))

## Strings and symbols
julia_to_gap(x::AbstractString) = MakeString(x)
julia_to_gap(x::Symbol) = MakeString(string(x))

## Arrays
# TODO: check the following func
function julia_to_gap(obj::Array{T,1}) where T
    len = length(obj)
    ret_val = NewPlist(len)
    for i in 1:len
        ret_val[i] = julia_to_gap(obj[i])
    end
    return ret_val
end

## Dictionaries
# TODO

## Tuples
# TODO

## TODO: BitArray <-> blist; ranges; ...

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
function julia_to_gap(x::Rational{T}) where T <: Integer
    denom_julia = denominator(x)
    numer_julia = numerator(x)
    if denom_julia == 0
        if numer_julia >= 0
            return GAP.Globals.infinity
        else
            return -GAP.Globals.infinity
        end
    end
    numer = julia_to_gap(numer_julia)
    denom = julia_to_gap(denom_julia)
    return Globals.QUO(numer,denom)
end

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
function julia_to_gap(obj::Dict{T,S}) where S where T <: Union{Symbol,AbstractString}
    nr_entries = obj.count
    keys = Array{T,1}(undef,nr_entries)
    entries = Array{S,1}(undef,nr_entries)
    i = 1
    for (x,y) in obj
        keys[i] = x
        entries[i] = y
        i += 1
    end
    return GAP.Globals.CreateRecFromKeyValuePairList(julia_to_gap(keys),julia_to_gap(entries))
end

## Tuples
function julia_to_gap(obj::Tuple)
    size = length(obj)
    array = Array{Any,1}(undef,size)
    for i in 1:size
        array[i] = obj[i]
    end
    return julia_to_gap(array)
end

## TODO: BitArray <-> blist; ranges; ...

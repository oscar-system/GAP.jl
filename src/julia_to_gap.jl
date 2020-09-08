## Converters
"""
    julia_to_gap(input, recursion_dict = IdDict(); recursive = false)

Convert a julia object `input` to an appropriate GAP object.
If `recursive` is set to `true`, recursive conversions on
arrays, tuples, and dictionaries is performed.

The input `recursion_dict` should never be set by the user, it is meant to keep egality
of input data, by converting egal data to identical objects in GAP.

# Examples
```jldoctest
julia> GAP.julia_to_gap(1//3)
GAP: 1/3

julia> GAP.julia_to_gap("abc")
GAP: "abc"

julia> GAP.julia_to_gap([ [1, 2], [3, 4]])
GAP: [ <Julia: [1, 2]>, <Julia: [3, 4]> ]

julia> GAP.julia_to_gap([ [1, 2], [3, 4]], recursive = true)
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

```
"""
julia_to_gap(x::FFE) = x    # Default for actual GAP objects is to do nothing
julia_to_gap(x::Bool) = x   # Default for actual GAP objects is to do nothing

## Integers: general case first deal with things that fit into immediate
## integers, then falls back to converting to BigInt and calling into the GAP
## kernel API.
## TODO: we could provide more efficient conversion for UInt64, Int128, UInt128
## which avoids the conversion to BigInt, if we wanted to.
function julia_to_gap(x::Integer)
    # if it fits into a GAP immediate integer, convert x to Int64
    if x in -1<<60:(1<<60-1)
        return Int64(x)
    end
    # for the general case, fall back to BigInt
    return julia_to_gap(BigInt(x))
end

## Small integers types always fit into GAP immediate integers, and thus are
## represented by Int64 on the Julia side.
julia_to_gap(x::Int64) = x
julia_to_gap(x::Int32) = Int64(x)
julia_to_gap(x::Int16) = Int64(x)
julia_to_gap(x::Int8) = Int64(x)
julia_to_gap(x::UInt32) = Int64(x)
julia_to_gap(x::UInt16) = Int64(x)
julia_to_gap(x::UInt8) = Int64(x)

## BigInts are converted via a ccall
function julia_to_gap(x::BigInt)
    if x in -1<<60:(1<<60-1)
        return Int64(x)
    end
    return @lock_noexcept ccall(:MakeObjInt, GapObj, (Ptr{UInt64}, Cint), x.d, x.size)
end

## Rationals
function julia_to_gap(x::Rational{T}) where {T<:Integer}
    denom_julia = denominator(x)
    numer_julia = numerator(x)
    if denom_julia == 0
        if numer_julia >= 0
            return Globals.infinity
        else
            return -Globals.infinity
        end
    end
    numer = julia_to_gap(numer_julia)
    denom = julia_to_gap(denom_julia)
    return Globals.QUO(numer, denom)
end

## Floats
julia_to_gap(x::Float64) = NEW_MACFLOAT(x)
julia_to_gap(x::Float32) = NEW_MACFLOAT(Float64(x))
julia_to_gap(x::Float16) = NEW_MACFLOAT(Float64(x))

## Chars
julia_to_gap(x::Char) = CharWithValue(Cuchar(x))

## Strings and symbols
julia_to_gap(x::AbstractString) = MakeString(string(x))
julia_to_gap(x::Symbol) = MakeString(string(x))

## Generic caller for optional arguments
julia_to_gap(obj::Any, recursion_dict; recursive = true) = julia_to_gap(obj)

## Arrays (including BitArray{1})
function julia_to_gap(
    obj::Array{T,1},
    recursion_dict::IdDict{Any,Any} = IdDict();
    recursive = false,
) where {T}

    len = length(obj)
    ret_val = NewPlist(len)
    if recursive
        recursion_dict[obj] = ret_val
    end
    for i = 1:len
        x = obj[i]
        if x === nothing
            continue
        end
        if recursive
            x = get!(recursion_dict, x) do
                julia_to_gap(x, recursion_dict; recursive = recursive)
            end
        end
        ret_val[i] = x
    end
    return ret_val
end

## Convert two dimensional arrays
function julia_to_gap(
    obj::Array{T,2},
    recursion_dict::IdDict{Any,Any} = IdDict();
    recursive::Bool = false,
) where {T}
    (rows, cols) = size(obj)
    if haskey(recursion_dict, obj)
        return recursion_dict[obj]
    end
    ret_val = NewPlist(rows)
    if recursive
        recursion_dict[obj] = ret_val
    end
    for i = 1:rows
        ret_val[i] = julia_to_gap(obj[i, :], recursion_dict; recursive = recursive)
    end
    return ret_val
end

## Tuples
function julia_to_gap(
    obj::Tuple,
    recursion_dict::IdDict{Any,Any} = IdDict();
    recursive::Bool = false,
)
    array = collect(Any, obj)
    return julia_to_gap(array, recursion_dict, recursive = recursive)
end

## Ranges
# FIXME: eventually check that the values are valid for GAP ranges
function julia_to_gap(range::UnitRange{T}) where {T<:Integer}
    return evalstr("[" * string(range.start) * ".." * string(range.stop) * "]")
end

function julia_to_gap(range::StepRange{T1,T2}) where {T1<:Integer,T2<:Integer}
    return evalstr(
        "[" *
        string(range.start) *
        "," *
        string(range.start + range.step) *
        ".." *
        string(range.stop) *
        "]",
    )
end

## Dictionaries
function julia_to_gap(
    obj::Dict{T,S},
    recursion_dict::IdDict{Any,Any} = IdDict();
    recursive::Bool = false,
) where {S} where {T<:Union{Symbol,AbstractString}}

    record = NewPrecord(0)
    if recursive
        recursion_dict[obj] = record
    end
    for (x, y) in obj
        x = Globals.RNamObj(MakeString(string(x)))
        if recursive
            y = get!(recursion_dict, y) do
                julia_to_gap(y, recursion_dict; recursive = recursive)
            end
        end
        Globals.ASS_REC(record, x, y)
    end

    return record
end

## GAP objects:
## We have to do something only if recursive conversion is required,
## and if `obj` contains Julia subobjects;
## in this case, `obj` is a GAP list or record.
## An example of such an `obj` is `GAP.julia_to_gap([[1]])`.
function julia_to_gap(
    obj::GapObj,
    recursion_dict::IdDict{Any,Any} = IdDict();
    recursive::Bool = false,
)
    if ! recursive
        ret_val = obj
    elseif Globals.IsList(obj)
        len = length(obj)
        ret_val = NewPlist(len)
        recursion_dict[obj] = ret_val
        for i = 1:len
             ret_val[i] = julia_to_gap(obj[i], recursion_dict; recursive = recursive)
        end
    elseif Globals.IsRecord(obj)
        ret_val = NewPrecord(0)
        recursion_dict[obj] = ret_val
        for x in gap_to_julia(Globals.RecNames(obj))
            Globals.ASS_REC(ret_val, x, julia_to_gap(Globals.ELM_REC(obj, x), recursion_dict; recursive = true))
        end
    else
        ret_val = obj
    end

    return ret_val
end

julia_to_gap(func::Function) = NewJuliaFunc(func)

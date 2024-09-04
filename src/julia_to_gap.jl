## Converters
"""
    julia_to_gap(input, recursion_dict::GapCacheDict = nothing; recursive::Bool = false)

Convert a julia object `input` to an appropriate GAP object.
If `recursive` is set to `true`, recursive conversion on
arrays, tuples, and dictionaries is performed.

The input `recursion_dict` should never be set by the user, it is meant to keep egality
of input data, by converting equal data to identical objects in GAP.

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

The following `julia_to_gap` conversions are supported by GAP.jl.
(Other Julia packages may provide conversions for more Julia objects.)

| Julia type                           | GAP filter   |
|--------------------------------------|--------------|
| `Int8`, `Int16`, ..., `BigInt`       | `IsInt`      |
| `GapFFE`                             | `IsFFE`      |
| `Bool`                               | `IsBool`     |
| `Rational{T}`                        | `IsRat`      |
| `Float16`, `Float32`, `Float64`      | `IsFloat`    |
| `AbstractString`                     | `IsString`   |
| `Symbol`                             | `IsString`   |
| `Char`                               | `IsChar`     |
| `Vector{T}`                          | `IsList`     |
| `Vector{Bool}`, `BitVector`          | `IsBList`    |
| `Tuple{T}`                           | `IsList`     |
| `Matrix{T}`                          | `IsList`     |
| `Dict{String, T}`, `Dict{Symbol, T}` | `IsRecord`   |
| `UnitRange{T}`, `StepRange{T, S}`    | `IsRange`    |
| `Function`                           | `IsFunction` |
"""
julia_to_gap(x, cache::GapCacheDict = nothing; recursive::Bool = false) = julia_to_gap_internal(x, cache, recursive)

# The calls to `GAP.@install` install methods for `julia_to_gap_internal`
# so we must make sure it is declared before
function julia_to_gap_internal end

GAP.@install GapObj(x::FFE) = x    # Default for actual GAP objects is to do nothing
GAP.@install GapObj(x::Bool) = x    # Default for actual GAP objects is to do nothing

## Integers: general case first deal with things that fit into immediate
## integers, then falls back to converting to BigInt and calling into the GAP
## kernel API.
## TODO: we could provide more efficient conversion for UInt64, Int128, UInt128
## which avoids the conversion to BigInt, if we wanted to.
function julia_to_gap_internal(x::Integer, cache::GapCacheDict, recursive::Bool)
    # if it fits into a GAP immediate integer, convert x to Int64
    x in -1<<60:(1<<60-1) && return Int64(x)
    # for the general case, fall back to BigInt
    return julia_to_gap_internal(BigInt(x), cache, recursive)
end

## Small integers types always fit into GAP immediate integers, and thus are
## represented by Int64 on the Julia side.
GAP.@install GapObj(x::Int64) = x
GAP.@install GapObj(x::Int32) = Int64(x)
GAP.@install GapObj(x::Int16) = Int64(x)
GAP.@install GapObj(x::Int8) = Int64(x)
GAP.@install GapObj(x::UInt32) = Int64(x)
GAP.@install GapObj(x::UInt16) = Int64(x)
GAP.@install GapObj(x::UInt8) = Int64(x)

GAP.@install function GapObj(x::UInt)
    x < (1<<60) && return Int64(x)
    return ccall((:ObjInt_UInt, libgap), GapObj, (UInt64, ), x)
end

## BigInts are converted via a ccall
GAP.@install function GapObj(x::BigInt)
    x in -1<<60:(1<<60-1) && return Int64(x)
    return GC.@preserve x ccall((:MakeObjInt, libgap), GapObj, (Ptr{UInt64}, Cint), x.d, x.size)
end

## Rationals
function julia_to_gap_internal(x::Rational{T}, cache::GapCacheDict, recursive::Bool) where {T<:Integer}
    denom_julia = denominator(x)
    numer_julia = numerator(x)
    if denom_julia == 0
        if numer_julia >= 0
            return Globals.infinity
        else
            return -Globals.infinity
        end
    end
    numer = julia_to_gap_internal(numer_julia, cache, recursive)
    denom = julia_to_gap_internal(denom_julia, cache, recursive)
    return Wrappers.QUO(numer, denom)
end

## Floats
GAP.@install GapObj(x::Float64) = NEW_MACFLOAT(x)
GAP.@install GapObj(x::Float32) = NEW_MACFLOAT(Float64(x))
GAP.@install GapObj(x::Float16) = NEW_MACFLOAT(Float64(x))

## Chars
GAP.@install GapObj(x::Char) = CharWithValue(Cuchar(x))

## Strings and symbols
GAP.@install GapObj(x::AbstractString) = MakeString(string(x))
GAP.@install GapObj(x::Symbol) = MakeString(string(x))

## Arrays (including BitVector)
function julia_to_gap_internal(
    obj::AbstractVector{T},
    recursion_dict::GapCacheDict,
    recursive::Bool,
) where {T}

    if recursion_dict !== nothing && haskey(recursion_dict, obj)
      return recursion_dict[obj]
    end
    len = length(obj)
    ret_val = NewPlist(len)
    if recursive
        if recursion_dict === nothing
          recursion_dict = RecDict()
        end
        recursion_dict[obj] = ret_val
    end
    for i = 1:len
        x = obj[i]
        if x === nothing
            continue
        end
        if recursive
            res = get!(recursion_dict::RecDict, x) do
                julia_to_gap_internal(x, recursion_dict::RecDict, recursive)
            end
        else
            res = x
        end
        ret_val[i] = res
    end
    return ret_val
end

## Convert two dimensional arrays
function julia_to_gap_internal(
    obj::Matrix{T},
    recursion_dict::GapCacheDict,
    recursive::Bool,
) where {T}
    if recursion_dict !== nothing && haskey(recursion_dict, obj)
      return recursion_dict[obj]
    end
    (rows, cols) = size(obj)
    ret_val = NewPlist(rows)
    if recursive
        if recursion_dict === nothing
          recursion_dict = RecDict()
        end
        recursion_dict[obj] = ret_val
    end
    for i = 1:rows
        # Note that we need not check whether the row is in `recursion_dict`
        # because we are just now creating the object.
        ret_val[i] = julia_to_gap_internal(obj[i, :], recursion_dict, recursive)
    end
    return ret_val
end

## Tuples
function julia_to_gap_internal(
    obj::Tuple,
    recursion_dict::GapCacheDict,
    recursive::Bool,
)
    array = collect(Any, obj)
    return julia_to_gap_internal(array, recursion_dict, recursive)
end

## Ranges
GAP.@install function GapObj(r::AbstractRange{<:Integer})
    res = NewRange(length(r), first(r), step(r))
    Wrappers.IsRange(res) || throw(ConversionError(r, GapObj))
    return res
end

## Dictionaries
function julia_to_gap_internal(
    obj::Dict{T,S},
    recursion_dict::GapCacheDict,
    recursive::Bool,
) where {S} where {T<:Union{Symbol,AbstractString}}

    record = NewPrecord(0)
    if recursive
        if recursion_dict === nothing
          recursion_dict = RecDict()
        end
        recursion_dict[obj] = record
    end
    for (x, y) in obj
        x = Wrappers.RNamObj(MakeString(string(x)))
        if recursive
            res = get!(recursion_dict::RecDict, y) do
                julia_to_gap_internal(y, recursion_dict::RecDict, recursive)
            end
        else
            res = y
        end
        Wrappers.ASS_REC(record, x, res)
    end

    return record
end

## GAP objects:
## We have to do something only if recursive conversion is required,
## and if `obj` contains Julia subobjects;
## in this case, `obj` is a GAP list or record.
## An example of such an `obj` is `GAP.julia_to_gap([[1]])`.
function julia_to_gap_internal(
    obj::GapObj,
    recursion_dict::GapCacheDict,
    recursive::Bool,
)
    if ! recursive
        ret_val = obj
    elseif Wrappers.IsList(obj)
        len = length(obj)
        ret_val = NewPlist(len)
        if recursion_dict === nothing
          recursion_dict = RecDict()
        end
        recursion_dict[obj] = ret_val
        for i = 1:len
            x = obj[i]
            ret_val[i] = get!(recursion_dict::RecDict, x) do
                julia_to_gap_internal(x, recursion_dict::RecDict, recursive)
            end
        end
    elseif Wrappers.IsRecord(obj)
        ret_val = NewPrecord(0)
        if recursion_dict === nothing
          recursion_dict = RecDict()
        end
        recursion_dict[obj] = ret_val
        for xx in Wrappers.RecNames(obj)::GapObj
            x = Wrappers.RNamObj(xx)
            y = Wrappers.ELM_REC(obj, x)
            res = get!(recursion_dict::RecDict, y) do
                julia_to_gap_internal(y, recursion_dict::RecDict, recursive)
            end
            Wrappers.ASS_REC(ret_val, x, res)
        end
    else
        ret_val = obj
    end

    return ret_val
end

GAP.@install GapObj(func::Function) = WrapJuliaFunc(func)

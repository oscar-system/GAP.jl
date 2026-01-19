#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##


## Converters
"""
    GapObj(input, recursive::Bool = false)

One can use the type [`GapObj`](@ref) as a constructor,
in order to convert the Julia object `input` to an appropriate GAP object.

If `recursive` is set to `true`, recursive conversion of nested Julia objects
(arrays, tuples, and dictionaries) is performed.

# Examples
```jldoctest
julia> GapObj(1//3)
GAP: 1/3

julia> GapObj("abc")
GAP: "abc"

julia> GapObj([1 2; 3 4])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GapObj([[1, 2], [3, 4]])
GAP: [ <Julia: [1, 2]>, <Julia: [3, 4]> ]

julia> GapObj([[1, 2], [3, 4]], true)
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GapObj([[1, 2], [3, 4]], recursive = true)
GAP: [ [ 1, 2 ], [ 3, 4 ] ]
```

Note that this conversion is *not* restricted to outputs that actually are
of type `GapObj`,
also GAP integers, finite field elements, and booleans can be created
by the constructor `GapObj`.

```jldoctest
julia> res = GapObj(42);  res isa GapObj
false

julia> res isa GAP.Obj
true
```

The following `GapObj` conversions are supported by GAP.jl.

| Julia type                           | GAP filter   |
|--------------------------------------|--------------|
| `Int8`, `Int16`, ..., `BigInt`       | `IsInt`      |
| `FFE`                                | `IsFFE`      |
| `Bool`                               | `IsBool`     |
| `Rational{T}`                        | `IsRat`      |
| `Float16`, `Float32`, `Float64`      | `IsFloat`    |
| `AbstractString`                     | `IsString`   |
| `Symbol`                             | `IsString`   |
| `Char`                               | `IsChar`     |
| `Vector{T}`                          | `IsList`     |
| `Vector{Bool}`, `BitVector`          | `IsBList`    |
| `Set{T}`                             | `IsList`     |
| `Tuple{T}`                           | `IsList`     |
| `Matrix{T}`                          | `IsList`     |
| `Dict{String, T}`, `Dict{Symbol, T}` | `IsRecord`   |
| `UnitRange{T}`, `StepRange{T, S}`    | `IsRange`    |
| `Function`                           | `IsFunction` |

Other Julia packages may provide conversions for more Julia types.
"""
GapObj(x; recursive::Bool = false) = GapObj_internal(x, nothing, BoolVal(recursive))

# The calls to `GAP.@install` install methods for `GAP.GapObj_internal`
# so we must make sure it is declared before
"""
    GapObj_internal(x::Any, rec_dict::GapCacheDict, ::Val{recursive}) where recursive

Return a `GapObj` that corresponds to the Julia object `x`.

The value of `recursive` can be `GAP.BoolVal(true)` or `GAP.BoolVal(false)`,
the former meaning that subobjects of `x` shall get converted recursively,
the latter meaning that no recursion is requested.
In the case of recursive conversion, a dictionary is used as the value of
`rec_dict` in order to make sure that identical subobjects of `x` correspond
to identical subobjects in the result of the conversion.
This dictionary is created automatically on demand,
it should never be supplied by the user.

The function `GapObj_internal` may call `GapObj`,
but the other direction is not allowed.

New methods for Julia-to-GAP conversions must be implemented via
methods for `GapObj_internal` not for `GapObj`.
"""
function GapObj_internal end


# The idea behind `_needs_tracking_julia_to_gap` is to avoid the creation
# of a dictionary for tracking subobjects if their type implies that
# no such tracking is needed/wanted.
#
# We need anyhow a `_needs_tracking_julia_to_gap` method for `Any`,
# for example in order to convert a Julia object of type `Dict{Symbol, Any}`
# to a GAP record.
# Thus we have a default method returning `true`.
#
# Methods for those types that want `false` have to be installed explicitly.
# The `GapObj` methods arising from `GAP.@install` don't handle recursion
# and the macro automatically installs such a `_needs_tracking_julia_to_gap`
# method.
_needs_tracking_julia_to_gap(::Any) = true


GAP.@install GapObj(x::FFE) = x    # Default for actual GAP objects is to do nothing
GAP.@install GapObj(x::Bool) = x    # Default for actual GAP objects is to do nothing

## Integers:
## We do not want to track conversion for any concrete integer types.
@install GapObj(x::Integer) = x in -1<<60:(1<<60-1) ? Int64(x) : GapObj(BigInt(x))

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
    return @ccall libgap.ObjInt_UInt(x::UInt64)::GapObj
end

## BigInts are converted via a ccall
GAP.@install function GapObj(x::BigInt)
    x in -1<<60:(1<<60-1) && return Int64(x)
    return GC.@preserve x @ccall libgap.MakeObjInt(x.d::Ptr{UInt64}, x.size::Cint)::GapObj
end

## Rationals
function GapObj_internal(x::Rational{T}, cache::GapCacheDict, ::Val{recursive}) where {T<:Integer, recursive}
    denom_julia = denominator(x)
    numer_julia = numerator(x)
    if denom_julia == 0
        if numer_julia >= 0
            return Globals.infinity
        else
            return -Globals.infinity
        end
    end
    numer = GapObj_internal(numer_julia, cache, BoolVal(recursive))
    denom = GapObj_internal(denom_julia, cache, BoolVal(recursive))
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
GAP.@install GapObj(x::Symbol) = MakeString(x)

## Arrays (including BitVector)
function GapObj_internal(
    obj::AbstractVector{T},
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, obj) && return recursion_dict[obj]

    len = length(obj)
    ret_val = NewPlist(len)

    recursion_dict = recursion_info_g(T, obj, ret_val, GAP.BoolVal(recursive), recursion_dict)

    # Set the subobjects.
    for i = 1:len
        x = obj[i]
        if x === nothing
            continue
        end
        res = recursive ? GapObj_internal(x, recursion_dict, Val(true)) : x
        ret_val[i] = res
    end

    return ret_val
end

## Sets
function GapObj_internal(
    obj::Set{T},
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, obj) && return recursion_dict[obj]

    ret_val = NewPlist(length(obj))

    recursion_dict = recursion_info_g(T, obj, ret_val, GAP.BoolVal(recursive), recursion_dict)

    for x in obj
        res = recursive ? GapObj_internal(x, recursion_dict, Val(true)) : x
        Wrappers.Add(ret_val, res)
    end
    Wrappers.Sort(ret_val)
    @assert Wrappers.IsSet(ret_val)

    return ret_val
end

## Convert two dimensional arrays
function GapObj_internal(
    obj::Matrix{T},
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, obj) && return recursion_dict[obj]

    rows = size(obj, 1)
    ret_val = NewPlist(rows)

    recursion_dict = recursion_info_g(T, obj, ret_val, GAP.BoolVal(recursive), recursion_dict)

    for i = 1:rows
    # TODO: don't work rowwise?!?
        ret_val[i] = GapObj_internal(obj[i, :], recursion_dict, BoolVal(recursive))
    end
    return ret_val
end

## Tuples
function GapObj_internal(
    obj::Tuple,
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where recursive
    array = collect(Any, obj)
    return GapObj_internal(array, recursion_dict, BoolVal(recursive))
end

## Ranges
GAP.@install function GapObj(r::AbstractRange{<:Integer})
    res = NewRange(length(r), first(r), step(r))
    Wrappers.IsRange(res) || throw(ConversionError(r, GapObj))
    return res
end

## Dictionaries
function GapObj_internal(
    obj::Dict{S,T},
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where {T, S<:Union{Symbol,AbstractString}, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, obj) && return recursion_dict[obj]

    ret_val = NewPrecord(0)

    recursion_dict = recursion_info_g(T, obj, ret_val, GAP.BoolVal(recursive), recursion_dict)

    for (x, y) in obj
        x = Wrappers.RNamObj(MakeString(string(x)))
        res = recursive ? GapObj_internal(y, recursion_dict, Val(true)) : y
        Wrappers.ASS_REC(ret_val, x, res)
    end

    return ret_val
end

## GAP objects:
## We have to do something only if recursive conversion is required,
## and if `obj` contains Julia subobjects;
## in this case, `obj` is a GAP list or record.
## An example of such an `obj` is `GapObj([[1]])`.
function GapObj_internal(
    obj::GapObj,
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where {recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, obj) && return recursion_dict[obj]

    if ! recursive
        ret_val = obj
    elseif Wrappers.IsList(obj)
        len = length(obj)
        ret_val = NewPlist(len)
        if recursion_dict === nothing
            # We have no type information that allows us to avoid the dictionary.
            recursion_dict = RecDict_g()
        end
        recursion_dict[obj] = ret_val
        for i = 1:len
            x = obj[i]
            ret_val[i] = GapObj_internal(x, recursion_dict::RecDict_g, BoolVal(recursive))
        end
    elseif Wrappers.IsRecord(obj)
        ret_val = NewPrecord(0)
        if recursion_dict === nothing
            # We have no type information that allows us to avoid the dictionary.
            recursion_dict = RecDict_g()
        end
        recursion_dict[obj] = ret_val
        for xx in Wrappers.RecNames(obj)::GapObj
            x = Wrappers.RNamObj(xx)
            y = Wrappers.ELM_REC(obj, x)
            res = GapObj_internal(y, recursion_dict::RecDict_g, BoolVal(recursive))
            Wrappers.ASS_REC(ret_val, x, res)
        end
    else
        ret_val = obj
    end

    return ret_val
end

GAP.@install GapObj(func::Function) = WrapJuliaFunc(func)

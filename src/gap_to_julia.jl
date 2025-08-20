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


#############################################################################
##
## the function `gap_to_julia_internal`

"""
    gap_to_julia_internal(::Type{T}, x::Any, rec_dict::JuliaCacheDict, ::Val{recursive}) where {T, recursive}

returns an object of type `T` that corresponds to the GAP object `x`.

The function `gap_to_julia` may call `gap_to_julia_internal`,
but the other direction is not allowed.

New methods for the conversion from GAP to Julia shall be implemented via
methods for `gap_to_julia_internal` not for `gap_to_julia`.
"""
function gap_to_julia_internal end

## Handle "conversion" to GAP.Obj and GapObj (may occur in recursions).
gap_to_julia_internal(::Type{Obj}, x::Obj, ::JuliaCacheDict, ::Val{recursive}) where recursive = x
gap_to_julia_internal(::Type{GapObj}, x::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive = x

## Integers
gap_to_julia_internal(::Type{T}, x::GapInt, ::JuliaCacheDict, ::Val{recursive}) where {T<:Integer, recursive} = T(x)

## Rationals
gap_to_julia_internal(::Type{Rational{T}}, x::GapInt, ::JuliaCacheDict, ::Val{recursive}) where {T<:Integer, recursive} = Rational{T}(x)

## Floats
gap_to_julia_internal(::Type{T}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where {T<:AbstractFloat, recursive} = T(obj)

## Chars
gap_to_julia_internal(::Type{Char}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive = Char(obj)
gap_to_julia_internal(::Type{Cuchar}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive = Cuchar(obj)

## Strings
gap_to_julia_internal(::Type{String}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive = String(obj)

## Symbols
gap_to_julia_internal(::Type{Symbol}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive = Symbol(obj)

## Convert GAP string to Vector{UInt8}
function gap_to_julia_internal(::Type{Vector{UInt8}}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive
    Wrappers.IsStringRep(obj) && return CSTR_STRING_AS_ARRAY(obj)
    Wrappers.IsList(obj) && return UInt8[gap_to_julia_internal(UInt8, obj[i], nothing, Val(false)) for i = 1:length(obj)]
    throw(ConversionError(obj, Vector{UInt8}))
end

## BitVectors
gap_to_julia_internal(::Type{BitVector}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive = BitVector(obj)

## Ranges
gap_to_julia_internal(::Type{T}, obj::GapObj, recursion_dict::JuliaCacheDict, ::Val{recursive}) where {T<:UnitRange, recursive} = T(obj)
gap_to_julia_internal(::Type{T}, obj::GapObj, recursion_dict::JuliaCacheDict, ::Val{recursive}) where {T<:StepRange, recursive} = T(obj)

## Functions
function gap_to_julia_internal(::Type{Function}, obj::GapObj, ::JuliaCacheDict, ::Val{recursive}) where recursive
  Wrappers.IS_JULIA_FUNC(obj) && return UnwrapJuliaFunc(obj)
  throw(ConversionError(obj, Function))
end


## Vectors
function gap_to_julia_internal(
    TT::Type{Vector{T}},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]
    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)

    if Wrappers.IsList(obj)
        islist = true
    elseif Wrappers.IsVectorObj(obj)
        islist = false
    else
        throw(ConversionError(obj, TT))
    end

    len_list = length(obj)
    new_array = TT(undef, len_list)
    recursion_dict = handle_recursion((obj, TT), new_array, recursive, rec_dict)
    for i = 1:len_list
        if islist
            current_obj = ElmList(obj, i)  # returns 'nothing' for holes in the list
        else
            # vector objects aren't lists,
            # but the function for accessing entries is `ELM_LIST`
            current_obj = Wrappers.ELM_LIST(obj, i)
        end
        if recursive && !isbitstype(typeof(current_obj))
            new_array[i] =
                gap_to_julia_internal(T, current_obj, recursion_dict, Val(recursive))
        else
            new_array[i] = current_obj
        end
    end

    return new_array::TT
end

## Matrices or lists of lists
function gap_to_julia_internal(
    TT::Type{Matrix{T}},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]
    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)

    if Wrappers.IsMatrixObj(obj)
        nrows = Wrappers.NumberRows(obj)::Int
        ncols = Wrappers.NumberColumns(obj)::Int
    elseif Wrappers.IsList(obj)
        nrows = length(obj)
        ncols = nrows == 0 ? 0 : length(obj[1])
    else
        throw(ConversionError(obj, TT))
    end

    elm = Wrappers.ELM_MAT
    new_array = TT(undef, nrows, ncols)
    recursion_dict = handle_recursion((obj, TT), new_array, recursive, rec_dict)

    for i = 1:nrows, j = 1:ncols
        current_obj = elm(obj, i, j)
        if recursive && !isbitstype(typeof(current_obj))
            new_array[i, j] =
                gap_to_julia_internal(T, current_obj, recursion_dict, Val(recursive))
        else
            new_array[i, j] = current_obj
        end
    end
    return new_array::TT
end

## Sets
## Assume that the argument `obj` of this function is not self-referential,
## for example we cannot really sort a self-referential GAP list.
## Then we need not worry about creating the result in the end,
## and then adding it to the dictionary that is needed for the recursion.
function gap_to_julia_internal(
    TT::Type{Set{T}},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]
    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)

    if Wrappers.IsCollection(obj)
        newobj = Wrappers.AsSet(obj)
    elseif Wrappers.IsList(obj)
        # The list entries may be not comparable via `<`.
        newobj = Wrappers.DuplicateFreeList(obj)
    else
        throw(ConversionError(obj, TT))
    end
    len_list = length(newobj)
    new_array = Vector{T}(undef, len_list)
    for i = 1:len_list
        current_obj = ElmList(newobj, i)
        if recursive && !isbitstype(typeof(current_obj))
            new_array[i] =
                gap_to_julia_internal(T, current_obj, rec_dict, Val(recursive))
        else
            new_array[i] = current_obj
        end
    end
    ret_val = TT(new_array)
    handle_recursion((obj, TT), ret_val, recursive, rec_dict)
    return ret_val
end

## Tuples
## Note that the tuple type prescribes the types of the entries,
## thus we have to convert at least also the next layer,
## even if `recursive == false` holds.
function gap_to_julia_internal(
    TT::Type{T},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {T<:Tuple, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]
    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)

    !Wrappers.IsList(obj) && throw(ConversionError(obj, T))
    parameters = T.parameters
    len = length(parameters)
    length(obj) == len ||
        throw(ArgumentError("length of $obj does not match type $T"))
    list = [
        gap_to_julia_internal(parameters[i], obj[i], rec_dict, Val(recursive))
        for i = 1:len
    ]

    ret_val = T(list)
    recursion_dict = handle_recursion((obj, TT), ret_val, recursive, rec_dict)
    return ret_val
end

## Dictionaries
function gap_to_julia_internal(
    TT::Type{Dict{Symbol,T}},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]
    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)

    !Wrappers.IsRecord(obj) && throw(ConversionError(obj, TT))
    dict = TT()
    recursion_dict = handle_recursion((obj, TT), dict, recursive, rec_dict)

    names = Wrappers.RecNames(obj)
    names_list = Vector{Symbol}(names)
    for key in names_list
      current_obj = getproperty(obj, key)
      if recursive && !isbitstype(typeof(current_obj))
        dict[key] =
          gap_to_julia_internal(T, current_obj, recursion_dict, Val(true))
      else
        dict[key] = current_obj
      end
    end
    return dict
end

## Generic method:
## If it gets called then none of the more special methods is applicable.
## - If `obj` is a `GapObj` to be "converted" to a supertype `T` of its type
##   then return `obj` except if recursive conversion is requested.
##   In the latter case check whether the default Julia type for `obj` is a
##   subtype of `T`, and if yes then convert `obj` to that type.
## - If `obj` is not a `GapObj` then recursion has no meaning,
##   and either `obj` is already of type `T` (and we return `obj`)
##   or we give up because the GAP to Julia conversion is not the right
##   situation.
##
function gap_to_julia_internal(
    ::Type{T},
    obj::Any,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {T, recursive}

  if obj isa GapObj
    (obj isa T) && !recursive && return obj
    D, rec = _default_type(obj, recursive)
    (D === T || !(D <: T)) && throw(ConversionError(obj, T))
    return gap_to_julia_internal(D, obj, recursion_dict, Val(rec))
  else
    (obj isa T) && return obj
    throw(ConversionError(obj, T))
  end
end


#############################################################################
##
## the function `gap_to_julia`
##
## - If no target type is given and if `obj` is a `GapObj`
##   then choose a default Julia type.
##
## - If no type is given and if `obj` is another `GAP.Obj`
##   then return the input.
##
## - If a type `T` is given but no specific method fits
##   and if `obj` is a `GapObj`
##   and if `recursive == true` holds then we want to convert recursively;
##   for that, we take `_default_type(obj, true)` instead,
##   and accept this type if it is a subtype of `T`.
##   (This happens for example inside recursions where `T == Any`,
##   for example when one wants to convert a GAP list of lists recursively
##   to a `Vector{Any}`.)

"""
    gap_to_julia([type, ]x, recursion_dict::JuliaCacheDict=nothing; recursive::Bool=true)

Try to convert the object `x` to a Julia object of type `type`.
If `x` is a `GapObj` then the conversion rules are defined in the
manual of the GAP package JuliaInterface.
If `x` is another `GAP.Obj` (for example a `Int64`) then the result is
defined in Julia by `type`.

The parameter `recursion_dict` is used to preserve the identity
of converted subobjects and should never be given by the user.

For GAP lists and records, it makes sense to either convert also the subobjects
recursively, or to keep the subobjects as they are;
the behaviour is controlled by `recursive`, which can be `true` or `false`.

# Examples
```jldoctest
julia> GAP.gap_to_julia(GapObj(1//3))
1//3

julia> GAP.gap_to_julia(GapObj("abc"))
"abc"

julia> val = GapObj([ 1 2 ; 3 4 ])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GAP.gap_to_julia( val )
2-element Vector{Any}:
 Any[1, 2]
 Any[3, 4]

julia> GAP.gap_to_julia( val, recursive = false )
2-element Vector{Any}:
 GAP: [ 1, 2 ]
 GAP: [ 3, 4 ]

julia> GAP.gap_to_julia( Vector{GapObj}, val )
2-element Vector{GapObj}:
 GAP: [ 1, 2 ]
 GAP: [ 3, 4 ]

julia> GAP.gap_to_julia( Matrix{Int}, val )
2×2 Matrix{Int64}:
 1  2
 3  4
```

The following `gap_to_julia` conversions are supported by GAP.jl.
(Other Julia packages may provide conversions for more GAP objects.)

| GAP filter    | default Julia type       | other Julia types     |
|---------------|--------------------------|-----------------------|
| `IsInt`       | `BigInt`                 | `T <: Integer`        |
| `IsFFE`       | `FFE`                    |                       |
| `IsBool`      | `Bool`                   |                       |
| `IsRat`       | `Rational{BigInt}`       | `Rational{T}`         |
| `IsFloat`     | `Float64`                | `T <: AbstractFloat`  |
| `IsChar`      | `Cuchar`                 | `Char`                |
| `IsStringRep` | `String`                 | `Symbol`, `Vector{T}` |
| `IsRangeRep`  | `StepRange{Int64,Int64}` | `Vector{T}`           |
| `IsBListRep`  | `BitVector`              | `Vector{T}`           |
| `IsList`      | `Vector{Any}`            | `Vector{T}`           |
| `IsVectorObj` | `Vector{Any}`            | `Vector{T}`           |
| `IsMatrixObj` | `Matrix{Any}`            | `Matrix{T}`           |
| `IsRecord`    | `Dict{Symbol, Any}`      | `Dict{Symbol, T}`     |
"""
function gap_to_julia end

gap_to_julia(x::Bool) = x
gap_to_julia(x::Int) = x
gap_to_julia(x::FFE) = x
gap_to_julia(T::Type, x::Any; recursive::Bool = true) = gap_to_julia_internal(T, x, nothing, Val(recursive))
gap_to_julia(::Type{Any}, x::Any; recursive::Bool = true) = x
gap_to_julia(::T, x::Nothing; recursive::Bool = true) where {T<:Type} = nothing
gap_to_julia(::Type{Any}, x::Nothing; recursive::Bool = true) = nothing
gap_to_julia(x::Any; recursive::Bool = true) = x

function _default_type(x::GapObj, recursive::Bool)
  GAP_IS_INT(x) && return BigInt, false
  GAP_IS_RAT(x) && return Rational{BigInt}, false
  GAP_IS_MACFLOAT(x) && return Float64, false
  GAP_IS_CHAR(x) && return Cuchar, false
  Wrappers.IsStringRep(x) && return String, false
  Wrappers.IsRangeRep(x) && return StepRange{Int64,Int64}, false
  Wrappers.IsBlistRep(x) && return BitVector, false
  Wrappers.IsList(x) && return Vector{Any}, recursive
  Wrappers.IsMatrixObj(x) && return Matrix{Any}, recursive
  Wrappers.IsVectorObj(x) && return Vector{Any}, recursive
  Wrappers.IsRecord(x) && return Dict{Symbol,Any}, recursive
  Wrappers.IS_JULIA_FUNC(x) && return Function, false
  return Any, false
end

function gap_to_julia(x::GapObj; recursive::Bool = true)
  T, recursive = _default_type(x, recursive)
  T == Any && throw(ConversionError(x, "any known type"))
  return gap_to_julia_internal(T, x, nothing, Val(recursive))
end


#############################################################################
##
## the function `_gap_to_julia`

"""
    _gap_to_julia([::Type{T}, ]x::Obj[, recursive::Bool])

This function implements the GAP function GAPToJulia.
It just delegates to `gap_to_julia`.
Its purpose is to turn the `recursive` argument into a keyword argument,
which is easier in Julia than in GAP.
"""
function _gap_to_julia end

_gap_to_julia(x::Obj) = gap_to_julia(x)
_gap_to_julia(::Type{T}, x::Obj) where {T} = gap_to_julia(T, x)
_gap_to_julia(::Type{T}, x::Obj, recursive::Bool) where {T} =
    gap_to_julia(T, x; recursive)

# for GapObj, gap_to_julia knows default types
_gap_to_julia(x::GapObj, recursive::Bool) = gap_to_julia(x; recursive)

# for GAP.Obj except GapObj, we can do better
_gap_to_julia(x::Bool, recursive::Bool) = x
_gap_to_julia(x::Int, recursive::Bool) = x
_gap_to_julia(x::FFE, recursive::Bool) = x

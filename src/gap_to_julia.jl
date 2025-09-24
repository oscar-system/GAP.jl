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
    ::Type{TT},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {TT <: Vector, recursive}

    if Wrappers.IsList(obj)
        islist = true
    elseif Wrappers.IsVectorObj(obj)
        islist = false
    else
        throw(ConversionError(obj, TT))
    end

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]

    len_list = length(obj)
    ret_val = TT(undef, len_list)::TT

    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)
    recursion_dict = handle_recursion((obj, TT), ret_val, recursive, rec_dict)

    for i = 1:len_list
        if islist
            current_obj = ElmList(obj, i)  # returns 'nothing' for holes in the list
        else
            # vector objects aren't lists,
            # but the function for accessing entries is `ELM_LIST`
            current_obj = Wrappers.ELM_LIST(obj, i)
        end
        if recursive && !isbitstype(typeof(current_obj))
            ret_val[i] =
                gap_to_julia_internal(eltype(TT), current_obj, recursion_dict, BoolVal(recursive))
        else
            ret_val[i] = current_obj
        end
    end

    return ret_val::TT
end

## Matrices or lists of lists
function gap_to_julia_internal(
    ::Type{TT},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {TT <: Matrix, recursive}

    if Wrappers.IsMatrixObj(obj)
        nrows = Wrappers.NumberRows(obj)::Int
        ncols = Wrappers.NumberColumns(obj)::Int
    elseif Wrappers.IsList(obj)
        nrows = length(obj)::Int
        ncols = nrows == 0 ? 0 : length(obj[1])::Int
    else
        throw(ConversionError(obj, TT))
    end

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]

    elm = Wrappers.ELM_MAT
    ret_val = TT(undef, nrows, ncols)::TT

    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)
    recursion_dict = handle_recursion((obj, TT), ret_val, recursive, rec_dict)

    for i = 1:nrows, j = 1:ncols
        current_obj = elm(obj, i, j)
        if recursive && !isbitstype(typeof(current_obj))
            ret_val[i, j] =
                gap_to_julia_internal(eltype(TT), current_obj, recursion_dict, BoolVal(recursive))
        else
            ret_val[i, j] = current_obj
        end
    end
    return ret_val
end

## Sets
function gap_to_julia_internal(
    ::Type{TT},
    obj::GapObj,
    recursion_dict::JuliaCacheDict,
    ::Val{recursive},
) where {TT <: Set, recursive}

    if Wrappers.IsCollection(obj)
        newobj = Wrappers.AsSet(obj)
    elseif Wrappers.IsList(obj)
        # The list entries may be not comparable via `<`.
        newobj = Wrappers.DuplicateFreeList(obj)
    else
        throw(ConversionError(obj, TT))
    end

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]

    ret_val = TT()

    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)
    handle_recursion((obj, TT), ret_val, recursive, rec_dict)

    for i = 1:length(newobj)
        current_obj = ElmList(newobj, i)
        if recursive && !isbitstype(typeof(current_obj))
            push!(ret_val, gap_to_julia_internal(eltype(TT), current_obj, rec_dict, BoolVal(recursive)))
        else
            push!(ret_val, current_obj)
        end
    end
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

    !Wrappers.IsList(obj) && throw(ConversionError(obj, T))

    # extract the Tuple parameters, i.e. from Tuple{T1, T2, ...}  the list T1,T2,...
    parameters = T.parameters
    len = length(parameters)
    length(obj) == len ||
        throw(ArgumentError("length of $obj does not match type $T"))

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]
    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)

    list = [
        gap_to_julia_internal(parameters[i], obj[i], rec_dict, BoolVal(recursive))
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

    !Wrappers.IsRecord(obj) && throw(ConversionError(obj, TT))

    recursive && recursion_dict !== nothing && haskey(recursion_dict, (obj, TT)) && return recursion_dict[(obj, TT)]

    ret_val = TT()

    rec_dict = recursion_info_j(TT, obj, recursive, recursion_dict)
    recursion_dict = handle_recursion((obj, TT), ret_val, recursive, rec_dict)

    names = Wrappers.RecNames(obj)
    names_list = Vector{Symbol}(names)
    for key in names_list
      current_obj = getproperty(obj, key)
      if recursive && !isbitstype(typeof(current_obj))
        ret_val[key] =
          gap_to_julia_internal(T, current_obj, recursion_dict, Val(true))
      else
        ret_val[key] = current_obj
      end
    end
    return ret_val
end

## Generic method:
## If it gets called then none of the more special methods is applicable.
## - If `obj` is already of type `T`, just return it, except in a special
##   case: if the target type T is "Any" this has a special meaning: if also
##   recursion is enabled, and the object is a GAP objects, then we should
##   try to convert the object recursively, guessing an output type.
## - If `obj` is a `GapObj` check whether the default Julia type `D` for
##   `obj` is a subtype of `T` distinct from `D`, and if so convert it
##   to that type.
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

  # first check if obj maybe already has the desired output type T:
  # in that case we can probably just return it...
  if obj isa T
    # ... except in a special case: if the target type T is "Any" this has a
    # special meaning: if also recursion is enabled, and the object is a GAP
    # object, then we should try to convert the object recursively, guessing
    # an output type
    if !(T === Any && obj isa GapObj && recursive)
      return obj
    end
  end

  if obj isa GapObj
    D, rec = _default_type(obj, recursive)
    (D === T || !(D <: T)) && throw(ConversionError(obj, T))
    return gap_to_julia_internal(D, obj, recursion_dict, BoolVal(rec))
  else
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
gap_to_julia(T::Type, x::Any; recursive::Bool = true) = gap_to_julia_internal(T, x, nothing, BoolVal(recursive))
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
  return gap_to_julia_internal(T, x, nothing, BoolVal(recursive))
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

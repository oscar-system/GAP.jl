# TODO: revise _needs_conversion_tracking

# TODO:  rec_dict alone is not enough, need `recursive::Bool, too`


# TODO: consider Vector{GAP.Obj}(x) and Vector{GAPObj}(x) ...
# perhaps we need a single  `gap_convert(TYPE, obj; recursive::Bool = DEFAULT)`
# which does both conversion directions at once...
# but to what exactly does `recursive` apply?? 
# it makes sense if we convert *all* to pure Julia or pure GAP. But as soon
# as we deal with "mixed" types, things get weird...



# TODO: document rules for conversion to Any:
# - does nothing if recursion is off
# - converts to a "guessed" type is recursion one
# - special rule: gap_to_julia(x)  resp. to_julia(x) is *NOT* the same as
#   to_julia(Any, x), but rather it always "guesses", even if recursion is off


# Show a specific error on conversion failure.
struct ConversionError <: Base.Exception
    obj::Any
    jl_type::Any
end

Base.showerror(io::IO, e::ConversionError) =
    print(io, "failed to convert $(typeof(e.obj)) to $(e.jl_type):\n $(e.obj)")


# Given a GAP object, guess an appropriate Julia type it could be converted to
function guess_type(x::GapObj)
    GAP_IS_INT(x) && return BigInt
    GAP_IS_RAT(x) && return Rational{BigInt}
    GAP_IS_MACFLOAT(x) && return Float64
    GAP_IS_CHAR(x) && return Cuchar
    # Do not choose this conversion for other lists in 'IsString'.
    Wrappers.IsStringRep(x) && return String
    # Do not choose this conversion for other lists in 'IsRange'.
    Wrappers.IsRangeRep(x) && return StepRange{Int64,Int64}
    # Do not choose this conversion for other lists in 'IsBlist'.
    Wrappers.IsBlistRep(x) && return BitVector
    Wrappers.IsList(x) && return Vector{Any}
    Wrappers.IsMatrixObj(x) && return Matrix{Any}
    Wrappers.IsVectorObj(x) && return Vector{Any}
    Wrappers.IsRecord(x) && return Dict{Symbol,Any}
    Wrappers.IS_JULIA_FUNC(x) && return Function
    throw(ArgumentError("could not guess suitable type"))
end


"""
    RecDict

An internal type of GAP.jl used for tracking conversion results in `gap_to_julia_intern`.
"""
const RecDict = IdDict{Tuple{Type,Any},Any}

const GapToJuliaDict = Union{Nothing,RecDict}



"""
    gap_to_julia_intern(type::Type, input::Any, rec_dict::GapToJuliaDict)

FIXME: update this text

Try to convert the object `x` to a Julia object of type `type`.
If `x` is a `GapObj` then the conversion rules are defined in the
manual of the GAP package JuliaInterface.
If `x` is another `GAP.Obj` (for example a `Int64`) then the result is
defined in Julia by `type`.

The parameter `rec_dict` is used to preserve the identity
of converted subobjects.

For GAP lists and records, it makes sense to convert also the subobjects
recursively, or to keep the subobjects as they are;
the behaviour is controlled by `recursive`, which can be `true` or `false`.

TODO: rec_dict
"""
function gap_to_julia_intern end

## Conversion from GAP to Julia
"""
    gap_to_julia(type::Type, x::Any; recursive::Bool = true)

FIXME: update this text

TODO: document that `type` must be a `Any` or a concrete type, and likewise
for its type parameters. This means that `Tuple{Any}` is not allowed, nor
are unions. Indeed, for a union, how should we determine which of the various
union types should be the end result of the conversion?
(TODO: Actually it's a tad more complicated: we do allow non-concrete types
such as Unions, if the input data already is of that type. So it is OK to 
convert a GapObj to the union type GAP.Obj...




Try to convert the object `x` to a Julia object of type `type`.
If `x` is a `GAP.GapObj` then the conversion rules are defined in the
manual of the GAP package JuliaInterface.
If `x` is another `GAP.Obj` (for example a `Int64`) then the result is
defined in Julia by `type`.

TODO: The parameter `rec_dict` is used to preserve the identity
of converted subobjects and should never be given by the user.

For GAP lists and records, it makes sense to convert also the subobjects
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
| `IsInt`       | `BigInt`                 | `T <: Integer         |
| `IsFFE`       | `GapFFE`                 |                       |
| `IsBool`      | `Bool`                   |                       |
| `IsRat`       | `Rational{BigInt}`       | `Rational{T}          |
| `IsFloat`     | `Float64`                | `T <: AbstractFloat   |
| `IsChar`      | `Cuchar`                 | `Char`                |
| `IsStringRep` | `String`                 | `Symbol`, `Vector{T}` |
| `IsRangeRep`  | `StepRange{Int64,Int64}` | `Vector{T}`           |
| `IsBListRep`  | `BitVector`              | `Vector{T}`           |
| `IsList`      | `Vector{Any}`            | `Vector{T}`           |
| `IsVectorObj` | `Vector{Any}`            | `Vector{T}`           |
| `IsMatrixObj` | `Matrix{Any}`            | `Matrix{T}`           |
| `IsRecord`    | `Dict{Symbol, Any}`      | `Dict{Symbol, T}`     |
"""
function gap_to_julia(type::Type, x::Any; recursive::Bool = true)
# TODO: rename this to just `to_julia`, then one may write `GAP.to_julia`... ???
# and `julia_to_gap` could be `GAP.from_julia` ...

# yet another option: fuse the two conversions functions into a single `GAP.convert`
# (distinct from `Base.convert` !) ... but that does not mash well with "output type guessing"

    return gap_to_julia_intern(type, x, recursive ? RecDict() : nothing)
end

# top level: no type specified, so "guess" a type
function gap_to_julia(x::Obj; recursive::Bool = true)
    return gap_to_julia_intern(x, recursive ? RecDict() : nothing)
end




# helper
# TODO: documentation this, rename it...
# TODO: should this be documented enough so that other packages wishing to
#       implement gap_to_julia_intern methods can use it???
# TODO: rename??? `_gap_to_julia!`?
function _get!(func, rec_dict::GapToJuliaDict, T::Type, obj)
    isbitstype(T) && return func()::T
    rec_dict === nothing && return func()::T
    return get!(func, rec_dict, (T, obj))::T
end
_get!(rec_dict::GapToJuliaDict, T::Type, obj) = _get!(() -> T(obj), rec_dict, T, obj)

# if no other rule matches, throw an error
gap_to_julia_intern(T::Type, obj::Any, rec_dict::GapToJuliaDict) = throw(ConversionError(obj, T))

## also converting an object to its own type does nothing (but this method somehow is much slower
## than the following, so we keep both)
## TODO: analyze this further, and give an example that show cases the performance differential
gap_to_julia_intern(::Type{T}, obj::S, rec_dict::GapToJuliaDict) where {T, S <: T} = obj

## converting an object to its own type does nothing
#gap_to_julia_intern(::Type{T}, obj::T, rec_dict::GapToJuliaDict) where {T} = obj

## Set up conversion for a bunch of types which do not contain subobjects, so
## `recursive` can be safely ignored.


#TODO TODO TODO

## Integers
gap_to_julia_intern(::Type{T}, obj::GapInt, rec_dict::GapToJuliaDict) where {T<:Integer} = _get!(rec_dict, T, obj)

## Rationals
gap_to_julia_intern(::Type{Rational{T}}, obj::GapInt, rec_dict::GapToJuliaDict) where {T<:Integer} = _get!(rec_dict, Rational{T}, obj)

## Floats
gap_to_julia_intern(::Type{T}, obj::GapObj, rec_dict::GapToJuliaDict) where {T<:AbstractFloat} = _get!(rec_dict, T, obj)

## Chars
gap_to_julia_intern(::Type{Char}, obj::GapObj, rec_dict::GapToJuliaDict) = Char(obj)
gap_to_julia_intern(::Type{Cuchar}, obj::GapObj, rec_dict::GapToJuliaDict) = Cuchar(obj)

## Strings
gap_to_julia_intern(::Type{String}, obj::GapObj, rec_dict::GapToJuliaDict) = _get!(rec_dict, String, obj)

## Symbols
gap_to_julia_intern(::Type{Symbol}, obj::GapObj, rec_dict::GapToJuliaDict) = Symbol(obj)

## Convert GAP string to Vector{UInt8}
function gap_to_julia_intern(::Type{Vector{UInt8}}, obj::GapObj, rec_dict::GapToJuliaDict)
    return _get!(rec_dict, Vector{UInt8}, obj) do
        Wrappers.IsStringRep(obj) && return CSTR_STRING_AS_ARRAY(obj)
        Wrappers.IsList(obj) && return UInt8[UInt8(obj[i]) for i = 1:length(obj)]
        throw(ConversionError(obj, Vector{UInt8}))
    end
end

gap_to_julia_intern(::Type{BitVector}, obj::GapObj, rec_dict::GapToJuliaDict) = _get!(rec_dict, BitVector, obj)

## Ranges
gap_to_julia_intern(::Type{T}, obj::GapObj, rec_dict::GapToJuliaDict) where {T<:UnitRange} = _get!(rec_dict, T, obj)
gap_to_julia_intern(::Type{T}, obj::GapObj, rec_dict::GapToJuliaDict) where {T<:StepRange} = _get!(rec_dict, T, obj)


#=
    Wrappers.IS_JULIA_FUNC(x) && return UnwrapJuliaFunc(x)
function gap_to_julia_intern(::Type{Function}, obj::GapObj, rec_dict::GapToJuliaDict)
    if Wrappers.IS_JULIA_FUNC(obj)
        return UnwrapJuliaFunc(obj)
    else
        return TODO
    end
end
=#


#
# The rules for caching/duplicate tracking during conversion from GAP to Julia,
# based on the conversion target type `T`
# - if `T` is a bits type then identity and equality coincide, so no tracking is needed
# - if `T` is `GapObj` then the only "conversion" we permit is the identity map, so
#   no tracking is needed
# - if `T` is a container type (e.g. `Vector`) then the conversion code in general
#   ought to first add the conversion result to the tracking dictionary before
#   performing any recursive calls.
#
# At the top level of conversion, the tracking dictionary may be set to `nothing`.
# Then the conversion method has two ways to proceed: If `T` is *not* a
# container type then `rec_dict` can simply be ignored.
# If `T` is a container type, then in general `rec_dict` needs to be initialized
# and subobjects tracked in it (but not the top level container), unless the
# type of the container elements does not require tracking, in which case
# again `rec_dict` can be simply ignored.
#

# default: bits types don't need tracking, all other types do
_needs_conversion_tracking(::Type{T}) where T = !isbitstype(T)

# the only way conversion produces a GapObj is if the input was a GapObj, and
# then we just use the same GapObj, so duplicates are automatically taken care of
# and we don't need tracking
_needs_conversion_tracking(::Type{GapObj}) = false

# Union types need tracking if any of the types the union was formed over need it
#_needs_conversion_tracking(T::Union) = any(_needs_conversion_tracking, Base.uniontypes(T))
# TODO: alternatively just handle GAP.GapInt, GAP.Obj
_needs_conversion_tracking(::Type{Any}) = false


## Vectors
function gap_to_julia_intern(::Type{S}, obj::GapObj, rec_dict::GapToJuliaDict) where {T, S <: Vector{T}}

    # if `rec_dict` is given and the result of this conversion is in it, use that
    key = (S, obj)
    rec_dict !== nothing && haskey(rec_dict, key) && return rec_dict[key]::S

    # verify input
    Wrappers.IsList(obj) || Wrappers.IsVectorObj(obj) || throw(ConversionError(obj, S))

    len = length(obj)
    result = S(undef, len)

    # FIXME: Why is _needs_conversion_tracking(Any) == true??
    if rec_dict === nothing && _needs_conversion_tracking(T)
        rec_dict = RecDict()
    end
    if rec_dict !== nothing
        # store the new object *before* doing recursion so that self
        # referencing objects are handled correctly
        rec_dict[key] = result
    end

    if Wrappers.IsList(obj)
        for i = 1:len
            subobj = ElmList(obj, i)  # returns 'nothing' for holes in the list
            result[i] = gap_to_julia_intern(T, subobj, rec_dict)
        end
    else
        for i = 1:len
            subobj = Wrappers.ELM_LIST(obj, i)
            result[i] = gap_to_julia_intern(T, subobj, rec_dict)
        end
    end

    return result
end

## Matrices or lists of lists
function gap_to_julia_intern(::Type{S}, obj::GapObj, rec_dict::GapToJuliaDict) where {T, S <: Matrix{T}}

    # if `rec_dict` is given and the result of this conversion is in it, use that
    key = (S, obj)
    rec_dict !== nothing && haskey(rec_dict, key) && return rec_dict[key]::S

    # verify input
    if Wrappers.IsMatrixObj(obj)
        nrows = Wrappers.NumberRows(obj)
        ncols = Wrappers.NumberColumns(obj)
    elseif Wrappers.IsList(obj)
        nrows = length(obj)
        ncols = nrows == 0 ? 0 : length(obj[1])
    else
        throw(ConversionError(obj, S))
    end

    elm = Wrappers.ELM_MAT
    result = S(undef, nrows, ncols)

    if rec_dict === nothing && _needs_conversion_tracking(T)
        rec_dict = RecDict()
    end
    if rec_dict !== nothing
        # store the new object *before* doing recursion so that self
        # referencing objects are handled correctly
        rec_dict[key] = result
    end

    for i = 1:nrows, j = 1:ncols
        subobj = elm(obj, i, j)
        result[i, j] = gap_to_julia_intern(T, subobj, rec_dict)
    end
    return result
end

## Sets
function gap_to_julia_intern(::Type{S}, obj::GapObj, rec_dict::GapToJuliaDict) where {T, S <: Set{T}}

    # if `rec_dict` is given and the result of this conversion is in it, use that
    key = (S, obj)
    rec_dict !== nothing && haskey(rec_dict, key) && return rec_dict[key]::S

    # verify input
    if Wrappers.IsCollection(obj)
        obj = Wrappers.AsSet(obj)
    elseif Wrappers.IsList(obj)
        # The list entries may be not comparable via `<`.
        obj = Wrappers.DuplicateFreeList(obj)
    else
        throw(ConversionError(obj, S))
    end

    len = length(obj)
    result = S()

    if rec_dict === nothing && _needs_conversion_tracking(T)
        rec_dict = RecDict()
    end
    if rec_dict !== nothing
        # store the new object *before* doing recursion so that self
        # referencing objects are handled correctly
        rec_dict[key] = result
    end

    for i = 1:len
        subobj = ElmList(obj, i)
        push!(result, gap_to_julia_intern(T, subobj, rec_dict))
    end
    return result
end

## Tuples
function gap_to_julia_intern(::Type{S}, obj::GapObj, rec_dict::GapToJuliaDict) where {S <: Tuple}

    # if `rec_dict` is given and the result of this conversion is in it, use that
    key = (S, obj)
    rec_dict !== nothing && haskey(rec_dict, key) && return rec_dict[key]::S

    # verify input
    Wrappers.IsList(obj) || throw(ConversionError(obj, S))

    parameters = fieldtypes(S)
    len = length(parameters)
    length(obj) == len || throw(ArgumentError("length of $obj does not match type $S"))

    # We can't create the result object early (before recursion), but we also
    # don't need to, as for tuples, identity and equality is the same.
    # However, we still may need to track conversion results for entries.
    if rec_dict === nothing && any(_needs_conversion_tracking, parameters)
        rec_dict = RecDict()
    end

    list = [gap_to_julia_intern(parameters[i], obj[i], rec_dict) for i = 1:len]
    result = S(list)

    if rec_dict !== nothing
        rec_dict[key] = result

        # Caveat: tuple types are special in Julia in that they are covariant
        # in their parameters: Tuple{Int} is a subtype of Tuple{Any}.
        # Therefore tuple types are only concrete if their parameters are.
        # Thus the final type of the result may differ from `S`. In that case,
        # we store the tuple twice, under both the requested and the actual
        # tuple type
        if !isconcretetype(S)
            rec_dict[(typeof(result),obj)] = result
        end
    end

    return isconcretetype(S) ? result::S : result
end

## Dictionaries
function gap_to_julia_intern(::Type{S}, obj::GapObj, rec_dict::GapToJuliaDict) where {T, S <: Dict{Symbol,T}}

    # if `rec_dict` is given and the result of this conversion is in it, use that
    key = (S, obj)
    rec_dict !== nothing && haskey(rec_dict, key) && return rec_dict[key]::S

    # verify input
    !Wrappers.IsRecord(obj) && throw(ConversionError(obj, S))

    names_list = Vector{Symbol}(Wrappers.RecNames(obj))
    result = S()

    if rec_dict === nothing && _needs_conversion_tracking(T)
        rec_dict = RecDict()
    end
    if rec_dict !== nothing
        # store the new object *before* doing recursion so that self
        # referencing objects are handled correctly
        rec_dict[key] = result
    end

    for key in names_list
        subobj = getproperty(obj, key)
        result[key] = gap_to_julia_intern(T, subobj, rec_dict)
    end

    return result
end

## Generic conversions
function gap_to_julia_intern(::Type{Any}, obj::Obj, rec_dict::GapToJuliaDict)
# FIXME: that's *not* what I'd expect ehre. Why recurse???
#    return obj
    return rec_dict !== nothing ? gap_to_julia_intern(obj, rec_dict) : obj
end

# internal function to convert a GapObj to a "guessed" type
gap_to_julia_intern(x::Union{Int,FFE,Bool}, rec_dict::GapToJuliaDict) = x
function gap_to_julia_intern(x::GapObj, rec_dict::GapToJuliaDict)
    Wrappers.IS_JULIA_FUNC(x) && return UnwrapJuliaFunc(x)
    T = guess_type(x)
    return gap_to_julia_intern(T, x, rec_dict)
end


## for the GAP function GAPToJulia:
## turning arguments into keyword arguments is easier in Julia than in GAP
# TODO: rewrite this using gap_to_julia_intern ??
_gap_to_julia(x::Obj) = gap_to_julia(x)
_gap_to_julia(x::Obj, recursive::Bool) = gap_to_julia(x; recursive)
_gap_to_julia(::Type{T}, x::Obj) where {T} = gap_to_julia(T, x)
_gap_to_julia(::Type{T}, x::Obj, recursive::Bool) where {T} =
    gap_to_julia(T, x; recursive)

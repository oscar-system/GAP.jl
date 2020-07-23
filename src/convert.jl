import Base: convert
  
## Admit `convert` for GAP-to-Julia conversions,
## as an alternative to constructors,
## see https://discourse.julialang.org/t/4159/24
## and https://discourse.julialang.org/t/4159/35.
"""
    convert(T, obj::GapObj; recursive::Bool = true)

Return the Julia object of type `T` that corresponds to `obj`.
If `recursive` is `true` then subobjects of `obj` are also converted,
otherwise not.
Such calls are delegated to [`gap_to_julia`](@ref).

# Examples
```jldoctest
julia> val = @gap 2^64
GAP: 18446744073709551616

julia> convert(Rational{BigInt}, val)
18446744073709551616//1

julia> val = @gap [ [ 1 ], [ 2 ] ]
GAP: [ [ 1 ], [ 2 ] ]

julia> convert(Vector{Any}, val)
2-element Array{Any,1}:
 Any[1]
 Any[2]

julia> convert(Vector{Any}, val, recursive = false)
2-element Array{Any,1}:
 GAP: [ 1 ]
 GAP: [ 2 ]

```
"""
Base.convert(::Type{T}, obj::GapObj; recursive::Bool = true) where {T} = gap_to_julia(T, obj; recursive = recursive)

## The following is needed to disambiguate.
## It is important not to call `gap_to_julia` here,
## otherwise we get a circular call in `_GAP_TO_JULIA`;
## note that `ccall` calls `convert`.
Base.convert(::Type{Any}, obj::GapObj) = obj

## The following is needed to disambiguate.
Base.convert(::Type{T}, obj::GapObj) where {T>:Nothing} = convert(Base.nonnothingtype_checked(T), obj)

## Admit `convert` for Julia-to-GAP conversions.
"""
    convert(GapObj, obj; recursive = false)

Return the GAP object that corresponds to the Julia object `obj`.
If `recursive` is `true` then subobjects of `obj` are also converted,
otherwise not.

# Examples
```jldoctest
julia> convert( GapObj, [1 2; 3 4] )
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> convert( GapObj, [[1, 2], [3, 4]] )
GAP: [ <Julia: [1, 2]>, <Julia: [3, 4]> ]

julia> convert( GapObj, [[1, 2], [3, 4]], recursive = true )
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

```
"""
Base.convert(::Type{GapObj}, obj; recursive::Bool = false) = julia_to_gap(obj; recursive = recursive)

## The following is needed to disambiguate.
## Note that a GapObj can contain Julia objects as subobjects,
## and then recursive conversion has to do something.
Base.convert(::Type{GapObj}, obj::GapObj; recursive::Bool = false) = julia_to_gap(obj, recursive = recursive)

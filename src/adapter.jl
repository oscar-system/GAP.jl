## Basic list / matrix / "record" access as well as arithmetics,
## for GAP objects in Julia

import Base: getindex, setindex!, length, show

function show_string(io::IO, obj::Union{GapObj,FFE})
    str = Globals.StringViewObj(obj)
    stri = CSTR_STRING(str)
    lines = split(stri, "\n")
    rows = displaysize(io)[1]-3  # the maximum number of lines to show
    if length(lines) > rows
      # For objects that do not fit on the screen,
      # show only the first and the last lines.
      upper = div(rows, 2)
      stri = join(lines[1:upper], "\n") * "\n  ⋮\n" *
             join(lines[(end-rows+upper+2):end], "\n")
    end
    return stri
end

function Base.show(io::IO, obj::Union{GapObj,FFE})
    stri = show_string(io, obj)
    print(io, "GAP: $stri")
end

function Base.string(obj::Union{GapObj,FFE})
    str = Globals.String(obj)
    return CSTR_STRING(str)
end

## implement indexing interface

"""
    getindex(x::GapObj, i::Int64)
    getindex(x::GapObj, i::Int64, j::Int64)
    getindex(x::GapObj, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer}

Return the entry at position `i` or at position `(i,j)` in `x`,
or the list of entries in `x` at the positions described by `l`,
provided that `x` is a GAP list.

# Examples
```jldoctest
julia> l = GAP.evalstr( "[ 1, 2, 3, 5, 8, 13 ]" )
GAP: [ 1, 2, 3, 5, 8, 13 ]

julia> l[4]
5

julia> l[end]
13

julia> l[2:4]
GAP: [ 2, 3, 5 ]

julia> l[[1,4,4]]
GAP: [ 1, 5, 5 ]

julia> m = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> m[1,1]
1

julia> m[1,2]
2

julia> m[2,1]
3

```
"""
Base.getindex(x::GapObj, i::Int64) = Globals.ELM_LIST(x, i)
Base.getindex(x::GapObj, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer} =
    Globals.ELMS_LIST(x, julia_to_gap(l))
# The following would make sense but could not be installed just for the case
# that the second argument is a positions list;
# also large integers (element access) or strings (component access) would have
# to be handled.
# Base.getindex(x::GapObj, l::GapObj) = Globals.ELMS_LIST(x, l)

"""
    setindex!(x::GapObj, v::Any, i::Int64)
    setindex!(x::GapObj, v::Any, i::Int64, j::Int64)
    setindex!(x::GapObj, v::Any, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer}

Set the entry at position `i` or `(i,j)` in `x` to `v`,
or set the entries at the positions in `x` that are described by `l`
to the entries in `v`, provided that `x` is a GAP list.

# Examples
```jldoctest
julia> l = GAP.evalstr( "[ 1, 2, 3, 5, 8, 13 ]" )
GAP: [ 1, 2, 3, 5, 8, 13 ]

julia> l[1] = 0
0

julia> l[8] = -1
-1

julia> l[2:4] = [ 7, 7, 7 ]
3-element Array{Int64,1}:
 7
 7
 7

julia> l
GAP: [ 0, 7, 7, 7, 8, 13,, -1 ]

julia> m = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> m[1,2] = 0
0

julia> m
GAP: [ [ 1, 0 ], [ 3, 4 ] ]

```
"""
Base.setindex!(x::GapObj, v::Any, i::Int64) = Globals.ASS_LIST(x, i, v)
Base.setindex!(x::GapObj, v::Any, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer} =
    Globals.ASSS_LIST(x, julia_to_gap(l), julia_to_gap(v))

Base.length(x::GapObj)::Int = Globals.Length(x)
Base.firstindex(x::GapObj) = 1
Base.lastindex(x::GapObj)::Int = Globals.Length(x)

# matrix
Base.getindex(x::GapObj, i::Int64, j::Int64) = Globals.ELM_LIST(x, i, j)
Base.setindex!(x::GapObj, v::Any, i::Int64, j::Int64) = Globals.ASS_LIST(x, i, j, v)

# records
RNamObj(f::Union{Symbol,Int64,AbstractString}) = Globals.RNamObj(MakeString(string(f)))
# note: we don't use Union{Symbol,Int64,AbstractString} below to avoid
# ambiguity between these methods and method `getproperty(x, f::Symbol)`
# from Julia's Base module

"""
    getproperty(x::GapObj, f::Symbol)
    getproperty(x::GapObj, f::Union{AbstractString,Int64})

Return the record component of the GAP record `x` that is described by `f`.

# Examples
```jldoctest
julia> r = GAP.evalstr( "rec( a:= 1 )" )
GAP: rec( a := 1 )

julia> r.a
1

```
"""
Base.getproperty(x::GapObj, f::Symbol) = Globals.ELM_REC(x, RNamObj(f))
Base.getproperty(x::GapObj, f::Union{AbstractString,Int64}) = Globals.ELM_REC(x, RNamObj(f))


"""
    setproperty!(x::GapObj, f::Symbol, v)
    setproperty!(x::GapObj, f::Union{AbstractString,Int64}, v)

Set the record component of the GAP record `x` that is described by `f`
to the value `v`.

# Examples
```jldoctest
julia> r = GAP.evalstr( "rec( a:= 1 )" )
GAP: rec( a := 1 )

julia> r.b = 0
0

julia> r
GAP: rec( a := 1, b := 0 )

```
"""
Base.setproperty!(x::GapObj, f::Symbol, v) = Globals.ASS_REC(x, RNamObj(f), v)
Base.setproperty!(x::GapObj, f::Union{AbstractString,Int64}, v) =
    Globals.ASS_REC(x, RNamObj(f), v)

"""
    hasproperty(x::GapObj, f::Symbol)
    hasproperty(x::GapObj, f::Union{AbstractString,Int64})

Return `true` if the GAP record `x` has a component that is described by `f`,
and `false` otherwise.

# Examples
```jldoctest
julia> r = GAP.evalstr( "rec( a:= 1 )" )
GAP: rec( a := 1 )

julia> hasproperty( r, :a )
true

julia> hasproperty( r, :b )
false

julia> r.b = 2
2

julia> hasproperty( r, :b )
true

julia> r
GAP: rec( a := 1, b := 2 )

```
"""
Base.hasproperty(x::GapObj, f::Symbol) = Globals.ISB_REC(x, RNamObj(f))
Base.hasproperty(x::GapObj, f::Union{AbstractString,Int64}) =
    Globals.ISB_REC(x, RNamObj(f))

#
Base.zero(x::Union{GapObj,FFE}) = Globals.ZERO(x)   # same mutability
Base.one(x::Union{GapObj,FFE}) = Globals.ONE_MUT(x) # same mutability
Base.inv(x::Union{GapObj,FFE}) = Globals.INV_MUT(x) # same mutability
Base.:-(x::Union{GapObj,FFE}) = Globals.AINV(x)     # same mutability

#
Base.in(x::Any, y::GapObj) = Globals.in(x, y)

#
typecombinations = (
    (:GapObj, :GapObj),
    (:FFE, :FFE),
    (:GapObj, :FFE),
    (:FFE, :GapObj),
    (:GapObj, :Int64),
    (:Int64, :GapObj),
    (:FFE, :Int64),
    (:Int64, :FFE),
    (:GapObj, :Bool),
    (:Bool, :GapObj),
    (:FFE, :Bool),
    (:Bool, :FFE),
)
function_combinations = (
    (:+, :SUM),
    (:-, :DIFF),
    (:*, :PROD),
    (:/, :QUO),
    (:\, :LQUO),
    (:^, :POW),
    (:mod, :MOD),
    (:<, :LT),
    (:(==), :EQ),
)

for (left, right) in typecombinations
    for (funcJ, funcC) in function_combinations
        @eval begin
            Base.$(funcJ)(x::$left, y::$right) = Globals.$(funcC)(x, y)
        end
    end
end

# Since we define the equality of GAP objects (see above),
# we must provide a safe `hash` method, otherwise `==` results may be wrong.
# For example, `==` for `Set`s of GAP objects may erroneously return
# `false` if the default `hash` is used.
Base.hash(::GapObj, h::UInt) = h
Base.hash(::FFE, h::UInt) = h

# The following bypasses GAP's redirection of `x^-1` to `INV_MUT(x)`.
# Installing analogous methods for `x^0` and `x^1` would *not* be allowed,
# these terms are equivalent to `ONE_MUT(x)` and `x`, respectively,
# only if `x` is a multiplicative element in the sense of GAP.
Base.literal_pow(::typeof(^), x::GapObj, ::Val{-1}) = Globals.INV_MUT(x)

# iteration

function Base.iterate(obj::GapObj)
    if Globals.IsList(obj)
        iterate(obj, (1, Globals.Length(obj)))
    elseif Globals.IsCollection(obj)
        iterate(obj, Globals.Iterator(obj))
    else
        throw(ArgumentError("object cannot be iterated"))
    end
end

function Base.iterate(obj::GapObj, (i, len)::Tuple{Int,Any})
    i > len && return nothing
    ElmList(obj, i), (i+1, len)
end

function Base.iterate(obj::GapObj, iter::GapObj)
    if Globals.IsDoneIterator(iter)
        nothing
    else
        x = Globals.NextIterator(iter)
        (x, iter)
    end
end

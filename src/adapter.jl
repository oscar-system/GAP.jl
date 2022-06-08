## Basic list / matrix / "record" access as well as arithmetics,
## for GAP objects in Julia

import Base: getindex, setindex!, length, show

export getbangindex, setbangindex!, getbangproperty, setbangproperty!

function show_string(io::IO, obj::Union{GapObj,FFE})
    str = Wrappers.StringViewObj(obj)
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
    str = Wrappers.String(obj)
    return CSTR_STRING(str)
end

## implement indexing interface

"""
    getindex(x::GapObj, i::Int64)
    getindex(x::GapObj, i::Int64, j::Int64)
    getindex(x::GapObj, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer}

Return the entry at position `i` or at position `(i,j)` in `x`,
or the list of entries in `x` at the positions described by `l`,
provided that `x` is a GAP object supporting
this, such as a GAP list or matrix object.

# Examples
```jldoctest
julia> l = GapObj([ 1, 2, 3, 5, 8, 13 ])
GAP: [ 1, 2, 3, 5, 8, 13 ]

julia> l[4]
5

julia> l[end]
13

julia> l[2:4]
GAP: [ 2, 3, 5 ]

julia> l[[1,4,4]]
GAP: [ 1, 5, 5 ]

julia> m = GapObj([ 1 2 ; 3 4 ])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> m[1,1]
1

julia> m[1,2]
2

julia> m[2,1]
3

```
"""
Base.getindex(x::GapObj, i::Int64) = Wrappers.ELM_LIST(x, i)
Base.getindex(x::GapObj, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer} =
    Globals.ELMS_LIST(x, GapObj(l))
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
to the entries in `v`, provided that `x` is a GAP object supporting
this, such as a GAP list or matrix object.

# Examples
```jldoctest
julia> l = GapObj([ 1, 2, 3, 5, 8, 13 ])
GAP: [ 1, 2, 3, 5, 8, 13 ]

julia> l[1] = 0
0

julia> l[8] = -1
-1

julia> l[2:4] = [ 7, 7, 7 ]
3-element Vector{Int64}:
 7
 7
 7

julia> l
GAP: [ 0, 7, 7, 7, 8, 13,, -1 ]

julia> m = GapObj([ 1 2 ; 3 4 ])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> m[1,2] = 0
0

julia> m
GAP: [ [ 1, 0 ], [ 3, 4 ] ]

```
"""
Base.setindex!(x::GapObj, v::Any, i::Int64) = Wrappers.ASS_LIST(x, i, v)
Base.setindex!(x::GapObj, v::Any, l::Union{Vector{T},AbstractRange{T}}) where {T<:Integer} =
    Wrappers.ASSS_LIST(x, GapObj(l), GapObj(v))

Base.length(x::GapObj)::Int = Wrappers.Length(x)
Base.firstindex(x::GapObj) = 1
Base.lastindex(x::GapObj)::Int = Wrappers.Length(x)

# matrix
Base.getindex(x::GapObj, i::Int64, j::Int64) = Wrappers.ELM_MAT(x, i, j)
Base.setindex!(x::GapObj, v::Any, i::Int64, j::Int64) = Wrappers.ASS_MAT(x, i, j, v)

# access and set internals of positional objects
"""
    getbangindex(x::GapObj, i::Int64)

Return the entry at position `i` in the
[positional object](GAP_ref(ref:IsPositionalObjectRep)) `x`.

# Examples
```jldoctest
julia> x = GAP.Globals.ZmodnZObj(1, 6)
GAP: ZmodnZObj( 1, 6 )

julia> GAP.Globals.IsPositionalObjectRep(x)
true

julia> getbangindex(x, 1)
1

```
"""
getbangindex(x::GapObj, i::Int64) = Globals.BangPosition(x, i)

"""
    setbangindex!(x::GapObj, v::Any, i::Int64)

Set the entry at position `i` in the
[positional object](GAP_ref(ref:IsPositionalObjectRep)) `x` to `v`,
and return `x`.

# Examples
```jldoctest
julia> x = GAP.Globals.ZmodnZObj(1, 6)
GAP: ZmodnZObj( 1, 6 )

julia> GAP.Globals.IsPositionalObjectRep(x)
true

julia> setbangindex!(x, 0, 1)
GAP: ZmodnZObj( 0, 6 )

```
"""
function setbangindex!(x::GapObj, v::Any, i::Int64)
  Globals.SetBangPosition(x, i, v)
  return x
end

# records
RNamObj(f::Union{Symbol,Int64,AbstractString}) = Wrappers.RNamObj(MakeString(string(f)))
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
Base.getproperty(x::GapObj, f::Symbol) = Wrappers.ELM_REC(x, RNamObj(f))
Base.getproperty(x::GapObj, f::Union{AbstractString,Int64}) = Wrappers.ELM_REC(x, RNamObj(f))


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
Base.setproperty!(x::GapObj, f::Symbol, v) = Wrappers.ASS_REC(x, RNamObj(f), v)
Base.setproperty!(x::GapObj, f::Union{AbstractString,Int64}, v) =
    Wrappers.ASS_REC(x, RNamObj(f), v)

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
Base.hasproperty(x::GapObj, f::Symbol) = Wrappers.ISB_REC(x, RNamObj(f))
Base.hasproperty(x::GapObj, f::Union{AbstractString,Int64}) =
    Wrappers.ISB_REC(x, RNamObj(f))

# access internals of component objects
"""
    getbangproperty(x::GapObj, f::Union{AbstractString,Int64,Symbol})

Return the value of the component `f` in the
[component object](GAP_ref(ref:IsComponentObjectRep)) `x`.

# Examples
```jldoctest
julia> x = GAP.Globals.Iterator(GAP.Globals.Integers)
GAP: <iterator of Integers at 0>

julia> GAP.Globals.IsComponentObjectRep(x)
true

julia> getbangproperty(x, :counter)
0

```
"""
getbangproperty(x::GapObj, f::Union{AbstractString,Int64,Symbol}) =
    Globals.BangComponent(x, Obj(f))

"""
    setbangproperty!(x::GapObj, f::Union{AbstractString,Int64,Symbol}, v)

Set the value of the component `f` in the
[component object](GAP_ref(ref:IsComponentObjectRep)) `x` to `v`,
and return `x`.

# Examples
```jldoctest
julia> x = GAP.Globals.Iterator(GAP.Globals.Integers)
GAP: <iterator of Integers at 0>

julia> GAP.Globals.IsComponentObjectRep(x)
true

julia> setbangproperty!(x, :counter, 3)
GAP: <iterator of Integers at -1>

julia> getbangproperty(x, :counter)
3

```
"""
function setbangproperty!(x::GapObj, f::Union{AbstractString,Int64,Symbol}, v)
  Globals.SetBangComponent(x, Obj(f), v)
  return x
end

#
Base.zero(x::Union{GapObj,FFE}) = Wrappers.ZeroSameMutability(x)
Base.one(x::Union{GapObj,FFE}) = Wrappers.OneSameMutability(x)
Base.inv(x::Union{GapObj,FFE}) = Wrappers.InverseSameMutability(x)
Base.:-(x::Union{GapObj,FFE}) = Wrappers.AdditiveInverseSameMutability(x)

#
Base.in(x::Any, y::GapObj) = Wrappers.IN(x, y)

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
            Base.$(funcJ)(x::$left, y::$right) = Wrappers.$(funcC)(x, y)
        end
    end
end

# Since we define the equality of GAP objects (see above),
# we must provide a safe `hash` method, otherwise `==` results may be wrong.
# For example, `==` for `Set`s of GAP objects may erroneously return
# `false` if the default `hash` is used.
Base.hash(::GapObj, h::UInt) = h
Base.hash(::FFE, h::UInt) = h

### RNGs

using Random: Random, AbstractRNG, rand

abstract type AbstractGAPRNG <: AbstractRNG end

struct MersenneTwisterState state end

struct MersenneTwister <: AbstractGAPRNG
    ptr::GapObj

    function MersenneTwister(; state::MersenneTwisterState=MersenneTwisterState(nothing))
        if state.state === true
            new(Globals.GlobalMersenneTwister)
        elseif state.state === nothing
            new(Globals.RandomSource(Globals.IsMersenneTwister))
        else
            new(Globals.RandomSource(Globals.IsMersenneTwister, state.state))
        end
    end

    MersenneTwister(seed::Integer) = new(Globals.RandomSource(Globals.IsMersenneTwister, seed))
end

default_rng() = MersenneTwister(state=MersenneTwisterState(true))

function Random.seed!(rng::MersenneTwister, seed::Integer)
    Globals.Reset(rng.ptr, seed)
    rng
end

function Base.copy!(dst::MersenneTwister, src::MersenneTwister)
    Globals.Reset(dst.ptr, Globals.State(src.ptr))
    dst
end

Base.copy(rng::MersenneTwister) = MersenneTwister(state=MersenneTwisterState(Globals.State(rng.ptr)))

## rand methods

Random.rand(rng::AbstractGAPRNG, x::Random.SamplerTrivial{<:Obj}) = Globals.Random(rng.ptr, x[])

Random.rand(rng::AbstractGAPRNG, x::Random.SamplerTrivial{<:AbstractUnitRange}) =
    Globals.Random(rng.ptr, julia_to_gap(first(x[])), julia_to_gap(last(x[])))

Random.Sampler(::Type{<:AbstractGAPRNG}, x::AbstractUnitRange, ::Random.Repetition) =
    Random.SamplerTrivial(x)

# avoid ambiguities
for U in (Base.BitInteger64, Union{Int128,UInt128})
    @eval Random.Sampler(::Type{<:AbstractGAPRNG}, x::AbstractUnitRange{T}, ::Random.Repetition
                         ) where {T<:$U} = Random.SamplerTrivial(x)
end

Random.Sampler(::Type{<:AbstractGAPRNG}, x::AbstractVector, ::Random.Repetition) =
    Random.SamplerTrivial(julia_to_gap(x, recursive=false))


# The following bypasses GAP's redirection of `x^-1` to `InverseSameMutability(x)`.
# Installing analogous methods for `x^0` and `x^1` would *not* be allowed,
# these terms are equivalent to `OneSameMutability(x)` and `x`, respectively,
# only if `x` is a multiplicative element in the sense of GAP.
Base.literal_pow(::typeof(^), x::GapObj, ::Val{-1}) = Wrappers.InverseSameMutability(x)

# iteration

function Base.iterate(obj::GapObj)
    if Wrappers.IsList(obj)
        iterate(obj, (1, Wrappers.Length(obj)))
    elseif Wrappers.IsCollection(obj)
        iterate(obj, Wrappers.Iterator(obj))
    else
        throw(ArgumentError("object cannot be iterated"))
    end
end

function Base.iterate(obj::GapObj, (i, len)::Tuple{Int,Any})
    i > len && return nothing
    ElmList(obj, i), (i+1, len)
end

function Base.iterate(obj::GapObj, iter::GapObj)
    if Wrappers.IsDoneIterator(iter)
        nothing
    else
        x = Wrappers.NextIterator(iter)
        (x, iter)
    end
end

# copy and deepcopy:
# The following is just a preliminary solution,
# in order to avoid Julia crashes when one calls `deepcopy` for a `GapObj`.
# Eventually we want to handle also nested objects such as GAP lists of
# Julia objects having GAP subobjects,
# see 'https://github.com/oscar-system/GAP.jl/issues/197'.
Base.copy(obj::GapObj) = GAP.Wrappers.ShallowCopy(obj)

function Base.deepcopy_internal(obj::GapObj, stackdict::IdDict)
    return get!(stackdict, obj) do
        GAP.Wrappers.StructuralCopy(obj)
    end
end


# Wrap a Julia random number generator into a GAP random source.
# Cache this GAP object in a global dictionary,
# in order to avoid creating such GAP objects again and again.
# We expect that the total number of different random number generators
# in a Julia session is small.
#
# The cache needs a dictionary that compares keys w.r.t. identity,
# in order to regard two copies of a random source as different.
# We would like to use weak keys, in order not to keep objects alive
# that are no longer reachable in the Julia session,
# but the `WeakKeyDict` type compares keys w.r.t. `isequal`.
# (We could introduce a new type `WeakKeyIdDict`, the only difference
# to `WeakKeyDict` would be that the `ht` field is an `IdDict`.)

const _wrapped_random_sources = IdDict{Any,GapObj}()

"""
    wrap_rng(rng::Random.AbstractRNG)

Return a GAP object in the filter `IsRandomSource` that uses `rng`
in calls to GAP's `Random` function.
The idea is that GAP's `Random` methods for high level objects will just
hand over the given random source to subfunctions until `Random` gets
called for a list or the bounds of a range,
and then `Base.rand` gets called with `rng`.

# Examples
```jldoctest
julia> rng1 = Random.default_rng();

julia> rng2 = copy(rng1);

julia> rng1 == rng2
true

julia> rng1 === rng2
false

julia> gap_rng1 = GAP.wrap_rng(rng1)
GAP: <RandomSource in IsRandomSourceJulia>

julia> gap_rng2 = GAP.wrap_rng(rng2)
GAP: <RandomSource in IsRandomSourceJulia>

julia> res1 = GAP.Globals.Random(gap_rng1, 1, 10);

julia> rng1 == rng2   # the two rngs have diverged
false

julia> res1 == GAP.Globals.Random(gap_rng2, GAP.GapObj(1:10))
true

julia> rng1 == rng2   # now the two rngs are again in sync
true

julia> g = GAP.Globals.SymmetricGroup(10);

julia> p = GAP.Globals.Random(gap_rng1, g);

julia> p in g
true

julia> GAP.Globals.Random(gap_rng1, GAP.Globals.GF(2)^10)
GAP: <a GF2 vector of length 10>

```
"""
function wrap_rng(rng::Random.AbstractRNG)
    # Create a new GAP object only if `rng` has not yet been wrapped.
    return get!(_wrapped_random_sources, rng) do
        GAP.Globals.RandomSourceJulia(rng)
    end
end

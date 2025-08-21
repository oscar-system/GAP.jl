```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# Conversions

One of the main ideas of GAP.jl is that *automatic* conversions of Julia objects
to GAP objects and vice versa shall be avoided whenever this is possible.
For a few types of objects, such conversions are unavoidable,
see [Automatic GAP-to-Julia and Julia-to-GAP Conversions](@ref).

In all other situations, the user must explicitly convert between GAP objects
and corresponding Julia objects. This is typically done by "type coercion",
also just called "coercion": to convert a Julia object `x` into a GAP object,
you may write `GapObj(x)`, see [`GapObj`](@ref). Conversely, if `y` is a GAP
object, then e.g. `Vector{Int}(y)` will attempt to convert it into a
`Vector{Int}`. This will success if e.g. `y` is a GAP range or a plain list of
integers. See also [Constructor Methods for GAP-to-Julia Conversions](@ref).

For interactive use it may also be convenient to use the function
[`gap_to_julia`](@ref) with a single argument, which will attempt to "guess" a
suitable Julia type for the conversion (e.g. GAP strings will be converted to
Julia strings). However, we generally recommend against using it, as usually
it is better to coerce to a specific type, as that makes it easier to reason
about the code, and helps code to become "type stable" (an important concept
for [writing performant Julia code](https://docs.julialang.org/en/v1/manual/performance-tips/#Write-%22type-stable%22-functions)).


## Automatic GAP-to-Julia and Julia-to-GAP Conversions

When one calls a GAP function with Julia objects as arguments,
or a Julia function with GAP objects as arguments,
the arguments are in general not automatically converted to GAP objects
or Julia objects, respectively.
The exceptions are as follows.

- GAP's immediate integers (in the range -2^60 to 2^60-1)
  are automatically converted to Julia's `Int64` objects;
  Julia's `Int64` objects are automatically converted to GAP's immediate
  integers if they fit, and to GAP's large integers otherwise.

- GAP's immediate finite field elements
  are automatically converted to Julia's `GAP.FFE` objects, and vice versa.

- GAP's `true` and `false`
  are automatically converted to Julia's `true` and `false`, and vice versa.

## Explicit GAP-to-Julia and Julia-to-GAP Conversions

```@docs
gap_to_julia
GapObj(x, cache::GapCacheDict = nothing; recursive::Bool = false)
```

## Constructor Methods for GAP-to-Julia Conversions

(For Julia-to-GAP conversions,
one can use [`GapObj`](@ref) and [`GAP.Obj`](@ref) as constructors.)

```@docs
Int128
BigInt
Rational
Float64
Char
Cuchar
String
Symbol
UnitRange
StepRange
Tuple
BitVector
Vector{T}
Matrix{T}
Set{T}
Dict{Symbol,T}
```

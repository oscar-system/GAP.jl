```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# Conversions

One of the main ideas of GAP.jl is that automatic conversions of Julia objects
to GAP objects and vice versa shall be avoided whenever this is possible.
For a few types of objects, such conversions are unavoidable,
see [Automatic GAP-to-Julia and Julia-to-GAP Conversions](@ref).
In all other situations,
the conversions between GAP objects and corresponding Julia objects
can be performed using [`gap_to_julia`](@ref) and [`julia_to_gap`](@ref),
see [Explicit GAP-to-Julia and Julia-to-GAP Conversions](@ref), respectively.

For convenience, also constructor methods are provided,
for example `Vector{Int64}(obj)` can be used instead of
`GAP.gap_to_julia(Vector{Int64}, obj)`, where `obj` is a GAP list of
integers;
see [Constructor Methods for GAP-to-Julia Conversions](@ref)
for a description of these methods.
For Julia-to-GAP conversions, one can use for example `GapObj(obj)`,
where `obj` is a Julia object, see [`GapObj`](@ref).

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
julia_to_gap
```

## Constructor Methods for GAP-to-Julia Conversions

(For Julia-to-GAP conversions,
one can use [`GapObj`](@ref) and [`GAP.Obj`](@ref) as constructors.)

```@docs
Int128
BigInt
Rational
Float64
big
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

# GAP.jl

```@contents
```

```@meta
CurrentModule = GAP
DocTestSetup = quote
  using GAP
end
```

## Introduction

GAP.jl is a low level interface from Julia to
[the computer algebra system GAP](https://www.gap-system.org).
The term "low level" means that the aim is
to give Julia access to all GAP objects,
to let Julia call GAP functions,
and to provide conversions of low level data
(integers, Booleans, strings, arrays/lists, dictionaries/records)
between the two systems.

In particular, it is *not* the aim of GAP.jl to provide Julia types
for higher level GAP objects that represent algebraic structures,
such as groups, rings, fields, etc.,
and mappings between such structures.

The connection between GAP and Julia is in fact bidirectional, that is,
GAP can access all Julia objects,
call Julia functions,
and perform conversions of low level data.
This direction will become interesting on the Julia side
as soon as GAP packages provide functionality that is based on
using Julia code from the GAP side.

The viewpoint of an interface from GAP to Julia is described in
[the manual of the GAP package JuliaInterface](GAP_ref(JuliaInterface:Title page)).

## Types

```@docs
FFE
GapObj
```

## Macros

```@docs
@gap
@g_str
@gapwrap
```

## Conversions

One of the main ideas of GAP.jl is that automatic conversions of Julia objects
to GAP objects and vice versa shall be avoided whenever this is possible.
For a few types of objects, such conversions are unavoidable,
see [Automatic GAP-to-Julia and Julia-to-GAP Conversions](@ref).
In all other situations,
the conversions between GAP objects and corresponding Julia objects
can be performed using [`gap_to_julia`](@ref) and [`julia_to_gap`](@ref),
or using `Base.convert`,
see [Explicit GAP-to-Julia and Julia-to-GAP Conversions](@ref), respectively.

For convenience, also constructor methods are provided,
for example `Vector{Int64}(obj)` can be used instead of
`GAP.gap_to_julia(Vector{Int64}, obj)`, where `obj` is a GAP list of
integers;
see [Constructor Methods for GAP-to-Julia Conversions](@ref)
for a description of these methods.
For Julia-to-GAP conversions, one can use for example `GapObj(obj)`,
where `obj` is a Julia object, see [`GapObj`](@ref).

### Automatic GAP-to-Julia and Julia-to-GAP Conversions

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

### Explicit GAP-to-Julia and Julia-to-GAP Conversions

```@docs
gap_to_julia
julia_to_gap
convert
```

### Constructor Methods for GAP-to-Julia Conversions

(For Julia-to-GAP conversions,
one can use [`GapObj`](@ref) as a constructor.)

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
BitArray
Vector{T}
Matrix{T}
Set{T}
Dict{Symbol,T}
```

## Convenience adapters

This section describes how one can manipulate GAP objects from the Julia side,
using Julia syntax features.

```@docs
Globals
call_gap_func
evalstr
getindex
setindex!
getproperty
setproperty!
hasproperty
```

For the following Julia functions, methods are provided that deal with the
case that the arguments are GAP objects; they delegate to the corresponding
GAP operations.

| Julia        | GAP      |
|--------------|----------|
| `length`     | `Length` |
| `in`         | `\in`    |
| `zero`       | `ZERO`   |
| `one`        | `ONE`    |
| `-` (unary)  | `AINV`   |
| `+`          | `SUM`    |
| `-` (binary) | `DIFF`   |
| `*`          | `PROD`   |
| `/`          | `QUO`    |
| `\`          | `LQUO`   |
| `^`          | `POW`    |
| `mod`        | `MOD`    |
| `<`          | `LT`     |
| `==`         | `EQ`     |

```jldoctest
julia> l = GAP.julia_to_gap( [ 1, 3, 7, 15 ] )
GAP: [ 1, 3, 7, 15 ]

julia> m = GAP.julia_to_gap( [ 1 2; 3 4 ] )
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> length( l )
4

julia> length( m )  # different from Julia's behaviour
2

julia> 1 in l
true

julia> 2 in l
false

julia> zero( l )
GAP: [ 0, 0, 0, 0 ]

julia> one( m )
GAP: [ [ 1, 0 ], [ 0, 1 ] ]

julia> - l
GAP: [ -1, -3, -7, -15 ]

julia> l + 1
GAP: [ 2, 4, 8, 16 ]

julia> l + l
GAP: [ 2, 6, 14, 30 ]

julia> m + m
GAP: [ [ 2, 4 ], [ 6, 8 ] ]

julia> 1 - m
GAP: [ [ 0, -1 ], [ -2, -3 ] ]

julia> l * l
284

julia> l * m
GAP: [ 10, 14 ]

julia> m * m
GAP: [ [ 7, 10 ], [ 15, 22 ] ]

julia> 1 / m
GAP: [ [ -2, 1 ], [ 3/2, -1/2 ] ]

julia> m / 2
GAP: [ [ 1/2, 1 ], [ 3/2, 2 ] ]

julia> 2 \ m
GAP: [ [ 1/2, 1 ], [ 3/2, 2 ] ]

julia> m ^ 2
GAP: [ [ 7, 10 ], [ 15, 22 ] ]

julia> m ^ -1
GAP: [ [ -2, 1 ], [ 3/2, -1/2 ] ]

julia> mod( l, 3 )
GAP: [ 1, 0, 1, 0 ]

julia> m < 2 * m
true

julia> m^2 - 5 * m == 2 * one( m )
true

```

## Access to the GAP help system

```@docs
show_gap_help
```

## Managing GAP packages

The following functions allow one to load/install/update/remove GAP packages.

```@docs
GAP.Packages.load
GAP.Packages.install
GAP.Packages.update
GAP.Packages.remove
```

## Other

```@docs
GAP.prompt
```


## Index

```@index
```

# GAP.jl

```@contents
```

```@meta
CurrentModule = GAP
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
```

## Conversions

```@docs
gap_to_julia
julia_to_gap
```

## Convenience adapters

This section describes how one can manipulate GAP objects from the Julia side,
using Julia syntax features.

```@docs
Globals
call_gap_func
EvalString
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

```julia
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
show_GAP_help
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

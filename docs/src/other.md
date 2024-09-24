```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# Other stuff

## Macros

```@docs
@gap
@g_str
@gapwrap
@gapattribute
@wrap
@install
```

## Convenience adapters

This section describes how one can manipulate GAP objects from the Julia side,
using Julia syntax features.

In particular, the following is available on the Julia side
in order to support special GAP syntax beyond function calls with arguments.

- Call functions with global options via [`call_gap_func`](@ref)
  or using Julia's keyword argument syntax. For example,
  `Cyc(1.41421356 : bits:=20)` in GAP translates to
  `GAP.Globals.Cyc(GAP.Obj(1.41421356); bits=20)` in Julia.

- Access list/matrix entries via [`getindex`](@ref) and [`setindex!`](@ref)
  respectively the corresponding Julia syntax (described there).

- Access record components via [`getproperty`](@ref) and [`setproperty!`](@ref)
  respectively the corresponding Julia syntax (described there).

- Check for bound record components via [`hasproperty`](@ref).

- Access entries of a positional object via [`getbangindex`](@ref),
  equivalent to GAP's `![]` operator.

- Access components of a component object via [`getbangproperty`](@ref),
  equivalent to GAP's `!.` operator.

```@docs
call_gap_func
call_with_catch
getindex
setindex!
getbangindex
hasbangindex
setbangindex!
getproperty
setproperty!
hasproperty
getbangproperty
hasbangproperty
setbangproperty!
wrap_rng
randseed!
```

For the following Julia functions, methods are provided that deal with the
case that the arguments are GAP objects; they delegate to the corresponding
GAP operations.

| Julia        | GAP      |
|--------------|----------|
| `length`     | `Length` |
| `in`         | `\in`    |
| `zero`       | `ZeroSameMutability`   |
| `one`        | `OneSameMutability`    |
| `-` (unary)  | `AdditiveInverseSameMutability`   |
| `inv`        | `InverseSameMutability`    |
| `+`          | `SUM`    |
| `-` (binary) | `DIFF`   |
| `*`          | `PROD`   |
| `/`          | `QUO`    |
| `\`          | `LQUO`   |
| `^`          | `POW`    |
| `mod`        | `MOD`    |
| `<`          | `LT`     |
| `==`         | `EQ`     |

The reason why four `SameMutability` operations are chosen in this list
is as follows.
In GAP, *binary* arithmetic operations return immutable results if and only if
the two arguments are immutable.
Thus it is consistent if *unary* arithmetic operations return a result
with the same mutability as the argument.
Note that GAP provides several variants of these unary operations,
regarding the mutability of the result
(`ZeroMutable`, `ZeroImmutable`, `ZeroSameMutability`, etc.),
but here we have to choose one behaviour for the Julia function.

```jldoctest
julia> l = GapObj( [ 1, 3, 7, 15 ] )
GAP: [ 1, 3, 7, 15 ]

julia> m = GapObj( [ 1 2; 3 4 ] )
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
